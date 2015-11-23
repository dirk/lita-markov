require 'spec_helper'

describe MarkyMarkov::PersistentJSONDictionary do
  subject { MarkyMarkov::PersistentJSONDictionary.new 'whoa' }
  
  it 'initializes with sensible defaults' do
    expect(subject.dictionary).to eq({})
  end

  it 'saves a dictionary' do
    subject.add_word ['a', 'b'], 'c'

    json = subject.to_json

    expect(json).to eql '{"depth":2,"dictionary":{"^#1":[["a","b"],["c"]]},"capitalized_words":[]}'
  end

  it 'saves and loads a dictionary' do
    subject.add_word ['a', 'b'], 'c'

    json = subject.to_json

    new_dictionary = MarkyMarkov::PersistentJSONDictionary.new 'whoa-another-one'
    new_dictionary.load_json json

    expect(new_dictionary.dictionary).to eql(['a', 'b'] => ['c'])
  end
end
