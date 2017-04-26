require 'test_helper'

module Radiator
  class ApiTest < Radiator::Test
    def setup
      @api = Radiator::Api.new(logger: LOGGER)
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

    def test_get_accounts_no_argument
      stub_post_error
      response = @api.get_accounts
      assert_equal Hashie::Mash, response.class, response.inspect
      assert_nil response.result
      refute_nil response.error
    end

    def test_get_accounts
      stub_post_get_account
      response = @api.get_accounts(['inertia'])
      assert_equal Hashie::Mash, response.class, response.inspect
      assert_equal response.result.first.owner.key_auths.first.first, 'STM7T5DRhNkp5RpiFrarPfLGXEnU6yk5jLFokfmyJThgRwtLpJuKM'
    end

    def test_get_feed_history
      stub_post_get_feed_history
      response = @api.get_feed_history(['inertia'])
      assert_equal Hashie::Mash, response.class, response.inspect
    end

    def test_get_account_count
      stub_post_get_account_count
      response = @api.get_account_count
      assert_equal Hashie::Mash, response.class, response.inspect
    end

    def test_get_account_references
      stub_post_get_account_references
      response = @api.get_account_references(["2.2.27007"])
      assert_equal Hashie::Mash, response.class, response.inspect
    end
    
    def test_get_dynamic_global_properties
      stub_post_get_dynamic_global_properties
      response = @api.get_dynamic_global_properties
      assert_equal Hashie::Mash, response.class, response.inspect
    end
    
    def test_get_hardfork_version
      stub_post_get_hardfork_version
      response = @api.get_hardfork_version
      assert_equal Hashie::Mash, response.class, response.inspect
    end
  end
end
