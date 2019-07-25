module Radiator
  module Type
    class Beneficiaries < Serializer
      
      def initialize(value)
        super(:beneficiaries, value)
      end
      
      def to_bytes
	#set sz 1,  op type 0, see
	#https://github.com/steemit/steem-js/blob/733332d09582e95c0ea868a6ac5b6ee8a1f115ee/src/auth/serializer/src/operations.js#L355
	varint(1) + varint(0) + varint(@value.size) + @value.map do |b|
	  case b
	  when ::Array then pakStr(b.first.to_s) + pakS(b.last)
	  else; pakStr(b.keys.first.to_s) + pakS(b.values.first)
          end
	end.join
      end
      
      def to_h
        v = @value.map do |b|
          case b
          when ::Array then {account: b.first, weight: b.last}
          else; {account: b.keys.first, weight: b.values.first}
          end
        end
        
        {@key => v}
      end
      
      def to_s
        to_h.to_json
      end
    end
  end
end
