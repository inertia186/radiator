require 'test_helper'

module Radiator
  class ChainStatsApiTest < Radiator::Test
    def setup
      @api = Radiator::ChainStatsApi.new
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

    def test_get_stats_for_time
      stub_post_get_stats_for_time
      response = @api.get_stats_for_time("20161031T235959", 1000)
      assert_equal Hashie::Mash, response.class, response.inspect
    end
  end
end
