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
        skip_integration_test "cannot execute an asynchronous request in tests"
        
        @api.method_names.each do |key|
          begin
            response = @api.send key
            assert response unless response.nil?
          rescue Steem::ArgumentError
            next
          rescue Steem::RemoteNodeError
            next
          rescue Hive::BaseError
            next
          rescue ApiError
            next
          end
        end
      end
    end

    def test_get_operations
      skip_integration_test "cannot execute an asynchronous request in tests"
      
      vcr_cassette('get_operations') do
        assert_raises Hive::BaseError do
          @api.operations
        end
      end
    end
  end
end
