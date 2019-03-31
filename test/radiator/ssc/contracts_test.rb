require 'test_helper'

module Radiator
  module SSC
    class ContractsTest < Radiator::Test
      def setup
        @rpc = Radiator::SSC::Contracts.new
      end

      def test_contract
        vcr_cassette('ssc_contracts_contract') do
          assert @rpc.contract('tokens')
        end
      end
      
      def test_find_one
        vcr_cassette('ssc_contracts_find_one') do
          params = {
            contract: 'tokens',
            table: 'balances',
            query: {
              symbol: 'STINGY',
              account: 'inertia'
            }
          }
          result = @rpc.find_one(params)
          assert result
          assert_equal 3.75137479, result.balance.to_f
        end
      end
      
      def test_find
        vcr_cassette('ssc_contracts_find') do
          params = {
            contract: 'tokens',
            table: 'balances',
            query: {
              symbol: 'STINGY'
            }
          }
          result = @rpc.find(params)
          assert result
          assert_equal 19, result.size
        end
      end
    end
  end
end
