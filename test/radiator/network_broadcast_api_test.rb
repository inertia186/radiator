require 'test_helper'

module Radiator
  class NetworkBroadcastApiTest < Radiator::Test
    def setup
      @api = Radiator::NetworkBroadcastApi.new
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
      VCR.use_cassette('all_methods', record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_broadcast_transaction
      VCR.use_cassette('broadcast_transaction', record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
        @api.broadcast_transaction do |result|
          assert_equal NilClass, result.class, result.inspect
        end
      end
    end
  end
end
