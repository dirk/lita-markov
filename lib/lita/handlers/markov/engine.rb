require 'sequel'

class Lita::Handlers::Markov
  class Engine
    class EmptyDictionaryError < StandardError; end

    # Default development database URL
    DEFAULT_DATABASE_URL = 'mysql2://root@localhost/lita-markov'

    attr_accessor :handler
    attr_reader :db

    def initialize(database_url = nil)
      @handler = handler
      @depth   = 2

      database_url = database_url || DEFAULT_DATABASE_URL

      @db = Sequel.connect database_url

      @db.create_table?(:dictionary) do
        column :user,          String,  null: false # The user the states are associated with
        column :current_state, String,  null: false # Word(s) the user has "said"
        column :next_state,    String,  null: false # Word that follows that word
        column :frequency,     Integer, null: false # Frequency that the next word follows the current state/word

        primary_key [:user, :current_state, :next_state]
      end
    end

    # user   - Username of the user
    # string - String of words that the user has just said (ideally a sentence)
    def ingest user, string
      string = sanitize_string string
      words  = separate_string string

      return if words.length == 0

      # Capitalize the first word and add a period at the end
      words = [words[0].capitalize] + words.slice(1..-1) + ['.']

      # Iterate over it one step at a time in sets of `@depth + 1`
      words.each_cons(@depth + 1) do |words|
        current_state = words[0]+' '+words[1]
        next_state    = words[2]

        add_entry user, current_state, next_state
      end # words.each_cons
    end # def ingest

    def add_entry user, current_state, next_state
      dictionary = @db[:dictionary]

      @db.transaction do
        entry = {
          user: user,
          current_state: current_state,
          next_state: next_state
        }

        if dictionary.where(entry).any?
          # Entry is already present, so increment its frequency
          frequency = dictionary.where(entry).get(:frequency)

          dictionary.where(entry).update frequency: frequency + 1
        else
          dictionary.insert entry.merge(frequency: 1)
        end
      end
    end

    def random_capitalized_word(user)
      states = @db[:dictionary]
        .where(user: user)
        .map(:current_state)

      capitalized_states = states.select do |state|
        /^[A-Z]/ =~ state
      end

      if capitalized_states.length > 0
        state = capitalized_states.sample
      else
        state = states.sample
      end

      raise EmptyDictionaryError, 'No data for user' if state.nil?

      return state.split(' ').first
    end

    def random_second_word(user, first_word)
      states = @db[:dictionary]
        .where(Sequel.like(:current_state, first_word+'%'))
        .where(user: user)
        .map(:current_state)

      state = states.sample
      state.split(' ').last
    end

    def get_next_state(user, current_state)
      states = @db[:dictionary]
        .where(user: user, current_state: current_state)
        .select(:next_state, :frequency)
        .all

      distribution = states.flat_map do |state|
        Array.new(state[:frequency]) { state[:next_state] }
      end

      distribution.sample
    end

    def generate_sentence_for(user, length = 30)
      first_word = random_capitalized_word user
      second_word = random_second_word user, first_word

      sentence = [first_word, second_word]
      ended_with_punctuation = false

      while sentence.length < length
        current_state = sentence.slice(sentence.length - @depth, @depth).join ' '

        next_state = get_next_state user, current_state

        # Stop if we failed to find a next state
        break if next_state.nil?

        sentence << next_state

        if next_state == '.'
          ended_with_punctuation = true
          break
        end
      end

      chain = sentence.slice(0..-2).join(' ')
      chain << ' ' unless ended_with_punctuation
      chain << sentence.last

      chain
    end

    STRING_SEPARATOR = /\s+/

    def separate_string string
      # Including the punctuation in group so they'll be included in the
      # split results
      string
        .split(STRING_SEPARATOR)
        .map { |w| w.strip!; w }
        .select { |w| !w.empty? }
    end

    # Don't allow anything besides letters, digits, whitespace, and puncutation
    NON_WORD_CHARACTERS = /[^\w\d'"“”’:+-]/

    HYPERLINKS          = /http[^\s]+/
    SIMPLE_CODE_BLOCK   = /`[^`]+`/
    EXTENDED_CODE_BLOCK = /```.+```/m
    REPEATED_WHITESPACE = /\s+/

    def sanitize_string string
      string = string
        .gsub(HYPERLINKS, ''.freeze)             # Remove any hyperlinks
        .gsub(SIMPLE_CODE_BLOCK, ''.freeze)      # Remove code blocks and illegal characters
        .gsub(EXTENDED_CODE_BLOCK, ''.freeze)
        .gsub(NON_WORD_CHARACTERS, ' '.freeze)   # Convert non-word characters into whitespace
        .gsub(REPEATED_WHITESPACE, ' '.freeze)   # Convert repeated whitespace into just single spaces
        .strip()
    end
  end
end
