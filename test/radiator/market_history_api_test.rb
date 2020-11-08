require 'test_helper'

module Radiator
  class MarketHistoryApiTest < Radiator::Test
    def setup
      vcr_cassette('market_history_api_jsonrpc') do
        @api = Radiator::MarketHistoryApi.new(chain_options)
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('market_history_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('market_history_api_all_methods') do
        @api.method_names.each do |key|
          begin
            assert @api.send key
          rescue Steem::ArgumentError
            next
          end
        end
      end
    end
    
    def test_get_market_history
      vcr_cassette('get_market_history') do
        @api.get_market_history(nil, nil, nil) do |history|
          assert_equal Hashie::Mash, history.class, history.inspect
          assert_equal history.buckets, []
        end
      end
    end
    
    def test_get_market_history_buckets
      vcr_cassette('get_market_history_buckets') do
        @api.get_market_history_buckets do |buckets|
          assert_equal Hashie::Mash, buckets.class, buckets.inspect
          assert buckets
        end
      end
    end
    
    def test_get_order_book
      vcr_cassette('get_order_book') do
        @api.get_order_book(limit: 10) do |order_book|
          assert_equal Hashie::Mash, order_book.class, order_book.inspect
          assert order_book
        end
      end
    end
    
    def test_get_recent_trades
      vcr_cassette('get_recent_trades') do
        @api.get_recent_trades(limit: 10) do |trades|
          assert_equal Hashie::Mash, trades.class, trades.inspect
          assert trades.trades
        end
      end
    end
    
    def test_get_ticker
      vcr_cassette('get_ticker') do
        @api.get_ticker do |ticker|
          assert_equal Hashie::Mash, ticker.class, ticker.inspect
          assert ticker
        end
      end
    end
    
    def test_get_trade_history
      vcr_cassette('get_trade_history') do
        @api.get_trade_history(nil, nil, nil) do |history|
          assert_equal Hashie::Mash, history.class, history.inspect
          assert_equal history.trades, []
        end
      end
    end
    
    def test_get_volume
      vcr_cassette('get_volume') do
        @api.get_volume do |volume|
          assert_equal Hashie::Mash, volume.class, volume.inspect
          assert volume
        end
      end
    end
  end
end
