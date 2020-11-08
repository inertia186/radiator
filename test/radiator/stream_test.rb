require 'test_helper'

module Radiator
  class StreamTest < Radiator::Test
    def setup
      vcr_cassette('stream_jsonrpc') do
        @api = Radiator::Stream.new
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('stream_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('stream_all_methods') do
        skip "cannot execute an asynchronous request in tests"
        
        @api.method_names.each do |key|
          begin
            assert @api.send key
          rescue Steem::ArgumentError
            next
          end
        end
      end
    end

    def test_get_operations
      skip "cannot execute an asynchronous request in tests"
      
      vcr_cassette('get_operations') do
        @api.operations
        assert_equal Hashie::Mash, response.class, response.inspect
      end
    end
  end
end
