require 'bitcoin'
require 'digest'
require 'time'

module Radiator
  #   * graphenej:
  #     * https://github.com/kenCode-de/graphenej/blob/master/graphenej/src/main/java/de/bitsharesmunich/graphenej/Transaction.java#L142
  class Transaction
    include ChainConfig
    include Utils
    
    VALID_OPTIONS = %w(
      wif private_key ref_block_num ref_block_prefix expiration operations
      chain
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
      
      @logger = options[:logger] || Radiator.logger
      @chain ||= :steem
      @chain_id = chain_id options[:chain_id]
      @url = options[:url] || url
      @operations ||= []
      
      unless NETWORK_CHAIN_IDS.include? @chain_id
        @logger.warn "Unknown chain id: #{@chain_id}"
      end
      
      if !!wif && !!private_key
        raise TransactionError, "Do not pass both wif and private_key.  That's confusing."
      end
      
      if !!wif
        @private_key = Bitcoin::Key.from_base58 wif
      end
      
      options = options.merge(url: @url)
      @api = Api.new(options)
      @network_broadcast_api = NetworkBroadcastApi.new(options)
    end
    
    def chain_id(chain_id = nil)
      return chain_id if !!chain_id
      
      case chain.to_s.downcase.to_sym
      when :steem then NETWORKS_STEEM_CHAIN_ID
      when :golos then NETWORKS_GOLOS_CHAIN_ID
      when :test then NETWORKS_TEST_CHAIN_ID
      end
    end
    
    def url
      case chain.to_s.downcase.to_sym
      when :steem then NETWORKS_STEEM_DEFAULT_NODE
      when :golos then NETWORKS_GOLOS_DEFAULT_NODE
      when :test then NETWORKS_TEST_DEFAULT_NODE
      end
    end
    
    def process(broadcast = false)
      prepare
      
      if broadcast
        @network_broadcast_api.broadcast_transaction_synchronous(payload)
      else
        self
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
      raise TransactionError, "No wif or private key." unless !!@wif || !!@private_key
      
      @properties = @api.get_dynamic_global_properties.result
      @ref_block_num = @properties.head_block_number & 0xFFFF
      @ref_block_prefix = unhexlify(@properties.head_block_id[8..-1]).unpack('V*')[0]
      
      # The expiration allows for transactions to expire if they are not
      # included into a block by that time.  Always update it to the current
      # time + EXPIRE_IN_SECS.
      @expiration = Time.parse(@properties.time + 'Z') + EXPIRE_IN_SECS
      
      @operations = @operations.map do |op|
        case op
        when Operation then op
        else; Operation.new(op)
        end
      end
      
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
    
    def digest
      Digest::SHA256.digest(to_bytes)
    end
    
    def signature
      public_key_hex = @private_key.pub
      ec = Bitcoin::OpenSSL_EC
      digest_hex = digest.freeze

      loop do
        @expiration += 1
        sig = ec.sign_compact(digest_hex, @private_key.priv, public_key_hex)
        
        next if public_key_hex != ec.recover_compact(digest_hex, sig)
        
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
