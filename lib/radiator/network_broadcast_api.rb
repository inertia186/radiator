module Radiator
  class NetworkBroadcastApi < Api
    def method_names
      @method_names ||= {
        broadcast_transaction: 0,
        broadcast_transaction_with_callback: 1,
        broadcast_transaction_synchronous: 2,
        broadcast_block: 3
      }.freeze
    end
    
    def api_name
      :network_broadcast_api
    end
  end
end
