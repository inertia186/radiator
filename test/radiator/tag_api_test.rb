require 'test_helper'

module Radiator
  class TagApiTest < Radiator::Test
    def setup
      vcr_cassette('tag_api_jsonrpc') do
        @api = Radiator::TagApi.new(chain_options)
      end
    end

    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end

    def test_all_respond_to
      vcr_cassette('tag_api_all_respond_to') do
        @api.method_names.each do |key|
          assert @api.respond_to?(key), "expect rpc respond to #{key}"
        end
      end
    end

    def test_all_methods
      vcr_cassette('tag_api_all_methods') do
        skip
        vcr_cassette('all_methods') do
          @api.method_names.each do |key|
            begin
              assert @api.send key
            rescue Steem::ArgumentError => e
              # next
            end
          end
        end
      end
    end
  end
end
