require 'test_helper'

module Radiator
  class ChainStatsApiTest < Radiator::Test
    def setup
      vcr_cassette('chain_stats_api_jsonrpc') do
        @api = Radiator::ChainStatsApi.new(chain_options)
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('chain_stats_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('chain_stats_api_all_methods') do
        skip 'This plugin is not typically enabled.'
        
        @api.method_names.each do |key|
          begin
            assert @api.send key
          rescue Steem::ArgumentError
            next
          end
        end
      end
    end

    def test_get_stats_for_time
      skip 'This plugin is not typically enabled.'
      
      vcr_cassette('get_stats_for_time') do
        @api.get_stats_for_time("20161031T235959", 1000) do |stats|
          assert_equal NilClass, stats.class, stats.inspect
        end
      end
    end
  end
end
