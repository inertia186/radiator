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
      varint(s.size) + s
    end
    
    def pakArr(a)
      varint(a.size) + a.map { |v| pakStr(v) }.join
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
