require 'spec_helper'
require 'pry'

describe Lita::Handlers::Markov::Engine do
  before(:each) do
    subject.db[:dictionary].delete
  end

  it 'will sanitize links from a message' do
    message = 'hello https://www.example.com world'

    expect(subject.sanitize_string(message)).to eql 'hello world'
  end

  it 'will remove code blocks from a message' do
    message = 'I have `code in` me.'

    expect(subject.sanitize_string(message)).to eql 'I have me'
  end

  it 'will remove illegal characters from a message' do
    message = 'I have a bad % character.'

    expect(subject.sanitize_string(message)).to eql 'I have a bad character'
  end

  it 'will separate a string into words' do
    string = "I am\n so  totally\tseparated"

    expect(subject.separate_string(string)).to eql ['I', 'am', 'so', 'totally', 'separated']
  end

  it 'will ingest messages' do
    dictionary = subject.db[:dictionary]

    subject.ingest('user', 'hello big, fun world!')

    # Check that the first state made it in and is capitalized
    expect(dictionary.where(current_state: 'Hello big').count).to eql 1
    # Check that the last state made it in
    expect(dictionary.where(current_state: 'fun world', next_state: '.').count).to eql 1

    subject.ingest('user', 'Hello big, fun planet!')

    # Check that the frequency of the "Hello big," -> "fun" state went up
    expect(dictionary.where(current_state: 'Hello big', next_state: 'fun').get(:frequency)).to eql 2
  end

  it 'will generate a sentence' do
    subject.ingest('user', 'Hello cruel world.')

    expect(subject.generate_sentence_for 'user').to include 'Hello cruel world.'
  end
end
