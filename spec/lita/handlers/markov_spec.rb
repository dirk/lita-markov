require 'spec_helper'
require 'pry'

describe Lita::Handlers::Markov, lita_handler: true do
  before(:each) do
    subject.engine.db[:dictionary].delete
  end

  it "won't call #ingest for non-command messages" do
    expect(subject).to_not receive(:ingest)

    send_message "#{robot.name} foo"
    send_command 'bar'
  end

  it 'will build a sentence' do
    send_message 'I love cookies!'
    send_message 'I love pancakes!'

    send_command "#{robot.name} markov #{user.mention_name}"

    expect(replies.count).to eql 1

    reply = replies[0]
    possible_replies = [
      'I love cookies.',
      'I love pancakes.'
    ]
    expect(possible_replies.any? { |r| reply.include?(r) }).to eql true
  end

  it "will complain if the user hasn't said anything" do
    send_command "#{robot.name} markov #{user.mention_name}"

    expect(replies.count).to eql 1
    expect(replies[0]).to eql "Looks like Test User hasn't said anything!"
  end
end
