require 'test_helper'

module Radiator
  class ApiTest < Radiator::Test
    def setup
      @api = Radiator::Api.new(logger: LOGGER)
    end
    
    def test_hashie_logger
      Radiator::Api.new(hashie_logger: 'hashie.log')
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
      @api.get_accounts do |accounts, error|
        assert_equal NilClass, accounts.class, accounts.inspect
        assert_nil accounts
        refute_nil error
      end
    end

    def test_get_accounts
      stub_post_get_account
      @api.get_accounts(['inertia']) do |accounts|
        assert_equal Hashie::Array, accounts.class, accounts.inspect
        account = accounts.first
        owner_key_auths = account.owner.key_auths.first
        assert_equal owner_key_auths.first, 'STM7T5DRhNkp5RpiFrarPfLGXEnU6yk5jLFokfmyJThgRwtLpJuKM'
      end
    end

    def test_get_feed_history
      stub_post_get_feed_history
      @api.get_feed_history(['inertia']) do |history|
        assert_equal Hashie::Mash, history.class, history.inspect
      end
    end

    def test_get_account_count
      stub_post_get_account_count
      @api.get_account_count do |count|
        assert_equal Integer, count.class, count.inspect
      end
    end

    def test_get_account_references
      stub_post_get_account_references
      @api.get_account_references(["2.2.27007"]) do |_, error|
        assert_equal Hashie::Mash, error.class, error.inspect
      end
    end
    
    def test_get_dynamic_global_properties
      stub_post_get_dynamic_global_properties
      @api.get_dynamic_global_properties do |properties|
        assert_equal Hashie::Mash, properties.class, properties.inspect
      end
    end
    
    def test_get_hardfork_version
      stub_post_get_hardfork_version
      @api.get_hardfork_version do |version|
        assert_equal String, version.class, version.inspect
      end
    end
    
    def test_get_vesting_delegations
      stub_post_get_vesting_delegation
      @api.get_vesting_delegations('minnowbooster', -1000, 1000) do |delegation|
        assert_equal Hashie::Array, delegation.class, delegation.inspect
      end
    end
  end
end
