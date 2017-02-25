module Radiator
  class Operation
    include OperationIds
    include Utils
    
    def initialize(options = {})
      options.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end
    
    def to_bytes
      bytes = [id(@type.to_sym)].pack('C')
      
      bytes += case @type
      when :vote
        pakStr(@voter) +
        pakStr(@author) +
        pakStr(@permlink) +
        paks(@weight)
      else
        raise "Unsupported type: #{@type}"
      end
      
      bytes
    end
    
    def payload
      [@type, case @type
        when :vote
          {
            voter: @voter,
            author: @author,
            permlink: @permlink,
            weight: @weight
          }
        else
          raise "Unsupported type: #{@type}"
        end
      ]
    end
  end
end
