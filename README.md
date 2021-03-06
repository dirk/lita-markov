# Markov chains for [Lita](https://www.lita.io/)

Listens to your public chat rooms and creates Markov chain databases
for each user.

## Installation

Add `lita-markov` to your Lita instance's Gemfile:

``` ruby
gem 'lita-markov'
```

Configure the database URL for your SQL database
([Sequel](http://sequel.jeremyevans.net/) is used for
communicating with databases):

```ruby
# lita_config.rb
Lita.configure do |config|
  # For example, using Heroku and their Postgresql addon, the database can be
  # configured by simply doing:
  config.handlers.markov.database_url = ENV['DATABASE_URL']
end
```

## Usage

The bot will automatically ingest all messages into the Redis-backed Markov
chain database. You can then query the bot for a generated chain:

```
user> mybot markov dirk
mybot> I love cookies!
```

## License

Licensed under the 3-clause BSD license. See [LICENSE](LICENSE) for details.
