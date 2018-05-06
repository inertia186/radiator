require 'test_helper'

module Radiator
  class MarketHistoryApiTest < Radiator::Test
    def setup
      @api = Radiator::MarketHistoryApi.new(chain_options)
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
    
    def test_get_market_history
      vcr_cassette('get_market_history') do
        @api.get_market_history(nil, nil, nil) do |history|
          assert_equal NilClass, history.class, history.inspect
          assert_nil history
        end
      end
    end
    
    def test_get_market_history_buckets
      vcr_cassette('get_market_history_buckets') do
        @api.get_market_history_buckets do |buckets|
          assert_equal Hashie::Array, buckets.class, buckets.inspect
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
          assert_equal Hashie::Array, trades.class, trades.inspect
          assert trades
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
          assert_equal NilClass, history.class, history.inspect
          assert_nil history
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
