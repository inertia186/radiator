require 'test_helper'

module Radiator
  class CondenserApiTest < Radiator::Test
    def setup
      @api = Radiator::CondenserApi.new(chain_options)
      @silent_api = Radiator::CondenserApi.new(chain_options.merge(logger: LOGGER))
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
    
    def test_look_up_witnesses
      vcr_cassette('look_up_witnesses') do
        @api.lookup_witness_accounts('', 19) do |witnesses|
          assert_equal Hashie::Array, witnesses.class, witnesses.inspect
        end
      end
    end
  end
end
