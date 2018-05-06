require 'test_helper'

module Radiator
  class NetworkBroadcastApiTest < Radiator::Test
    def setup
      @api = Radiator::NetworkBroadcastApi.new(chain_options)
      @silent_api = Radiator::NetworkBroadcastApi.new(chain_options.merge(logger: LOGGER))
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
      vcr_cassette('all_methods') do
        @silent_api.method_names.each do |key|
          assert @silent_api.send key
        end
      end
    end

    def test_broadcast_transaction
      vcr_cassette('broadcast_transaction') do
        @silent_api.broadcast_transaction do |result|
          assert_equal NilClass, result.class, result.inspect
        end
      end
    end
  end
end
