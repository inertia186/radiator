require 'test_helper'

module Radiator
  class ApiTest < Radiator::Test
    def setup
      @api = Radiator::Api.new(chain_options.merge(logger: LOGGER))
    end
    
    def test_hashie_logger
      assert Radiator::Api.new(chain_options.merge(hashie_logger: 'hashie.log'))
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
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_get_accounts_no_argument
      vcr_cassette('get_accounts_no_argument') do
        @api.get_accounts do |accounts, error|
          assert_equal NilClass, accounts.class, accounts.inspect
          assert_nil accounts
          refute_nil error
        end
      end
    end

    def test_get_accounts
      vcr_cassette('get_accounts') do
        @api.get_accounts(['inertia']) do |accounts|
          assert_equal Hashie::Array, accounts.class, accounts.inspect
          account = accounts.first
          owner_key_auths = account.owner.key_auths.first
          assert_equal 'STM5LC8uBiiaihoPhM16CKktPnfb1Yop7fLicuNVgZm6JvU8yCZ7v', owner_key_auths.first
        end
      end
    end

    def test_get_feed_history
      vcr_cassette('get_feed_history') do
        @api.get_feed_history() do |history|
          assert_equal Hashie::Mash, history.class, history.inspect
        end
      end
    end

    def test_get_account_count
      vcr_cassette('get_account_count') do
        @api.get_account_count do |count|
          skip "Fixnum is deprecated." if count.class.to_s == 'Fixnum'
          assert_equal Integer, count.class, count.inspect
        end
      end
    end

    def test_get_account_references
      vcr_cassette('get_account_references') do
        @api.get_account_references(["2.2.27007"]) do |_, error|
          assert_equal Hashie::Mash, error.class, error.inspect
        end
      end
    end
    
    def test_get_dynamic_global_properties
      vcr_cassette('get_dynamic_global_properties') do
        @api.get_dynamic_global_properties do |properties|
          assert_equal Hashie::Mash, properties.class, properties.inspect
        end
      end
    end
    
    def test_get_hardfork_version
      vcr_cassette('get_hardfork_version') do
        @api.get_hardfork_version do |version|
          assert_equal String, version.class, version.inspect
        end
      end
    end
    
    def test_get_vesting_delegations
      vcr_cassette('get_vesting_delegations') do
        @api.get_vesting_delegations('minnowbooster', -1000, 1000) do |delegation|
          assert_equal Hashie::Array, delegation.class, delegation.inspect
        end
      end
    end
    
    def test_get_witness_by_account
      vcr_cassette('get_witness_by_account') do
        @api.get_witness_by_account('') do |witness|
          assert_equal NilClass, witness.class, witness.inspect
        end
      end
    end
    
    def test_recover_transaction
      vcr_cassette('recover_transaction') do
        assert_nil @api.send(:recover_transaction, [], 1, Time.now.utc), 'expect nil response from recover_transaction'
      end
    end
    
    def test_backoff
      assert_equal 0, @api.send(:backoff)
    end
  end
end
