module Radiator
  module Utils
    def extract_signatures(options)
      return [] unless defined? options[:params].map
      
      params = options[:params]
      
      signatures = params.map do |param|
        next unless defined? param.map
        
        param.map do |tx|
          tx[:signatures] rescue nil
        end
      end.flatten.compact
      
      expirations = params.map do |param|
        next unless defined? param.map
        
        param.map do |tx|
          Time.parse(tx[:expiration] + 'Z') rescue nil
        end
      end.flatten.compact
      
      [signatures, expirations.min]
    end
    
    def send_log(level, obj, prefix = nil)
      log_message = case obj
      when String
        log_message = if !!prefix
          "#{prefix} :: #{obj}"
        else
          obj
        end
        
        if !!@logger
          @logger.send level, log_message
        else
          puts "#{level}: #{log_message}"
        end
      else
        if defined? @logger.ap
          if !!prefix
            @logger.ap log_level: level, prefix => obj
          else
            @logger.ap obj, level
          end
        else
          if !!prefix
            @logger.send level, ({prefix => obj}).inspect
          else
            @logger.send level, obj.inspect
          end
        end
      end
      
      nil
    end
    
    def error(obj, prefix = nil)
      send_log(:error, obj, prefix)
    end
    
    def warning(obj, prefix = nil, log_debug_node = false)
      debug("Current node: #{@url}", prefix) if !!log_debug_node && @url
        
      send_log(:warn, obj, prefix)
    end
    
    def debug(obj, prefix = nil)
      if %w(DEBUG TRACE).include? ENV['LOG']
        send_log(:debug, obj, prefix)
      end
    end
    
    def hexlify(s)
      a = []
      if s.respond_to? :each_byte
        s.each_byte { |b| a << sprintf('%02X', b) }
      else
        s.each { |b| a << sprintf('%02X', b) }
      end
      a.join.downcase
    end
    
    def unhexlify(s)
      s.split.pack('H*')
    end
    
    def varint(n)
      data = []
      while n >= 0x80
        data += [(n & 0x7f) | 0x80]
        
        n >>= 7
      end
      
      data += [n]
      
      data.pack('C*')
    end
  
    def pakStr(s)
      s = s.dup.force_encoding('BINARY')
      bytes = []
      bytes << varint(s.size)
      bytes << s
      
      bytes.join
    end
    
    def pakArr(a)
      varint(a.size) + a.map do |v|
        case v
        when Symbol then pakStr(v.to_s)
        when String then pakStr(v)
        when Integer then paks(v)
        when TrueClass then pakC(1)
        when FalseClass then pakC(0)
        when Array then pakArr(v)
        when Hash then pakHash(v)
        when NilClass then next
        else
          raise OperationError, "Unsupported type: #{v.class}"
        end
      end.join
    end
    
    def pakHash(h)
      varint(h.size) + h.map do |k, v|
        pakStr(k.to_s) + case v
        when Symbol then pakStr(v.to_s)
        when String then pakStr(v)
        when Integer then paks(v)
        when TrueClass then pakC(1)
        when FalseClass then pakC(0)
        when Array then pakArr(v)
        when Hash then pakHash(v)
        when NilClass then next
        else
          raise OperationError, "Unsupported type: #{v.class}"
        end
      end.join
    end
    
    def pakC(i)
      [i].pack('C')
    end
    
    def pakc(i)
      [i].pack('c')
    end
    
    def paks(i)
      [i].pack('s')
    end
    
    def pakS(i)
      [i].pack('S')
    end
    
    def pakI(i)
      [i].pack('I')
    end
    
    def pakL!(i)
      [i].pack('L!')
    end
  end
end
