module Radiator
  module SSC
    # The "contracts" endpoint
    # 
    # See: https://github.com/harpagon210/steemsmartcontracts/wiki/JSON-RPC-server#3-the-contracts-endpoint-httplocalhost5000contracts
    class Contracts < BaseSteemSmartContractRPC
      # @param options [::Hash] The attributes
      # @option options [String] :url Specify the full node end-point.  Default: https://api.steem-engine.com/rpc/contracts
      def initialize(options = {})
        super
        @url = options[:url] || "#{@root_url}/contracts"
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Contracts.new
      #     rpc.contract('tokens')
      #
      # @param [String] name
      # @return the contract specified from the database
      def contract(name)
        request(method: 'getContract', params: {name: name})
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Contracts.new
      #     rpc.find_one(
      #       contract: "tokens",
      #       table: "balances",
      #       query: {
      #         symbol: "STINGY",
      #         account: "inertia"
      #       }
      #     )
      #
      # @param options [::Hash] The attributes
      # @option options [String] :contract
      # @option options [String] :table
      # @option options [String] :query
      # @return the object that matches the query from the table of the specified contract
      def find_one(options = {})
        request(method: 'findOne', params: options)
      end
      
      # Example using the defaults, backed by Steem Engine:
      #
      #     rpc = Radiator::SSC::Contracts.new
      #     rpc.find(
      #       contract: "tokens",
      #       table: "balances",
      #       query: {
      #         symbol: "STINGY"
      #       }
      #     )
      #
      # @param options [::Hash] The attributes
      # @option options [String] :contract
      # @option options [String] :table
      # @option options [String] :query
      # @option options [Integer] :limit default: 1000
      # @option options [Integer] :offset default: 0
      # @option options [Boolean] :descending
      # @option options [::Hash] indexes default: empty, an index is an object { index: string, descending: boolean }
      # @return array of objects that match the query from the table of the specified contract
      def find(options = {})
        request(method: 'find', params: options)
      end
    end
  end
end
