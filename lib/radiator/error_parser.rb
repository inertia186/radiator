module Radiator
  class ErrorParser
    include Utils
    
    attr_reader :response, :error, :error_code, :error_message,
      :api_name, :api_method, :api_params,
      :expiry, :can_retry, :can_reprepare, :node_degraded, :trx_id, :debug
      
    alias expiry? expiry
    alias can_retry? can_retry
    alias can_reprepare? can_reprepare
    alias node_degraded? node_degraded
    
    REPREPARE_WHITELIST = [
      'is_canonical( c ): signature is not canonical',
      'now < trx.expiration: '
    ]
    
    DUPECHECK = '(skip & skip_transaction_dupe_check) || trx_idx.indices().get<by_trx_id>().find(trx_id) == trx_idx.indices().get<by_trx_id>().end(): Duplicate transaction check failed'
      
    REPREPARE_BLACKLIST = [DUPECHECK]
    
    def initialize(response)
      @response = response
      
      @error = nil
      @error_code = nil
      @error_message = nil
      @api_name = nil
      @api_method = nil
      @api_params = nil
      
      @expiry = nil
      @can_retry = nil
      @can_reprepare = nil
      @trx_id = nil
      @debug = nil
      
      parse_error_response
    end
    
    def parse_error_response
      if response.nil?
        @expiry = false
        @can_retry = false
        @can_reprepare = false
        
        return
      end
      
      @response = JSON[response] if response.class == String

      @error = if !!@response['error']
        response['error']
      else
        response
      end
      
      begin
        if !!@error['data']
          # These are, by far, the more interesting errors, so we try to pull
          # them out first, if possible.
          
          @error_code = @error['data']['code']
          stacks = @error['data']['stack']
          stack_formats = nil
          
          @error_message = if !!stacks
            stack_formats = stacks.map { |s| s['format'] }
            stack_datum = stacks.map { |s| s['data'] }
            data_call_method = stack_datum.find { |data| data['call.method'] == 'call' }
            data_name = stack_datum.find { |data| !!data['name'] }
            
            # See if we can recover a transaction id out of this hot mess.
            data_trx_ix = stack_datum.find { |data| !!data['trx_ix'] }
            @trx_id = data_trx_ix['trx_ix'] if !!data_trx_ix
            
            stack_formats.reject(&:empty?).join('; ')
          else
            @error_code ||= @error['code']
            @error['message']
          end
          
          @api_name, @api_method, @api_params = if !!data_call_method
            @api_name = data_call_method['call.params']
          end
        else
          @error_code = @error['code']
          @error_message = @error['message']
          @expiry = false
          @can_retry = false
          @can_reprepare = false
        end
        
        case @error_code
        when -32603
          if error_match?('Internal Error')
            @expiry = false
            @can_retry = true
            @can_reprepare = true
          end
        when -32003
          if error_match?('Unable to acquire database lock')
            @expiry = false
            @can_retry = true
            @can_reprepare = true
          end
        when -32000
          @expiry = false
          @can_retry = coerce_backtrace
          @can_reprepare = if @api_name == 'network_broadcast_api'
            error_match(REPREPARE_WHITELIST)
          else
            false
          end
        when 10
          @expiry = false
          @can_retry = coerce_backtrace
          @can_reprepare = !!stack_formats && (stack_formats & REPREPARE_WHITELIST).any?
        when 13
          @error_message = @error['data']['message']
          @expiry = false
          @can_retry = false
          @can_reprepare = false
        when 3030000
          @error_message = @error['data']['message']
          @expiry = false
          @can_retry = false
          @can_reprepare = false
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
      rescue => e
        if defined? ap
          if ENV['DEBUG'] == 'true'
            ap error_parser_exception: e, original_response: response, backtrace: e.backtrace
          else
            ap error_parser_exception: e, original_response: response
          end
        end
        
        @expiry = false
        @can_retry = false
        @can_reprepare = false
      end
    end
    
    def coerce_backtrace
      can_retry = false
      
      case @error['code']
      when -32003
        any_of = [
          'Internal Error"',
          '_api_plugin not enabled.'
        ]
        
        can_retry = error_match?('Unable to acquire database lock')
        
        if !can_retry && error_match?(any_of)
          can_retry = true
          @node_degraded = true
        else
          @node_degraded = false
        end
      when -32002
        can_retry = @node_degraded = error_match?('Could not find API')
      when 1
        can_retry = @node_degraded = error_match?('no method with name \'condenser_api')
      end
        
      can_retry
    end
    
    def error_match?(matches)
      matches = [matches].flatten
      
      any = matches.map do |match|
        case match
        when String
          @error['message'] && @error['message'].include?(match)
        when Array
          if @error['message']
            match.map { |m| m.include?(match) }.include? true
          else
            false
          end
        else; false
        end
      end
      
      any.include?(true)
    end
    
    def to_s
      if !!error_message && !error_message.empty?
        "#{error_code}: #{error_message}"
      else
        error_code.to_s
      end
    end
    
    def inspect
      "#<#{self.class.name} [#{to_s}]>"
    end
  end
end
