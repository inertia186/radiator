require 'test_helper'

module Radiator
  class TransactionBuilderTest < Radiator::Test
    include Utils
    
    def setup
      options = {
        wif: '5Khe9Sriho4ET9ijGdT6GMUqK1v7nEQkZwTLXfUtd4KZgUVtHBR',
        ref_block_num: 36029,
        ref_block_prefix: 1164960351,
        expiration: Time.parse('2016-08-08T12:24:17 Z'),
      }
      
      @transaction = Radiator::Transaction.new(options)
    end
    
    # This is a contrived transaction that mirrors the transaction documented
    # by the manual signing example written by xeroc:
    #
    # https://gist.github.com/xeroc/9bda11add796b603d83eb4b41d38532b
    def test_to_bytes
      vote = {
        type: :vote,
        voter: 'xeroc',
        author: 'xeroc',
        permlink: 'piston',
        weight: 10000
      }
      
      operation = Radiator::Operation.new(vote)
      
      @transaction.operations << operation
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      
      # Here, we're going to take apart our contrived serialization so we can
      # verify each substring individually.
      
      chain_id = hex[0..63]
      ref_block_num = hex[64..67]
      ref_block_prefix = hex[68..75]
      exp = hex[76..83]
      op_len = hex[84..85]
      op_id = hex[86..87]
      voter = hex[88..99]
      author = hex[100..111]
      permlink = hex[112..125]
      weight = hex[126..129]
      extensions = hex[130..131]
      
      hex_segments = {
        chain_id: chain_id, ref_block_num: ref_block_num,
        ref_block_prefix: ref_block_prefix, exp: exp, op_len: op_len,
        op_id: op_id, voter: voter, author: author, permlink: permlink,
        weight: weight, extensions: extensions
      }
      
      # This example serialization was documented by xeroc:
      # https://steemit.com/steem/@xeroc/steem-transaction-signing-in-a-nutshell
      example_hex = 'bd8c5fe26f45f179a8570100057865726f63057865726f6306706973746f6e102'
      assert hex.include?(example_hex), 'expect example_hex in our result'
      
      # Later correction by xeroc:
      # https://steemit.com/steem/@xeroc/steem-transaction-signing-in-a-nutshell#@xeroc/re-steem-transaction-signing-in-a-nutshell-20160901t151404
      example_hex2 = 'bd8c5fe26f45f179a8570100057865726f63057865726f6306706973746f6e102700'
      assert hex.include?(example_hex2), 'expect example_hex2 in our result'
      
      # The only thing that should if we remove the second example is the chain_id.
      remaining_hex = hex.gsub example_hex2, ''
      assert_equal '0000000000000000000000000000000000000000000000000000000000000000',
        remaining_hex, 'expect nothing but the chain_id'
      
      # Here, we're going to take apart our contrived serialization so we can
      # verify each substring.
      
      assert_equal '0000000000000000000000000000000000000000000000000000000000000000',
        hex_segments[:chain_id], 'expect chain_id'
      assert_equal 'bd8c', hex_segments[:ref_block_num], 'expect ref_block_num'
      assert_equal '5fe26f45', hex_segments[:ref_block_prefix], 'expect ref_block_prefix'
      assert_equal 'f179a857', hex_segments[:exp], 'expect exp'
      assert_equal '01', hex_segments[:op_len], 'expect op_len'
      assert_equal '00', hex_segments[:op_id], 'expect op_id'
      assert_equal '057865726f63', hex_segments[:voter], 'expect voter'
      assert_equal '057865726f63', hex_segments[:author], 'expect author'
      assert_equal '06706973746f6e', hex_segments[:permlink], 'expect permlink'
      assert_equal '1027', hex_segments[:weight], 'expect weight'
      assert_equal '00', hex_segments[:extensions], 'expect extensions'
      assert_equal hex, hex_segments.values.join
    end
    
    def test_digest
      vote = {
        type: :vote,
        voter: 'xeroc',
        author: 'xeroc',
        permlink: 'piston',
        weight: 10000
      }
      
      operation = Radiator::Operation.new(vote)
      
      @transaction.operations << operation

      refute_nil digest = @transaction.send(:digest)
      
      # This is how the example given by @xeroc deals with the signature.  It
      # does not include the extensions count.
      # 
      # https://gist.github.com/xeroc/9bda11add796b603d83eb4b41d38532b
      example_bytes = @transaction.send(:to_bytes).chop
      example_digest = Digest::SHA256.digest example_bytes
      assert_equal 'ccbcb7d64444356654febe83b8010ca50d99edd0389d273b63746ecaf21adb92', hexlify(example_digest),
        'epect example output from digest'
      refute_equal hexlify(digest), hexlify(example_digest),
        'did not expect example output to match normal output'
      
      assert_equal '582176b1daf89984bc8b4fdcb24ff1433d1eb114a8c4bf20fb22ad580d035889', hexlify(digest)
        'expect normal output from digest'
    end
    
    def test_signature
      vote = {
        type: :vote,
        voter: 'meanpeoplesuck',
        author: 'shadowspub',
        permlink: 'feb-23-steemit-ramble-76-don-t-you-hate-missing-good-posts',
        weight: 10000
      }
      
      operation = Radiator::Operation.new(vote)
      
      @transaction.operations << operation

      refute_nil sig_data = @transaction.send(:signature)
    end
  end
end
