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
      
      assert_equal "\x00\ainertia", operation.to_bytes
    end
    
    def test_supported_fixnum
      operation = Radiator::Operation.new(type: :vote, weight: 10000)
      
      assert_equal "\x00\x10'", operation.to_bytes
    end
    
    def test_supported_true_class
      operation = Radiator::Operation.new(type: :comment_options, allow_votes: true)
      
      assert_equal "\x13\x01", operation.to_bytes
    end
    
    def test_supported_false_class
      operation = Radiator::Operation.new(type: :comment_options, allow_votes: false)
      
      expected_bytes = "\x13\x00"
      expected_bytes = expected_bytes.force_encoding('ASCII-8BIT')
      
      assert_equal expected_bytes, operation.to_bytes
    end
    
    def test_supported_empty_array_class
      operation = Radiator::Operation.new(type: :comment_options, extensions: [])
      
      expected_bytes = "\x13\x00"
      expected_bytes = expected_bytes.force_encoding('ASCII-8BIT')
      
      assert_equal expected_bytes, operation.to_bytes
    end
    
    def test_supported_complex_array_class
      extensions = [[0,{"beneficiaries":[{"account":"inertia","weight":500}]}]]
      operation = Radiator::Operation.new(type: :comment_options, extensions: extensions)
      
      expected_bytes = "\x13\x01\x02\x00\x00\x01\rbeneficiaries\x01\x02\aaccount\ainertia\x06weight\xF4\x01"
      expected_bytes = expected_bytes.force_encoding('ASCII-8BIT')
      
      assert_equal expected_bytes, operation.to_bytes
    end
    
    def test_supported_nil_class
      operation = Radiator::Operation.new(type: :comment, json_metadata: nil)
      
      assert_equal "\x01", operation.to_bytes
    end
    
    def test_supported_array
      operation = Radiator::Operation.new(type: :custom_json, required_auths: [])
      
      assert_equal "\x12\x00", operation.to_bytes
    end
    
    def test_operation_payload
      operation = Radiator::Operation.new(
        chain: :hive,
        type: :comment_options,
        author: 'xeroc',
        permlink: 'piston',
        max_accepted_payout: '1000000.000 HBD',
        percent_hbd: 10000,
        # allow_replies: true,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: Radiator::Type::Beneficiaries.new('good-karma' => 2000, 'null' => 5000)
      )
      
      expected_bytes = "\x13\x05xeroc\x06piston\x00\xCA\x9A;\x00\x00\x00\x00\x03HBD\x00\x00\x00\x00\x10'\x01\x01\x01\x00\x02\ngood-karma\xD0\a\x04null\x88\x13"
      expected_bytes = expected_bytes.force_encoding('ASCII-8BIT')
      
      assert_equal expected_bytes, operation.to_bytes
      
      expected_payload = [:comment_options, {
        author: 'xeroc',
        permlink: 'piston',
        max_accepted_payout: Hive::Type::Amount.new('1000000.000 HBD'),
        percent_hbd: 10000,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: [[0, {beneficiaries: [{
          account: 'good-karma',
          weight: 2000
        }, {
          account: 'null',
          weight: 5000
        }]}]]
      }]
      
      assert_equal expected_payload[0], operation.payload[0]
      assert_equal expected_payload[1].keys, operation.payload[1].keys
    end
  end
end
