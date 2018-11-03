module Radiator
  module Type
    class Beneficiaries < Serializer
      
      def initialize(value)
        super(:beneficiaries, value)
      end
      
      def to_bytes
        pakArr([]) + pakHash(@value)
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
