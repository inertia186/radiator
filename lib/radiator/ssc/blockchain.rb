module Radiator
  module SSC
    # The "blockchain" endpoint
    # 
    # See: https://github.com/harpagon210/steemsmartcontracts/wiki/JSON-RPC-server#1-the-blockchain-endpoint-httplocalhost5000blockchain
    class Blockchain < BaseSteemSmartContractRPC
      # @param options [::Hash] The attributes
      # @option options [String] :url Specify the full node end-point.  Default: https://api.steem-engine.com/rpc/blockchain
      def initialize(options = {})
        super
        @url = options[:url] || "#{@root_url}/blockchain"
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Blockchain.new
      #     rpc.latest_block_info
      #
      # @return the latest block of the sidechain
      def latest_block_info
        request(method: 'getLatestBlockInfo')
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Blockchain.new
      #     rpc.block_info(1)
      #
      # @param [Integer] block_num
      # @return the block with the specified block number of the sidechain
      def block_info(block_num)
        request(method: 'getBlockInfo', params: {blockNumber: block_num})
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Blockchain.new
      #     rpc.transaction_info('9d288aab2eb66064dc0d4492cb281512386e2293')
      #
      # @param [String] trx_id
      # @return the specified transaction info of the sidechain
      def transaction_info(trx_id)
        request(method: 'getTransactionInfo', params: {txid: trx_id})
      end
    end
  end
end
