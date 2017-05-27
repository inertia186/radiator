require 'test_helper'

module Radiator
  class OperationTest < Radiator::Test
    def test_unsupported_operation_type
      assert_raises OperationError, 'expect operation type not to be supported' do
        Radiator::Operation.new
      end
    end
    
    def test_unsupported_param_type
      operation = Radiator::Operation.new(type: :vote, voter: 0.0)
      
      assert_raises OperationError, 'expect operation type not to be supported' do
        operation.to_bytes
      end
    end
    
    def test_supported_string
      operation = Radiator::Operation.new(type: :vote, voter: 'inertia')
      
      operation.to_bytes
    end
    
    def test_supported_fixnum
      operation = Radiator::Operation.new(type: :vote, weight: 10000)
      
      operation.to_bytes
    end
    
    def test_supported_true_class
      operation = Radiator::Operation.new(type: :comment_options, allow_votes: true)
      
      operation.to_bytes
    end
    
    def test_supported_false_class
      operation = Radiator::Operation.new(type: :comment_options, allow_votes: false)
      
      operation.to_bytes
    end
    
    def test_supported_empty_array_class
      operation = Radiator::Operation.new(type: :comment_options, extensions: [])
      
      operation.to_bytes
    end
    
    def test_supported_complex_array_class
      extensions = [[0,{"beneficiaries":[{"account":"inertia","weight":500}]}]]
      operation = Radiator::Operation.new(type: :comment_options, extensions: extensions)
      
      operation.to_bytes
    end
    
    def test_supported_nil_class
      operation = Radiator::Operation.new(type: :comment, json_metadata: nil)
      
      operation.to_bytes
    end
    
    def test_supported_array
      operation = Radiator::Operation.new(type: :custom_json, required_auths: [])
      
      operation.to_bytes
    end
    
    def test_operation_payload
      operation = Radiator::Operation.new(
        type: :comment_options,
        author: 'xeroc',
        permlink: 'piston',
        max_accepted_payout: '1000000.000 SBD',
        percent_steem_dollars: 10000,
        # allow_replies: true,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: Radiator::Type::Beneficiaries.new('good-karma' => 2000, 'null' => 5000)
      )
      
      operation.to_bytes
      operation.payload
    end
  end
end
