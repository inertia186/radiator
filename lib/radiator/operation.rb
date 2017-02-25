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
      unless Operation::known_operation_names.include? @type
        raise "Unsupported type: #{@type}"
      end
      
      bytes = [id(@type.to_sym)].pack('C')
      
      Operation::param_names(@type.to_sym).each do |p|
        next unless defined? p
        
        v = instance_variable_get("@#{p}")
        k = v.class.name
        bytes += case k
        when 'String' then pakStr(v)
        when 'Fixnum' then paks(v)
        when 'NilClass' then next
        else
          raise "Unsupported type: #{k}"
        end
      end
      
      bytes
    end
    
    def payload
      unless Operation::known_operation_names.include? @type
        raise "Unsupported type: #{@type}"
      end
      
      params = {}
      
      Operation::param_names(@type.to_sym).each do |p|
        next unless defined? p
        
        params[p] = instance_variable_get("@#{p}")
      end
      
      [@type, params]
    end
  private
    def self.broadcast_operations
      @broadcast_operations ||= JSON[File.read 'lib/radiator/broadcast_operations.json']
    end

    def self.known_operation_names
      broadcast_operations.map { |op| op["operation"].to_sym }
    end
    
    def self.param_names(type)
      broadcast_operations.each do |op|
        if op['operation'].to_sym == type.to_sym
          return op['params'].map(&:to_sym)
        end
      end
    end
  end
end

