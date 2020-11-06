# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'radiator/version'

Gem::Specification.new do |spec|
  spec.name = 'radiator'
  spec.version = Radiator::VERSION
  spec.authors = ['Anthony Martin']
  spec.email = ['radiator@martin-studio.com']

  spec.summary = %q{Hive/Steem RPC Ruby Client}
  spec.description = %q{Client for accessing the Hive/Steem blockchain.}
  spec.homepage = 'https://github.com/inertia186/radiator'
  spec.license = 'CC0-1.0'

  spec.files = Dir['lib/**/*', 'test/**/*', 'Gemfile', 'LICENSE', 'Rakefile', 'README.md', 'radiator.gemspec']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0', '>= 2.0.1'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
  spec.add_development_dependency 'minitest', '~> 5.10', '>= 5.10.3'
  spec.add_development_dependency 'minitest-line', '~> 0.6.3'
  spec.add_development_dependency 'minitest-proveit', '~> 1.0', '>= 1.0.0'
  spec.add_development_dependency 'webmock', '~> 3.6', '>= 3.6.0'
  spec.add_development_dependency 'simplecov', '~> 0.19.0'
  spec.add_development_dependency 'vcr', '~> 6.0', '>= 6.0.0'
  spec.add_development_dependency 'yard', '~> 0.9.20'
  spec.add_development_dependency 'pry', '~> 0.11', '>= 0.11.3'
  spec.add_development_dependency 'rb-readline', '~> 0.5', '>= 0.5.5'
  spec.add_development_dependency 'irb', '~> 1.2', '>= 1.2.1'
  
  # net-http-persistent has an open-ended dependency because radiator directly
  # supports net-http-persistent-4.0.0 as well as net-http-persistent-2.5.2.
  spec.add_dependency('net-http-persistent', '>= 2.5.2')
  spec.add_dependency('steem-ruby', '~> 0.9', '>= 0.9.4')
  spec.add_dependency('hive-ruby', '~> 1.0', '>= 1.0.1')
  spec.add_dependency('json', '~> 2.0', '>= 2.0.2')
  spec.add_dependency('logging', '~> 2.2', '>= 2.2.0')
  spec.add_dependency('hashie', '~> 4.1', '>= 3.5.7')
  spec.add_dependency('bitcoin-ruby', '0.0.20') # (was 0.0.19)
  spec.add_dependency('ffi', '~> 1.9', '>= 1.9.18') # (was 1.11.2)
  spec.add_dependency('awesome_print', '~> 1.7', '>= 1.7.0')
end
