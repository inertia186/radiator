require 'test_helper'

module Radiator
  class AccountByKeyApiTest < Radiator::Test
    def setup
      vcr_cassette('account_by_key_api_jsonrpc') do
        @api = Radiator::AccountByKeyApi.new(chain_options)
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('account_by_key_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('account_by_key_api_all_methods') do
        @api.method_names.each do |key|
          begin
            assert @api.send key
          rescue Steem::ArgumentError
            next
          end
        end
      end
    end

    def test_get_key_references
      vcr_cassette('get_key_references') do
        keys = ['STM71f6yWztimJuREVyyMXNqAVbx1FzPVW6LLXNoQ35dHwKuszmHX']
        @api.get_key_references(keys: keys) do |account_names|
          assert_equal Hashie::Mash, account_names.class, account_names.inspect
        end
      end
    end
  end
end
