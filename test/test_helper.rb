$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if ENV["HELL_ENABLED"]
  require 'simplecov'
  SimpleCov.start
  SimpleCov.merge_timeout 3600
end

require 'radiator'

require 'minitest/autorun'

require 'webmock/minitest' unless ENV["TEST_NET"] == 'true'
require 'vcr'
require 'yaml'
require 'awesome_print'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

if ENV["HELL_ENABLED"]
  require "minitest/hell"
  require 'minitest/proveit'

  class Minitest::Test
    # See: https://gist.github.com/chrisroos/b5da6c6a37ac8af5fe78
    parallelize_me! unless defined? WebMock
  end
else
  require "minitest/pride"
end

if defined? WebMock 
  WebMock.disable_net_connect!(allow_localhost: false, allow: 'codeclimate.com:443')
end

class Radiator::Test < MiniTest::Test
  defined? prove_it! and prove_it!
  
  def chain_options
    {
      chain: :steem,
      url: 'https://api.steemit.com',
      failover_urls: [
        'https://api.steemitstage.com',
        'https://api.steemitdev.com',
        'https://api.steem.house',
      ]
    }
  end
  
  # Most likely modes: 'once' and 'new_episodes'
  VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'new_episodes').to_sym
  
  def vcr_cassette(name, &block)
    VCR.use_cassette(name, record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
      yield
    end
  end

  LOGGER = Logger.new(nil).tap do |logger|
    logger.progname = 'nil-logger'
  end
end
