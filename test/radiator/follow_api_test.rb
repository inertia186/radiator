require 'test_helper'

module Radiator
  class FollowApiTest < Radiator::Test
    def setup
      @api = Radiator::FollowApi.new(chain_options)
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

    def test_get_followers
      vcr_cassette('get_followers') do
        @api.get_followers(account: 'inertia', start: 0, type: 'blog', limit: 100) do |followers|
          assert_equal Hashie::Array, followers.class, followers.inspect
          assert followers
        end
      end
    end
  end
end
