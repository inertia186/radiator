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
      response = @api.get_market_history(nil, nil, nil)
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_market_history_buckets
      stub_post_market_history_api_get_market_history_buckets
      response = @api.get_market_history_buckets
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_order_book
      stub_post_market_history_api_get_order_book
      response = @api.get_order_book(10)
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_recent_trades
      stub_post_market_history_api_get_recent_trades
      response = @api.get_recent_trades(10)
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_ticker
      stub_post_market_history_api_get_ticker
      response = @api.get_ticker
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_trade_history
      skip "Need to research arguments"
      stub_post_market_history_api_get_trade_history
      response = @api.get_trade_history(nil, nil, nil)
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
    
    def test_get_volume
      stub_post_market_history_api_get_volume
      response = @api.get_volume
      assert_equal Hashie::Mash, response.class, response.inspect
      assert response.result
    end
  end
end
