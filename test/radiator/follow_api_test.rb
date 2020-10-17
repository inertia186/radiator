require 'test_helper'

module Radiator
  class FollowApiTest < Radiator::Test
    def setup
      vcr_cassette('follow_api_jsonrpc') do
        @api = Radiator::FollowApi.new(chain_options)
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('follow_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('follow_api_all_methods') do
        skip
        @api.method_names.each do |key|
          begin
            assert @api.send key
          rescue Steem::ArgumentError => e
            # next
          end
        end
      end
    end

    def test_get_followers
      skip
      vcr_cassette('get_followers') do
        @api.get_followers(account: 'inertia', start: 0, type: 'blog', limit: 100) do |followers|
          assert_equal Hashie::Array, followers.class, followers.inspect
          assert followers
        end
      end
    end
  end
end
