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
      vcr_cassette('all_methods') do
        @api.method_names.each do |key|
          assert @api.send key
        end
      end
    end

    def test_get_tags
      vcr_cassette('get_tags') do
        @api.get_tags do |tags|
          assert_equal NilClass, tags.class, tags.inspect
        end
      end
    end
  end
end
