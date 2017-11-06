require 'test_helper'

module Radiator
  class ApiTest < Radiator::Test
    def setup
      @api = Radiator::Api.new(logger: LOGGER)
    end
    
    def test_hashie_logger
      assert Radiator::Api.new(hashie_logger: 'hashie.log')
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
      VCR.use_cassette('all_methods', record: VCR_RECORD_MODE) do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_get_accounts_no_argument
      VCR.use_cassette('get_accounts_no_argument', record: VCR_RECORD_MODE) do
        @api.get_accounts do |accounts, error|
          assert_equal NilClass, accounts.class, accounts.inspect
          assert_nil accounts
          refute_nil error
        end
      end
    end

    def test_get_accounts
      VCR.use_cassette('get_accounts', record: VCR_RECORD_MODE) do
        @api.get_accounts(['inertia']) do |accounts|
          assert_equal Hashie::Array, accounts.class, accounts.inspect
          account = accounts.first
          owner_key_auths = account.owner.key_auths.first
          assert_equal owner_key_auths.first, 'STM5uzQ4tZhWjZmNmxCS4rPapCKQBXPPLXe6WLdPzwn6LsPfE76j1'
        end
      end
    end

    def test_get_feed_history
      VCR.use_cassette('get_feed_history', record: VCR_RECORD_MODE) do
        @api.get_feed_history(['inertia']) do |history|
          assert_equal Hashie::Mash, history.class, history.inspect
        end
      end
    end

    def test_get_account_count
      VCR.use_cassette('get_account_count', record: VCR_RECORD_MODE) do
        @api.get_account_count do |count|
          skip "Fixnum is deprecated." if count.class.to_s == 'Fixnum'
          assert_equal Integer, count.class, count.inspect
        end
      end
    end

    def test_get_account_references
      VCR.use_cassette('get_account_references', record: VCR_RECORD_MODE) do
        @api.get_account_references(["2.2.27007"]) do |_, error|
          assert_equal Hashie::Mash, error.class, error.inspect
        end
      end
    end
    
    def test_get_dynamic_global_properties
      VCR.use_cassette('get_dynamic_global_properties', record: VCR_RECORD_MODE) do
        @api.get_dynamic_global_properties do |properties|
          assert_equal Hashie::Mash, properties.class, properties.inspect
        end
      end
    end
    
    def test_get_hardfork_version
      VCR.use_cassette('get_hardfork_version', record: VCR_RECORD_MODE) do
        @api.get_hardfork_version do |version|
          assert_equal String, version.class, version.inspect
        end
      end
    end
    
    def test_get_vesting_delegations
      VCR.use_cassette('get_vesting_delegations', record: VCR_RECORD_MODE) do
        @api.get_vesting_delegations('minnowbooster', -1000, 1000) do |delegation|
          assert_equal Hashie::Array, delegation.class, delegation.inspect
        end
      end
    end
    
    def test_get_witness_by_account
      VCR.use_cassette('get_witness_by_account', record: VCR_RECORD_MODE) do
        @api.get_witness_by_account('') do |witness|
          assert_equal NilClass, witness.class, witness.inspect
        end
      end
    end
    
    def test_recover_transaction
      VCR.use_cassette('recover_transaction', record: VCR_RECORD_MODE) do
        assert_nil @api.send(:recover_transaction, [], 1, Time.now.utc), 'expect nil response from recover_transaction'
      end
    end
    
    def test_backoff
      assert_equal 0, @api.send(:backoff)
    end
  end
end
