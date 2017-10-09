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
    
    def test_look_up_witnesses
      stub_post_empty
      @api.lookup_witness_accounts('', 19) do |witnesses|
        assert_equal Hashie::Array, witnesses.class, witnesses.inspect
      end
    end
  end
end
