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
      VCR.use_cassette('all_methods', record: VCR_RECORD_MODE) do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_get_stats_for_time
      VCR.use_cassette('get_stats_for_time', record: VCR_RECORD_MODE) do
        @api.get_stats_for_time("20161031T235959", 1000) do |stats|
          assert_equal NilClass, stats.class, stats.inspect
        end
      end
    end
  end
end
