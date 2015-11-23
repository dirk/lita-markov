require 'spec_helper'
require 'pry'

describe Lita::Handlers::Markov, lita_handler: true do
  before(:each) do
    Lita.redis.flushall
  end

  it "won't call #ingest for non-command messages" do
    expect(subject).to_not receive(:ingest)

    send_message "#{robot.name} foo"
    send_command 'bar'
  end

  it "will ingest a message into that person's dictionary" do
    send_message 'hello markov world'
    send_message 'hello markov planet'

    dictionary = subject.dictionary_for_user user.mention_name

    # Check that the messages made it into the dictionary
    expect(dictionary.dictionary[['hello', 'markov']]).to eql ['world', 'planet']
  end

  it 'will build a sentence' do
    send_message 'I love cookies!'
    send_message 'I love pancakes!'

    send_command "#{robot.name} markov #{user.mention_name}"

    expect(replies.count).to eql 1

    possible_replies = [
      'I love cookies!',
      'I love pancakes!'
    ]
    expect(possible_replies).to include replies[0]
  end

  it "will complain if the user hasn't said anything" do
    send_command "#{robot.name} markov #{user.mention_name}"

    expect(replies.count).to eql 1
    expect(replies[0]).to eql "Looks like Test User hasn't said anything!"
  end
end
