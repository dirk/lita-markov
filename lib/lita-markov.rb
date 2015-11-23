require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require 'marky_markov/persistent_json_dictionary'
require 'lita/handlers/markov'

# Lita::Handlers::Markov.template_root File.expand_path(
#   File.join("..", "..", "templates"),
#  __FILE__
# )
