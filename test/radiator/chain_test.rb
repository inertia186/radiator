require 'test_helper'

module Radiator
  class ChainTest < Radiator::Test
    def setup
      options = {
        chain: :steem,
        account_name: 'social',
        wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      }
      
      @chain = Radiator::Chain.new(options)
    end
    
    def test_find_block
      VCR.use_cassette('find_block', record: VCR_RECORD_MODE) do
        refute_nil @chain.find_block(424377)
      end
    end
    
    def test_find_account
      VCR.use_cassette('find_account', record: VCR_RECORD_MODE) do
        refute_nil @chain.find_account('ned')
      end
    end
    
    def test_find_comment
      VCR.use_cassette('find_comment', record: VCR_RECORD_MODE) do
        refute_nil @chain.find_comment('inertia', 'kinda-spooky')
      end
    end
    
    def test_properties
      VCR.use_cassette('properties', record: VCR_RECORD_MODE) do
        refute_nil @chain.properties
      end
    end
    
    def test_block_time
      VCR.use_cassette('block_time', record: VCR_RECORD_MODE) do
        refute_nil @chain.block_time
      end
    end
    
    def test_base_per_mvest
      VCR.use_cassette('base_per_mvest', record: VCR_RECORD_MODE) do
        refute_nil @chain.base_per_mvest
      end
    end
    
    def test_base_per_debt
      VCR.use_cassette('base_per_debt', record: VCR_RECORD_MODE) do
        refute_nil @chain.base_per_debt
      end
    end
    
    def test_followed_by
      VCR.use_cassette('followed_by', record: VCR_RECORD_MODE) do
        refute_nil @chain.followed_by('inertia')
      end
    end
    
    def test_following
      VCR.use_cassette('following', record: VCR_RECORD_MODE) do
        refute_nil @chain.following('inertia')
      end
    end
    
    def test_post!
      options = {
        title: 'title of my post',
        body: 'body of my post',
        tags: ['tag'],
        self_upvote: 10000,
        percent_steem_dollars: 0
      }
      
      VCR.use_cassette('post!', record: VCR_RECORD_MODE) do
        result = @chain.post!(options)
        refute_nil result
        assert_equal ErrorParser, result.class, "expect ErrorParser, got result: #{result}"
        assert_equal '4100000: The comment is archived', result.to_s
      end
    end
  end
end
