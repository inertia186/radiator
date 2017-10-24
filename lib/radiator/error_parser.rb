module Radiator
  class ErrorParser
    include Utils
    
    attr_reader :response, :error_code, :error_message,
      :api_name, :api_method, :api_params,
      :expiry, :can_retry, :can_reprepare, :debug
      
    alias expiry? expiry
    alias can_retry? can_retry
    alias can_reprepare? can_reprepare
    
    REPREPARE = [
      'is_canonical( c ): signature is not canonical',
      'now < trx.expiration: ',
      '(skip & skip_transaction_dupe_check) || trx_idx.indices().get<by_trx_id>().find(trx_id) == trx_idx.indices().get<by_trx_id>().end(): Duplicate transaction check failed'
    ]
    
    def initialize(response)
      @response = response
      
      @error_code = nil
      @error_message = nil
      @api_name = nil
      @api_method = nil
      @api_params = nil
      
      @expiry = nil
      @can_retry = nil
      @can_reprepare = nil
      @debug = nil
      
      parse_error_response
    end
    
    def parse_error_response
      return if response.nil?
      
      @error_code = response['error']['data']['code']
      stacks = response['error']['data']['stack']
      stack_formats = stacks.map { |s| s['format'] }
      stack_datum = stacks.map { |s| s['data'] }
      data_call_method = stack_datum.find { |data| data['call.method'] == 'call' }
      
      @error_message = stack_formats.reject(&:empty?).join('; ')
      
      @api_name, @api_method, @api_params = if !!data_call_method
        @api_name = data_call_method['call.params']
      end
      
      case @error_code
      when 10
        @expiry = false
        @can_retry = false
        @can_reprepare = if @api_name == 'network_broadcast_api'
          (stack_formats & REPREPARE).any?
        else
          false
        end
      when 4030100
        # Code 4030100 is "transaction_expiration_exception: transaction
        # expiration exception".  If we assume the expiration was valid, the
        # node might be bad and needs to be dropped.
        
        @expiry = true
        @can_retry = true
        @can_reprepare = false
      when 4030200
        # Code 4030200 is "transaction tapos exception".  They are recoverable
        # if the transaction hasn't expired yet.  A tapos exception can be
        # retried in situations where the node is behind and the tapos is
        # based on a block the node doesn't know about yet.
        
        @expiry = false
        @can_retry = true
        
        # Allow fall back to reprepare if retry fails.
        @can_reprepare = true
      else
        @expiry = false
        @can_retry = false
        @can_reprepare = false
      end
    end
    
    def to_s
      if !!error_message && !error_message.empty?
        "#{error_code}: #{error_message}"
      else
        error_code.to_s
      end
    end
  end
end
