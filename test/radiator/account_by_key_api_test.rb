require 'test_helper'

module Radiator
  class AccountByKeyApiTest < Radiator::Test
    def setup
      @api = Radiator::AccountByKeyApi.new
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

    def test_get_key_references
      stub_post_get_key_references
      response = @api.get_key_references(['STM71f6yWztimJuREVyyMXNqAVbx1FzPVW6LLXNoQ35dHwKuszmHX'])
      assert_equal response.class, Hashie::Mash, response.inspect
    end
  end
end
