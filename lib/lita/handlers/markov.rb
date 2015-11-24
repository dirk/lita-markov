# Forward definition of Markov handler class
class Lita::Handlers::Markov < Lita::Handler; end

require 'oj'
require 'lita/handlers/markov/engine'

module Lita::Handlers
  class Markov
    template_root File.expand_path('../../../../templates', __FILE__)

    config :database_url, type: String, required: true
    
    route(/.+/, :ingest, command: false)

    route(/markov (.+)/, :generate, command: true, help: {
      'markov USER' => 'Generate a markov chain from the given user.'
    })

    http.get  '/markov/backlog',        :backlog_form
    http.post '/markov/upload_backlog', :upload_backlog

    # Share the engine instance between all instances of the bot
    def self.engine(instance)
      @engine ||= Engine.new(instance.config.database_url)
    end
    def engine
      self.class.engine(self)
    end

    def ingest(chat)
      # Don't ingest messages addressed to ourselves
      return if chat.command?

      message = chat.matches[0].strip

      # Get the mention name (ie. 'dirk') of the user
      id = chat.user.id

      engine.ingest id, message
    end

    def generate(chat)
      name = chat.matches[0][0].strip
      user = Lita::User.fuzzy_find name

      if user.nil?
        chat.reply "Couldn't find the user #{name}. :("
        return
      end

      begin
        sentence = engine.generate_sentence_for user.id

        chat.reply sentence
      rescue Engine::EmptyDictionaryError
        chat.reply "Looks like #{name} hasn't said anything!"
      end
    end

    def backlog_form(request, response)
      render_backlog_form response
    end

    def upload_backlog(request, response)
      t0 = Time.now

      response.headers['Content-Type'] = 'text/plain'

      multipart = Rack::Multipart.parse_multipart request.env
      tempfile  = multipart.values.first[:tempfile]

      begin
        messages = Oj.load File.read(tempfile.path).strip, :mode => :strict
      rescue Oj::ParseError => error
        response.write error.message
        return
      end

      messages.select! { |m| m['type'] == 'message' }

      users = {}
      find_user = proc do |id|
        users[id] ||= Lita::User.fuzzy_find id
      end

      meta_tag_regex = /<(\w|[!|@])+>/

      count = 0
      messages.each do |message|
        count += 1

        begin
          text = message['text'.freeze]
          next unless text

          user = find_user.call message['user'.freeze]
          unless user
            response.write "User not found for message ##{count}: #{message['user']}\n"
            next
          end

          message = text.gsub meta_tag_regex, ''.freeze

          engine.ingest user.id, message

          if count % 1000 == 0
            response.write "Processed #{count} messages\n"
          end
        rescue => error
          response.write "Error writing message ##{count}: #{error.inspect}\n"
        end
      end

      response.write "Processed #{count} total messages in #{Time.now - t0} seconds\n"
    end

    private

    def render_backlog_form(response)
      response.write render_template('backlog_form')
    end

    Lita.register_handler self
  end
end
