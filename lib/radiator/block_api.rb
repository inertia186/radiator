module Radiator
  class BlockApi < Api
    def method_names
      @method_names ||= [
        :get_block_header,
        :get_block
      ].freeze
    end
    
    def api_name
      :block_api
    end
  end
end
