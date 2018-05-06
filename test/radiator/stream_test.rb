require 'test_helper'

module Radiator
  class StreamTest < Radiator::Test
    def setup
      @api = Radiator::Stream.new
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
      skip "cannot execute an asynchronous request in tests"
      
      vcr_cassette('all_methods') do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_get_operations
      skip "cannot execute an asynchronous request in tests"
      
      vcr_cassette('get_operations') do
        @api.operations
        assert_equal Hashie::Mash, response.class, response.inspect
      end
    end
  end
end
