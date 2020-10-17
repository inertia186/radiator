require 'test_helper'

module Radiator
  class CondenserApiTest < Radiator::Test
    def setup
      vcr_cassette('condenser_api_jsonrpc') do
        @api = Radiator::CondenserApi.new(chain_options)
        @silent_api = Radiator::CondenserApi.new(chain_options.merge(logger: LOGGER))
      end
    end
    
    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end
    
    def test_all_respond_to
      vcr_cassette('condenser_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end
    
    def test_all_methods
      vcr_cassette('condenser_all_all_methods') do
        @silent_api.method_names.each do |key|
          begin
            assert @silent_api.send key
          rescue Steem::ArgumentError => e
            # next
          rescue Steem::RemoteNodeError => e
            # next
          end
        end
      end
    end
    
    def test_look_up_witnesses
      vcr_cassette('look_up_witnesses') do
        @api.lookup_witness_accounts('', 19) do |witnesses|
          assert_equal Hashie::Array, witnesses.class, witnesses.inspect
        end
      end
    end
  end
end
