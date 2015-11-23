module Lita::Handlers
  class Markov < Lita::Handler
    Dictionary = MarkyMarkov::PersistentJSONDictionary

    REDIS_KEY_PREFIX = 'lita-markov:'
    
    route(/.+/, :ingest, command: false)

    route(/markov (.+)/, :generate, command: true, help: {
      'markov USER' => 'Generate a markov chain from the given user.'
    })

    def ingest(chat)
      # Don't ingest messages addressed to ourselves
      return if chat.command?

      message = chat.matches[0].strip

      # Get the mention name (ie. 'dirk') of the user
      name       = chat.user.mention_name
      dictionary = dictionary_for_user name

      # Passing `false` to indicate it's a string and not a file name
      dictionary.parse_source message, false

      save_dictionary name, dictionary
    end

    def generate(chat)
      name = chat.matches[0][0].strip

      dictionary = dictionary_for_user name
      generator  = MarkovSentenceGenerator.new dictionary

      begin
        sentence = generator.generate_sentence 1

        chat.reply sentence
      rescue EmptyDictionaryError
        chat.reply "Looks like #{name} hasn't said anything!"
      end
    end

    def save_dictionary(name, dictionary)
      redis.set key_for_user(name), dictionary.to_json
    end

    def dictionary_for_user(name)
      key        = key_for_user name
      dictionary = Dictionary.new name
      json       = redis.get key

      dictionary.load_json(json) if json

      dictionary
    end

    def key_for_user(name)
      REDIS_KEY_PREFIX+name.downcase
    end

    Lita.register_handler self
  end
end
