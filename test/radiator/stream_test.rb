require 'test_helper'

module Radiator
  class StreamTest < Radiator::Test
    def setup
      @api = Radiator::Stream.new
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      @api.method_names.each do |key|
        assert @api.respond_to?(key), "expect rpc respond to #{key}"
      end
    end

    def test_all_methods
      unless defined? WebMock
        skip 'This test cannot run against testnet.  It is only here to help locate newly added actions.'
      end
      
      @api.method_names.each do |key|
        begin
          assert @api.send key
          fail 'did not expect method with invalid argument to execute'
        rescue WebMock::NetConnectNotAllowedError => _
          # success
        rescue ArgumentError => _
          # success
        end
      end
    end

    def test_get_operations
      url = 'https://steemd.steemit.com'
      stubs = []
      stubs << stub_request(:post, url).with(body: /get_dynamic_global_properties/).
        to_return(status: 200, body: fixture('get_dynamic_global_properties.json'))
      stubs << stub_request(:post, url).with(body: /get_block/).
        to_return(status: 200, body: fixture('get_block.json'))
  
      skip "cannot execute an asynchronous request in tests"
      @api.operations
      assert_equal Hashie::Mash, response.class, response.inspect
    end
  end
end
