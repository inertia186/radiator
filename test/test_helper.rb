$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if ENV["HELL_ENABLED"] || ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  if ENV['CODECLIMATE_REPO_TOKEN']
    require "codeclimate-test-reporter"
    SimpleCov.start CodeClimate::TestReporter.configuration.profile
    CodeClimate::TestReporter.start
  else
    SimpleCov.start
  end
  SimpleCov.merge_timeout 3600
end

require 'radiator'

require 'minitest/autorun'

require 'webmock/minitest' unless ENV["TEST_NET"] == 'true'
require 'vcr'
require 'yaml'
require 'pry'
require 'typhoeus/adapters/faraday'

if !!ENV['VCR']
  VCR.configure do |c|
    c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
    c.hook_into :webmock
  end
end

if ENV["HELL_ENABLED"]
  require "minitest/hell"
  
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
  FIXTURE_PATH = 'test/fixtures'.freeze
  LOGGER = Logger.new(nil)
  
  def stub_post_login ( & block )
    stub_login = if defined?(WebMock) && !ENV['VCR']
      stub_request(:post, /login/).
        to_return(status: 200, body: '{"success": true}', headers: {'Set-Cookie' => 'TWISTED_SESSION=e564e3329ec7a205ee588bfc32c98ac3; Path=/'})
    end
      
    if !!block
      VCR.use_cassette('login') do
        yield
      end
      if !!stub_login
        assert_requested stub_login, times: 1 and remove_request_stub stub_login
      end
    end
  end
  
  def stub_500_error_odd_string_length ( method, pattern, & block )
    stub_500_error_odd_string_length = if defined?(WebMock) && !ENV['VCR']
      stub_request(method, pattern).
        to_return(status: 500, body: fixture('500_error_odd_string_length.html'))
    end
    
    if !!block
      VCR.use_cassette('untitled') do
        yield
      end
      if !!stub_500_error_odd_string_length
        assert_requested stub_500_error_odd_string_length, times: 1 and remove_request_stub stub_500_error_odd_string_length
      end
    end
  end
  
  def stub_401_unauthorized ( method, pattern, & block )
    stub_401_error_odd_string_length = if defined?(WebMock) && !ENV['VCR']
      stub_request(method, pattern).
        to_return(status: 401, body: fixture('401_unauthorized.html'))
    end
    
    if !!block
      VCR.use_cassette('untitled') do
        yield
      end
      if !!stub_401_error_odd_string_length
        assert_requested stub_401_error_odd_string_length, times: 1 and remove_request_stub stub_401_error_odd_string_length
      end
    end
  end
  
  def stub_connection_refused ( method, pattern, & block )
    stub_connection_refused = if defined?(WebMock) && !ENV['VCR']
      stub_request(method, pattern).
        to_raise(Errno::ECONNREFUSED)
    end
    
    if !!block
      VCR.use_cassette('untitled') do
        yield
      end
      if !!stub_connection_refused
        assert_requested stub_connection_refused, times: 1 and remove_request_stub stub_connection_refused
      end
    end
  end
  
  def stub_timeout ( method, pattern, & block )
    stub_timeout = if defined?(WebMock) && !ENV['VCR']
      stub_request(method, pattern).to_timeout
    end
    
    if !!block
      VCR.use_cassette('untitled') do
        yield
      end
      if !!stub_timeout
        assert_requested stub_timeout, times: 1 and remove_request_stub stub_timeout
      end
    end
  end
  
  def method_missing(m, *args, &block)
    if m =~ /^stub_/
      verb = m.to_s.split('_')
      method = verb[1].to_sym
      json_file = action = verb[2..-1].join('_')
      action = args[0][:as] if !!args[0] && !!args[0][:as]
      times = args[0][:times] if !!args[0] && !!args[0][:times]
      
      if defined?(WebMock) && !ENV['VCR']
        status = if !!args[0] && !!args[0][:status]
          args[0][:status]
        else
          200
        end
        
        options = if !!json = fixture("#{json_file}.json")
          {status: status, body: json}
        else
          {status: 404}
        end
        
        stub = stub_request(method, //).to_return(options)
      end
        
      if !!block
        VCR.use_cassette("#{action}_#{SecureRandom.hex(16)}") do
          yield.tap do |result|
            if !!stub
              assert_requested stub, times: times
              remove_request_stub stub 
            end
            return result
          end
        end
      end
      
      stub
    else
      super
    end
  end
private
  def fixture(fixture)
    if File.exist?(File.join(FIXTURE_PATH, fixture))
      File.open(File.join(FIXTURE_PATH, fixture), 'rb')
    end
  end
end
