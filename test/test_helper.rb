$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['RADIATOR_TEST_MODE'] ||= 'true'
ENV['RADIATOR_TEST_SUITE'] ||= 'default'

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

  c.register_request_matcher :jsonrpc_body do |request_1, request_2|
    normalize = lambda do |request|
      body = request.body.to_s
      parsed = JSON.parse(body) rescue body

      if parsed.is_a?(Hash)
        parsed = parsed.reject { |k, _| k == 'id' }
      elsif parsed.is_a?(Array)
        parsed = parsed.map do |entry|
          entry.is_a?(Hash) ? entry.reject { |k, _| k == 'id' } : entry
        end
      end

      parsed
    end

    normalize.call(request_1) == normalize.call(request_2)
  end
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

class Radiator::Test < Minitest::Test
  defined? prove_it! and prove_it!
  
  def chain_options
    {
      chain: :steem,
      url: 'https://api.steemitdev.com',
      failover_urls: [
        # 'https://api.steemitstage.com',
        'https://api.steemitdev.com',
        # 'https://api.steem.house',
      ]
    }
  end
  
  # Most likely modes: 'once' and 'new_episodes'
  # Default to :once so ordinary test runs do not silently rewrite cassettes.
  # Use VCR_RECORD_MODE=new_episodes when intentionally refreshing fixtures.
  VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'once').to_sym
  
  def vcr_cassette(name, &block)
    VCR.use_cassette(name, record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :jsonrpc_body]) do
      yield
    end
  end

  def integration_test?
    ENV['RADIATOR_TEST_SUITE'] == 'integration'
  end

  def skip_integration_test(message)
    skip message unless integration_test?
  end

  LOGGER = Logger.new(nil).tap do |logger|
    logger.progname = 'nil-logger'
  end
end
