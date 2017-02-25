require 'bitcoin'
require 'digest'
require 'leon'

module Radiator
  #   * graphenej:
  #     * https://github.com/kenCode-de/graphenej/blob/master/graphenej/src/main/java/de/bitsharesmunich/graphenej/Transaction.java#L142
  class Transaction
    include ChainConfig
    include Utils
    
    VALID_OPTIONS = %w(
      wif private_key ref_block_num ref_block_prefix expiration operations
      chain_id
    ).map(&:to_sym)
    VALID_OPTIONS.each { |option| attr_accessor option }
    
    def initialize(options = {})
      options.each do |k, v|
        k = k.to_sym
        if VALID_OPTIONS.include?(k.to_sym)
          options.delete(k)
          send("#{k}=", v)
        end
      end

      @chain_id ||= NETWORKS_STEEM_CHAIN_ID
      @operations ||= []
      
      if !!@wif && !!@private_key
        raise "Do not pass both wif and private_key.  That's confusing."
      end
      
      if !!@wif
        @private_key = Bitcoin::Key.from_base58 @wif
      end
      
      @api = Api.new(options)
      @network_broadcast_api = NetworkBroadcastApi.new(options)
    end
    
    def process(broadcast = false)
      prepare
      
      if broadcast
        @network_broadcast_api.broadcast_transaction_synchronous(payload)
      end
    end
  private
    def payload
      {
        expiration: @expiration.strftime('%Y-%m-%dT%H:%M:%S'),
        ref_block_num: @ref_block_num,
        ref_block_prefix: @ref_block_prefix,
        operations: @operations.map { |op| op.payload },
        extensions: [],
        signatures: [hexlify(signature)]
      }
    end
  
    def prepare
      @properties = @api.get_dynamic_global_properties.result
      @ref_block_num = @properties.head_block_number & 0xFFFF
      buf = LEON::StringBuffer.new(@properties.head_block_id, 'hex')
      @ref_block_prefix = buf.readUInt32LE(4)
      
      # The expiration allows for transactions to expire if they are not
      # included into a block by that time.
      @expiration ||= Time.parse(@properties.time + 'Z') + EXPIRE_IN_SECS
      
      self
    end

    def to_bytes
      bytes = unhexlify(@chain_id)
      bytes << pakS(@ref_block_num)
      bytes << pakI(@ref_block_prefix)
      bytes << pakI(@expiration.to_i)
      bytes << pakC(@operations.size)
      
      @operations.each do |op|
        bytes << op.to_bytes
      end
      
      bytes << 0x00 # extensions
      
      bytes
    end
    
    def signature
      public_key_hex = @private_key.pub
      ec = Bitcoin::OpenSSL_EC

      loop do
        @expiration += 1
        data = to_bytes
        hash = Digest::SHA256.digest data
        sig = ec.sign_compact(hash, @private_key.priv, public_key_hex)
        
        next if public_key_hex != ec.recover_compact(hash, sig)
        
        return sig if canonical? sig
      end
    end
    
    def canonical?(sig)
      sig = sig.unpack('C*')
      
      !(
        ((sig[0] & 0x80 ) != 0) || ( sig[0] == 0 ) ||
        ((sig[1] & 0x80 ) != 0) ||
        ((sig[32] & 0x80 ) != 0) || ( sig[32] == 0 ) ||
        ((sig[33] & 0x80 ) != 0)
      )
    end
  end
end
