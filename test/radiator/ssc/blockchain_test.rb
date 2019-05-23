require 'test_helper'

module Radiator
  module SSC
    class BlockchainTest < Radiator::Test
      def setup
        @rpc = Radiator::SSC::Blockchain.new
      end
      
      def teardown
        @rpc.shutdown
      end
      
      def test_latest_block_info
        vcr_cassette('ssc_blockchain_latest_block_info') do
          assert @rpc.latest_block_info
        end
      end
      
      def test_block_info
        vcr_cassette('ssc_blockchain_block_info') do
          block_num = 1
          block_info = @rpc.block_info(block_num)
          assert block_info
          assert_equal block_num, block_info.blockNumber
        end
      end
      
      def test_block_info_invalid
        vcr_cassette('ssc_blockchain_block_info_invalid') do
          assert_raises Radiator::ApiError do
            @rpc.block_info('WRONG')
          end
        end
      end
      
      def test_transaction_info
        vcr_cassette('ssc_blockchain_transaction_info') do
          trx_id = 'df846ffdbd87f3fae2a60993dae9d16d44c814e3'
          transaction_info = @rpc.transaction_info(trx_id)
          assert transaction_info
          assert_equal trx_id, transaction_info.transactionId
        end
      end
      
      def test_no_persist_transaction_info
        rpc = Radiator::SSC::Blockchain.new(persist: false)
        
        vcr_cassette('ssc_blockchain_transaction_info') do
          trx_id = 'df846ffdbd87f3fae2a60993dae9d16d44c814e3'
          transaction_info = rpc.transaction_info(trx_id)
          assert transaction_info
          assert_equal trx_id, transaction_info.transactionId
        end
      end
    end
  end
end
