Gem::Specification.new do |spec|
  spec.name          = "lita-markov"
  spec.version       = "1.1.1"
  spec.authors       = ["Dirk Gadsden"]
  spec.email         = ["dirk@dirk.to"]
  spec.description   = "Markov chains for Lita."
  spec.summary       = spec.description
  spec.homepage      = "http://github.com/dirk/lita-markov"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita",         ">= 4.6"
  spec.add_runtime_dependency "sequel",       "~> 4.28.0"
  spec.add_runtime_dependency "mysql2",       "~> 0.4.1"
  spec.add_runtime_dependency "pg",           "~> 0.18.4"
  spec.add_runtime_dependency "oj",           "~> 2.13.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
