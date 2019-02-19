require 'test_helper'

module Radiator
  class TagApiTest < Radiator::Test
    def setup
      @api = Radiator::TagApi.new(chain_options)
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
      skip
      vcr_cassette('all_methods') do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end
  end
end
