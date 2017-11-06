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
      wif private_key ref_block_num ref_block_prefix expiration
      chain
    ).map(&:to_sym)
    VALID_OPTIONS.each { |option| attr_accessor option }
    
    def initialize(options = {})
      options = options.dup
      options.each do |k, v|
        k = k.to_sym
        if VALID_OPTIONS.include?(k.to_sym)
          options.delete(k)
          send("#{k}=", v)
        end
      end
      
      @logger = options[:logger] || Radiator.logger
      @chain ||= :steem
      @chain = @chain.to_sym
      @chain_id = chain_id options[:chain_id]
      @url = options[:url] || url
      @operations = options[:operations] || []
      
      unless NETWORK_CHAIN_IDS.include? @chain_id
        warning "Unknown chain id: #{@chain_id}"
      end
      
      if !!wif && !!private_key
        raise TransactionError, "Do not pass both wif and private_key.  That's confusing."
      end
      
      if !!wif
        @private_key = Bitcoin::Key.from_base58 wif
      end
      
      @expiration ||= nil
      @immutable_expiration = !!@expiration
      
      options = options.merge(
        url: @url,
        chain: @chain,
        pool_size: 1,
        persist: false,
        reuse_ssl_sessions: false
      )
      
      @api = Api.new(options)
      @network_broadcast_api = NetworkBroadcastApi.new(options)
      
      ObjectSpace.define_finalizer(self, self.class.finalize(@api, @network_broadcast_api))
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
        loop do
          response = @network_broadcast_api.broadcast_transaction_synchronous(payload)
          
          if !!response.error
            parser = ErrorParser.new(response)
            
            if parser.can_reprepare?
              debug "Error code: #{parser}, repreparing transaction ..."
              prepare
              redo 
            end
          end
          
          return response
        end
      else
        self
      end
    ensure
      shutdown
    end
    
    def operations
      @operations = @operations.map do |op|
        case op
        when Operation then op
        else; Operation.new(op)
        end
      end
    end
    
    def operations=(operations)
      @operations = operations
    end
    
    def shutdown
      @api.shutdown if !!@api
      @network_broadcast_api.shutdown if !!@network_broadcast_api
    end
  private
    def payload
      @payload ||= {
        expiration: @expiration.strftime('%Y-%m-%dT%H:%M:%S'),
        ref_block_num: @ref_block_num,
        ref_block_prefix: @ref_block_prefix,
        operations: operations.map { |op| op.payload },
        extensions: [],
        signatures: [hexlify(signature)]
      }
    end
    
    def prepare
      raise TransactionError, "No wif or private key." unless !!@wif || !!@private_key
      
      @payload = nil
      
      while @expiration.nil? && @ref_block_num.nil? && @ref_block_prefix.nil?
        @api.get_dynamic_global_properties do |properties, error|
          if !!error
            raise TransactionError, "Unable to prepare transaction.", error
          end
          
          @properties = properties
        end
          
        # You can actually go back as far as the TaPoS buffer will allow, which
        # is something like 50,000 blocks.
        
        block_number = @properties.last_irreversible_block_num
      
        @api.get_block(block_number) do |block, error|
          if !!error
            raise TransactionError, "Unable to prepare transaction.", error
          end
          
          if !!block && !!block.previous
            @ref_block_num = (block_number - 1) & 0xFFFF
            @ref_block_prefix = unhexlify(block.previous[8..-1]).unpack('V*')[0]
          
            # The expiration allows for transactions to expire if they are not
            # included into a block by that time.  Always update it to the current
            # time + EXPIRE_IN_SECS.
            #
            # Note, as of #1215, expiration exactly 'now' will be rejected:
            # https://github.com/steemit/steem/blob/57451b80d2cf480dcce9b399e48e56aa7af1d818/libraries/chain/database.cpp#L2870
            # https://github.com/steemit/steem/issues/1215
            
            block_time = Time.parse(@properties.time + 'Z')
            @expiration ||= block_time + EXPIRE_IN_SECS
          else
            # Suspect this happens when there are microforks, but it should be
            # rare, especially since we're asking for the last irreversible
            # block.
            
            if block.nil?
              warning "Block missing while trying to prepare transaction, retrying ..."
            else
              debug block if %w(DEBUG TRACE).include? ENV['LOG']
              
              warning "Block structure while trying to prepare transaction, retrying ..."
            end
            
            @expiration = nil unless @immutable_expiration
          end
        end
      end
      
      self
    end
    
    def to_bytes
      bytes = unhexlify(@chain_id)
      bytes << pakS(@ref_block_num)
      bytes << pakI(@ref_block_prefix)
      bytes << pakI(@expiration.to_i)
      bytes << pakC(operations.size)
      
      operations.each do |op|
        bytes << op.to_bytes
      end
      
      bytes << 0x00 # extensions
      
      bytes
    end
    
    def digest
      Digest::SHA256.digest(to_bytes)
    end
    
    # May not find all non-canonicals, see: https://github.com/lian/bitcoin-ruby/issues/196
    def signature
      public_key_hex = @private_key.pub
      ec = Bitcoin::OpenSSL_EC
      digest_hex = digest.freeze
      count = 0

      loop do
        count += 1
        debug "#{count} attempts to find canonical signature" if count % 40 == 0
        sig = ec.sign_compact(digest_hex, @private_key.priv, public_key_hex, false)
        
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
    
    def self.finalize(api, network_broadcast_api)
      proc {
        if !!api && !api.stopped?
          puts "DESTROY: #{api.inspect}" if ENV['LOG'] == 'TRACE'
          api.shutdown
          api = nil
        end
        
        if !!network_broadcast_api && !network_broadcast_api.stopped?
          puts "DESTROY: #{network_broadcast_api.inspect}" if ENV['LOG'] == 'TRACE'
          network_broadcast_api.shutdown
          network_broadcast_api = nil
        end
      }
    end
  end
end
