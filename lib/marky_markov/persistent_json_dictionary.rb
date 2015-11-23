require 'marky_markov'
require 'oj'

module MarkyMarkov
  class PersistentJSONDictionary < ::PersistentDictionary
    def initialize(*args)
      super(*args)

      @dictionary        = {}
      @capitalized_words = []
    end

    # No-op instead of reading from the filesystem
    def open_dictionary
      nil
    end

    def load_json(json)
      data = Oj.load json

      @depth             = data['depth']
      @dictionary        = data['dictionary']
      @capitalized_words = data['capitalized_words']
    end

    def to_json
      Oj.dump(
        'depth'             => @depth,
        'dictionary'        => @dictionary,
        'capitalized_words' => @capitalized_words
      )
    end
  end
end
