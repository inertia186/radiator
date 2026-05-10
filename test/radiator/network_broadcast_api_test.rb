require 'test_helper'

module Radiator
  class NetworkBroadcastApiTest < Radiator::Test
    def setup
      vcr_cassette('network_broadcast_api_jsonrpc') do
        @api = Radiator::NetworkBroadcastApi.new(chain_options)
        @silent_api = Radiator::NetworkBroadcastApi.new(chain_options.merge(logger: LOGGER))
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('network_broadcast_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('network_broadcast_api_all_methods') do
        @silent_api.method_names.each do |key|
          next if [:broadcast_transaction, :broadcast_transaction_synchronous].include?(key)

          begin
            response = @silent_api.send key
            assert response
          rescue Steem::ArgumentError
            next
          rescue Steem::RemoteNodeError
            next
          end
        end
      end
    end

    def test_broadcast_transaction
      vcr_cassette('broadcast_transaction') do
        error = assert_raises ApiError do
          @silent_api.broadcast_transaction({})
        end

        assert_includes error.to_s, 'network_broadcast_api.broadcast_transaction'
      end
    end
  end
end
