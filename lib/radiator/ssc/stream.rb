module Radiator
  module SSC
    # Streams the "blockchain" endpoint.
    # 
    # See: https://github.com/harpagon210/steemsmartcontracts/wiki/JSON-RPC-server#3-the-contracts-endpoint-httplocalhost5000contracts
    class Stream < Blockchain
      # Block production on the sidechain is no faster than 3 seconds, but can
      # be indefinately longer than 3 seconds if there are no pending
      # transactions.
      # @private
      MIN_BLOCK_PRODUCTION = 3.0
      
      # @param options [::Hash] The attributes
      # @option options [String] :url Specify the full node end-point.  Default: https://api.steem-engine.net/rpc/blockchain
      def initialize(options = {})
        super
      end
      
      # Stream each block on the side-chain.
      # 
      #     stream = Radiator::SSC::Stream.new
      #     stream.blocks do |block|
      #       puts "Block: #{block}"
      #     end
      # 
      # @param options [::Hash] The attributes
      # @option options [Integer] :at_block_num start stream at this block number
      def blocks(options = {}, &block)
        at_block_num = options[:at_block_num] || latest_block_info.blockNumber
        
        loop do
          block = block_info(at_block_num)
          
          if block.nil?
            sleep MIN_BLOCK_PRODUCTION and next
          end
          
          at_block_num += 1
          
          yield block, block.blockNumber
        end
      end
      
      # Stream each transaction on the side-chain.
      # 
      #     stream = Radiator::SSC::Stream.new
      #     stream.transactions do |trx|
      #       puts "Transaction: #{trx}"
      #     end
      # 
      # @param options [::Hash] The attributes
      # @option options [Integer] :at_block_num start stream at this block number
      def transactions(options = {}, &block)
        blocks(options) do |block, block_num|
          block.transactions.each do |transaction|
            yield transaction, transaction.transactionId, block_num
          end
        end
      end
    end
  end
end
