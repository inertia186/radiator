require 'test_helper'

module Radiator
  class CondenserApiTest < Radiator::Test
    def setup
      @api = Radiator::CondenserApi.new
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
    
    def test_look_up_witnesses
      VCR.use_cassette('look_up_witnesses', record: VCR_RECORD_MODE, match_requests_on: [:method, :uri, :body]) do
        @api.lookup_witness_accounts('', 19) do |witnesses|
          assert_equal Hashie::Array, witnesses.class, witnesses.inspect
        end
      end
    end
  end
end
