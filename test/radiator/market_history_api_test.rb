require 'test_helper'

module Radiator
  class MarketHistoryApiTest < Radiator::Test
    def setup
      @api = Radiator::MarketHistoryApi.new
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
    
    def test_get_market_history
      skip "Need to research arguments"
      stub_post_market_history_api_get_market_history
      @api.get_market_history(nil, nil, nil) do |history|
        assert_equal Hashie::Mash, history.class, history.inspect
        assert history
      end
    end
    
    def test_get_market_history_buckets
      stub_post_market_history_api_get_market_history_buckets
      @api.get_market_history_buckets do |buckets|
        assert_equal Hashie::Array, buckets.class, buckets.inspect
        assert buckets
      end
    end
    
    def test_get_order_book
      stub_post_market_history_api_get_order_book
      @api.get_order_book(10) do |order_book|
        assert_equal Hashie::Mash, order_book.class, order_book.inspect
        assert order_book
      end
    end
    
    def test_get_recent_trades
      stub_post_market_history_api_get_recent_trades
      @api.get_recent_trades(10) do |trades|
        assert_equal Hashie::Array, trades.class, trades.inspect
        assert trades
      end
    end
    
    def test_get_ticker
      stub_post_market_history_api_get_ticker
      @api.get_ticker do |ticker|
        assert_equal Hashie::Mash, ticker.class, ticker.inspect
        assert ticker
      end
    end
    
    def test_get_trade_history
      skip "Need to research arguments"
      stub_post_market_history_api_get_trade_history
      @api.get_trade_history(nil, nil, nil) do |history|
        assert_equal Hashie::Mash, history.class, history.inspect
        assert history
      end
    end
    
    def test_get_volume
      stub_post_market_history_api_get_volume
      @api.get_volume do |volume|
        assert_equal Hashie::Mash, volume.class, volume.inspect
        assert volume
      end
    end
  end
end
