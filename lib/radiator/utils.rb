module Radiator
  module Utils
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
    
    def pakStr(s)
      [s.size].pack('C') + s
    end
    
    def pakC(i)
      [i].pack('C')
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
  end
end
