require 'test_helper'

module Radiator
  class TransactionTest < Radiator::Test
    include Utils
    
    def setup
      options = {
        wif: '5JLw5dgQAx6rhZEgNN5C2ds1V47RweGshynFSWFbaMohsYsBvE8',
        ref_block_num: 36029,
        ref_block_prefix: 1164960351,
        expiration: Time.parse('2016-08-08T12:24:17 Z'),
        failover_urls: [],
        logger: Logger.new(nil).tap do |logger|
          logger.progname = 'transction-test'
        end
      }
      
      @transaction = Radiator::Transaction.new(options.dup)
    end
    
    def test_valid_chains
      %w(steem test).each do |chain|
        io = StringIO.new
        log = Logger.new(io).tap do |logger|
          logger.progname = 'test-valid-chains'
        end
        
        case chain.to_sym
        when :steem
          transaction = Radiator::Transaction.new(chain: chain, logger: log)
          assert_equal Radiator::Transaction::NETWORKS_STEEM_CHAIN_ID, transaction.chain_id, 'expect steem chain'
        when :test
          assert_raises ApiError do
            transaction = Radiator::Transaction.new(chain: chain, logger: log)
          end
        else
          # :nocov:
          fail "did not expect chain: #{chain}"
          # :nocov:
        end
        assert_equal '', io.string, 'expect empty log'
      end
    end
    
    def test_unknown_chain
      io = StringIO.new
      Radiator.logger = Logger.new(io).tap do |logger| # side effect: increase code coverage
        logger.progname = 'test-unknown-chain'
      end
      chain = 'ginger'
      assert_raises ApiError do
        Radiator::Transaction.new(chain: chain)
      end
      refute_equal '', io.string, 'did not expect empty log'
      assert io.string.include?('Unknown chain id'), 'expect log to mention unknown chain id'
    end
    
    def test_unknown_chain_id
      io = StringIO.new
      log = Logger.new(io).tap do |logger|
        logger.progname = 'test-unknown-chain-id'
      end
      unknown_chain_id = 'F' * (256 / 4)
      Radiator::Transaction.new(chain_id: unknown_chain_id, logger: log)
      
      refute_equal '', io.string, 'did not expect empty log'
      assert io.string.include?(unknown_chain_id), 'expect log to mention unknown chain id'
    end
    
    def test_wif_and_private_key
      assert_raises TransactionError, 'expect transaction to freak when it sees both' do
        Radiator::Transaction.new(wif: 'wif', private_key: 'private key')
      end
    end
    
    def test_ref_block_num
      vcr_cassette('ref_block_num') do
        @transaction.operations << {type: :vote}
        @transaction.process(false)
        payload = @transaction.send(:payload)
        assert_equal 36029, payload[:ref_block_num], 'expect a certain ref_block_prefix'
      end
    end
    
    def test_ref_block_prefix
      vcr_cassette('ref_block_prefix') do
        @transaction.operations << {type: :vote}
        @transaction.process(false)
        payload = @transaction.send(:payload)
        assert_equal 1164960351, payload[:ref_block_prefix], 'expect a certain ref_block_prefix'
      end
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
        weight: 10000,
        extensions: [],
      }
      
      @transaction.operations << vote
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
      
      # The only thing that should remain if we remove the second example is the
      # chain_id.
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
      
      @transaction.operations << vote

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
        voter: 'xeroc',
        author: 'xeroc',
        permlink: 'piston',
        weight: 10000
      }
      
      @transaction.operations << vote

      refute_nil _sig_data = @transaction.send(:signature)
    end
    
    def test_signature_long_input
      vote = {
        type: :comment,
        author: 'xeroc',
        permlink: 'piston',
        body: 'test' * 900
      }
      
      @transaction.operations << vote

      refute_nil _sig_data = @transaction.send(:signature)
    end
    
    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L426
    def test_utf8
      op = {
        type: :comment,
        parent_author: "",
        parent_permlink: "",
        author: "a",
        permlink: "a",
        title: "-",
        body: [*(0..2048)].map { |i| [i].pack('U') }.join.chop,
        json_metadata: {}.to_json
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        parent_author: hex[88..89],
        parent_permlink: hex[90..91],
        author: hex[92..95],
        permlink: hex[96..99],
        title: hex[100..103],
        body: hex[104..8043],
        json_metadata: hex[8044..8049]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '01', hex_segments[:op_id], 'expect op_id'
      assert_equal '00', hex_segments[:parent_author], 'expect parent_author'
      assert_equal '00', hex_segments[:parent_permlink], 'expect parent_permlink'
      assert_equal '0161', hex_segments[:author], 'expect author'
      assert_equal '0161', hex_segments[:permlink], 'expect permlink'
      assert_equal '012d', hex_segments[:title], 'expect title'
      assert_equal 7940, hex_segments[:body].size, 'expect body (hex) size'
      assert_equal '027b7d', hex_segments[:json_metadata], 'expect json_metadata'
      
      compare = 'f68585abf4dce7c804570101000001610161012dec1f75303030307' +
        '5303030317530303032753030303375303030347530303035753030' +
        '3036753030303762090a7530303062660d753030306575303030667' +
        '5303031307530303131753030313275303031337530303134753030' +
        '3135753030313675303031377530303138753030313975303031617' +
        '5303031627530303163753030316475303031657530303166202122' +
        '232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3' +
        'e3f404142434445464748494a4b4c4d4e4f50515253545556575859' +
        '5a5b5c5d5e5f606162636465666768696a6b6c6d6e6f70717273747' +
        '5767778797a7b7c7d7e7fc280c281c282c283c284c285c286c287c2' +
        '88c289c28ac28bc28cc28dc28ec28fc290c291c292c293c294c295c' +
        '296c297c298c299c29ac29bc29cc29dc29ec29fc2a0c2a1c2a2c2a3' +
        'c2a4c2a5c2a6c2a7c2a8c2a9c2aac2abc2acc2adc2aec2afc2b0c2b' +
        '1c2b2c2b3c2b4c2b5c2b6c2b7c2b8c2b9c2bac2bbc2bcc2bdc2bec2' +
        'bfc380c381c382c383c384c385c386c387c388c389c38ac38bc38cc' +
        '38dc38ec38fc390c391c392c393c394c395c396c397c398c399c39a' +
        'c39bc39cc39dc39ec39fc3a0c3a1c3a2c3a3c3a4c3a5c3a6c3a7c3a' +
        '8c3a9c3aac3abc3acc3adc3aec3afc3b0c3b1c3b2c3b3c3b4c3b5c3' +
        'b6c3b7c3b8c3b9c3bac3bbc3bcc3bdc3bec3bfc480c481c482c483c' +
        '484c485c486c487c488c489c48ac48bc48cc48dc48ec48fc490c491' +
        'c492c493c494c495c496c497c498c499c49ac49bc49cc49dc49ec49' +
        'fc4a0c4a1c4a2c4a3c4a4c4a5c4a6c4a7c4a8c4a9c4aac4abc4acc4' +
        'adc4aec4afc4b0c4b1c4b2c4b3c4b4c4b5c4b6c4b7c4b8c4b9c4bac' +
        '4bbc4bcc4bdc4bec4bfc580c581c582c583c584c585c586c587c588' +
        'c589c58ac58bc58cc58dc58ec58fc590c591c592c593c594c595c59' +
        '6c597c598c599c59ac59bc59cc59dc59ec59fc5a0c5a1c5a2c5a3c5' +
        'a4c5a5c5a6c5a7c5a8c5a9c5aac5abc5acc5adc5aec5afc5b0c5b1c' +
        '5b2c5b3c5b4c5b5c5b6c5b7c5b8c5b9c5bac5bbc5bcc5bdc5bec5bf' +
        'c680c681c682c683c684c685c686c687c688c689c68ac68bc68cc68' +
        'dc68ec68fc690c691c692c693c694c695c696c697c698c699c69ac6' +
        '9bc69cc69dc69ec69fc6a0c6a1c6a2c6a3c6a4c6a5c6a6c6a7c6a8c' +
        '6a9c6aac6abc6acc6adc6aec6afc6b0c6b1c6b2c6b3c6b4c6b5c6b6' +
        'c6b7c6b8c6b9c6bac6bbc6bcc6bdc6bec6bfc780c781c782c783c78' +
        '4c785c786c787c788c789c78ac78bc78cc78dc78ec78fc790c791c7' +
        '92c793c794c795c796c797c798c799c79ac79bc79cc79dc79ec79fc' +
        '7a0c7a1c7a2c7a3c7a4c7a5c7a6c7a7c7a8c7a9c7aac7abc7acc7ad' +
        'c7aec7afc7b0c7b1c7b2c7b3c7b4c7b5c7b6c7b7c7b8c7b9c7bac7b' +
        'bc7bcc7bdc7bec7bfc880c881c882c883c884c885c886c887c888c8' +
        '89c88ac88bc88cc88dc88ec88fc890c891c892c893c894c895c896c' +
        '897c898c899c89ac89bc89cc89dc89ec89fc8a0c8a1c8a2c8a3c8a4' +
        'c8a5c8a6c8a7c8a8c8a9c8aac8abc8acc8adc8aec8afc8b0c8b1c8b' +
        '2c8b3c8b4c8b5c8b6c8b7c8b8c8b9c8bac8bbc8bcc8bdc8bec8bfc9' +
        '80c981c982c983c984c985c986c987c988c989c98ac98bc98cc98dc' +
        '98ec98fc990c991c992c993c994c995c996c997c998c999c99ac99b' +
        'c99cc99dc99ec99fc9a0c9a1c9a2c9a3c9a4c9a5c9a6c9a7c9a8c9a' +
        '9c9aac9abc9acc9adc9aec9afc9b0c9b1c9b2c9b3c9b4c9b5c9b6c9' +
        'b7c9b8c9b9c9bac9bbc9bcc9bdc9bec9bfca80ca81ca82ca83ca84c' +
        'a85ca86ca87ca88ca89ca8aca8bca8cca8dca8eca8fca90ca91ca92' +
        'ca93ca94ca95ca96ca97ca98ca99ca9aca9bca9cca9dca9eca9fcaa' +
        '0caa1caa2caa3caa4caa5caa6caa7caa8caa9caaacaabcaaccaadca' +
        'aecaafcab0cab1cab2cab3cab4cab5cab6cab7cab8cab9cabacabbc' +
        'abccabdcabecabfcb80cb81cb82cb83cb84cb85cb86cb87cb88cb89' +
        'cb8acb8bcb8ccb8dcb8ecb8fcb90cb91cb92cb93cb94cb95cb96cb9' +
        '7cb98cb99cb9acb9bcb9ccb9dcb9ecb9fcba0cba1cba2cba3cba4cb' +
        'a5cba6cba7cba8cba9cbaacbabcbaccbadcbaecbafcbb0cbb1cbb2c' +
        'bb3cbb4cbb5cbb6cbb7cbb8cbb9cbbacbbbcbbccbbdcbbecbbfcc80' +
        'cc81cc82cc83cc84cc85cc86cc87cc88cc89cc8acc8bcc8ccc8dcc8' +
        'ecc8fcc90cc91cc92cc93cc94cc95cc96cc97cc98cc99cc9acc9bcc' +
        '9ccc9dcc9ecc9fcca0cca1cca2cca3cca4cca5cca6cca7cca8cca9c' +
        'caaccabccacccadccaeccafccb0ccb1ccb2ccb3ccb4ccb5ccb6ccb7' +
        'ccb8ccb9ccbaccbbccbcccbdccbeccbfcd80cd81cd82cd83cd84cd8' +
        '5cd86cd87cd88cd89cd8acd8bcd8ccd8dcd8ecd8fcd90cd91cd92cd' +
        '93cd94cd95cd96cd97cd98cd99cd9acd9bcd9ccd9dcd9ecd9fcda0c' +
        'da1cda2cda3cda4cda5cda6cda7cda8cda9cdaacdabcdaccdadcdae' +
        'cdafcdb0cdb1cdb2cdb3cdb4cdb5cdb6cdb7cdb8cdb9cdbacdbbcdb' +
        'ccdbdcdbecdbfce80ce81ce82ce83ce84ce85ce86ce87ce88ce89ce' +
        '8ace8bce8cce8dce8ece8fce90ce91ce92ce93ce94ce95ce96ce97c' +
        'e98ce99ce9ace9bce9cce9dce9ece9fcea0cea1cea2cea3cea4cea5' +
        'cea6cea7cea8cea9ceaaceabceacceadceaeceafceb0ceb1ceb2ceb' +
        '3ceb4ceb5ceb6ceb7ceb8ceb9cebacebbcebccebdcebecebfcf80cf' +
        '81cf82cf83cf84cf85cf86cf87cf88cf89cf8acf8bcf8ccf8dcf8ec' +
        'f8fcf90cf91cf92cf93cf94cf95cf96cf97cf98cf99cf9acf9bcf9c' +
        'cf9dcf9ecf9fcfa0cfa1cfa2cfa3cfa4cfa5cfa6cfa7cfa8cfa9cfa' +
        'acfabcfaccfadcfaecfafcfb0cfb1cfb2cfb3cfb4cfb5cfb6cfb7cf' +
        'b8cfb9cfbacfbbcfbccfbdcfbecfbfd080d081d082d083d084d085d' +
        '086d087d088d089d08ad08bd08cd08dd08ed08fd090d091d092d093' +
        'd094d095d096d097d098d099d09ad09bd09cd09dd09ed09fd0a0d0a' +
        '1d0a2d0a3d0a4d0a5d0a6d0a7d0a8d0a9d0aad0abd0acd0add0aed0' +
        'afd0b0d0b1d0b2d0b3d0b4d0b5d0b6d0b7d0b8d0b9d0bad0bbd0bcd' +
        '0bdd0bed0bfd180d181d182d183d184d185d186d187d188d189d18a' +
        'd18bd18cd18dd18ed18fd190d191d192d193d194d195d196d197d19' +
        '8d199d19ad19bd19cd19dd19ed19fd1a0d1a1d1a2d1a3d1a4d1a5d1' +
        'a6d1a7d1a8d1a9d1aad1abd1acd1add1aed1afd1b0d1b1d1b2d1b3d' +
        '1b4d1b5d1b6d1b7d1b8d1b9d1bad1bbd1bcd1bdd1bed1bfd280d281' +
        'd282d283d284d285d286d287d288d289d28ad28bd28cd28dd28ed28' +
        'fd290d291d292d293d294d295d296d297d298d299d29ad29bd29cd2' +
        '9dd29ed29fd2a0d2a1d2a2d2a3d2a4d2a5d2a6d2a7d2a8d2a9d2aad' +
        '2abd2acd2add2aed2afd2b0d2b1d2b2d2b3d2b4d2b5d2b6d2b7d2b8' +
        'd2b9d2bad2bbd2bcd2bdd2bed2bfd380d381d382d383d384d385d38' +
        '6d387d388d389d38ad38bd38cd38dd38ed38fd390d391d392d393d3' +
        '94d395d396d397d398d399d39ad39bd39cd39dd39ed39fd3a0d3a1d' +
        '3a2d3a3d3a4d3a5d3a6d3a7d3a8d3a9d3aad3abd3acd3add3aed3af' +
        'd3b0d3b1d3b2d3b3d3b4d3b5d3b6d3b7d3b8d3b9d3bad3bbd3bcd3b' +
        'dd3bed3bfd480d481d482d483d484d485d486d487d488d489d48ad4' +
        '8bd48cd48dd48ed48fd490d491d492d493d494d495d496d497d498d' +
        '499d49ad49bd49cd49dd49ed49fd4a0d4a1d4a2d4a3d4a4d4a5d4a6' +
        'd4a7d4a8d4a9d4aad4abd4acd4add4aed4afd4b0d4b1d4b2d4b3d4b' +
        '4d4b5d4b6d4b7d4b8d4b9d4bad4bbd4bcd4bdd4bed4bfd580d581d5' +
        '82d583d584d585d586d587d588d589d58ad58bd58cd58dd58ed58fd' +
        '590d591d592d593d594d595d596d597d598d599d59ad59bd59cd59d' +
        'd59ed59fd5a0d5a1d5a2d5a3d5a4d5a5d5a6d5a7d5a8d5a9d5aad5a' +
        'bd5acd5add5aed5afd5b0d5b1d5b2d5b3d5b4d5b5d5b6d5b7d5b8d5' +
        'b9d5bad5bbd5bcd5bdd5bed5bfd680d681d682d683d684d685d686d' +
        '687d688d689d68ad68bd68cd68dd68ed68fd690d691d692d693d694' +
        'd695d696d697d698d699d69ad69bd69cd69dd69ed69fd6a0d6a1d6a' +
        '2d6a3d6a4d6a5d6a6d6a7d6a8d6a9d6aad6abd6acd6add6aed6afd6' +
        'b0d6b1d6b2d6b3d6b4d6b5d6b6d6b7d6b8d6b9d6bad6bbd6bcd6bdd' +
        '6bed6bfd780d781d782d783d784d785d786d787d788d789d78ad78b' +
        'd78cd78dd78ed78fd790d791d792d793d794d795d796d797d798d79' +
        '9d79ad79bd79cd79dd79ed79fd7a0d7a1d7a2d7a3d7a4d7a5d7a6d7' +
        'a7d7a8d7a9d7aad7abd7acd7add7aed7afd7b0d7b1d7b2d7b3d7b4d' +
        '7b5d7b6d7b7d7b8d7b9d7bad7bbd7bcd7bdd7bed7bfd880d881d882' +
        'd883d884d885d886d887d888d889d88ad88bd88cd88dd88ed88fd89' +
        '0d891d892d893d894d895d896d897d898d899d89ad89bd89cd89dd8' +
        '9ed89fd8a0d8a1d8a2d8a3d8a4d8a5d8a6d8a7d8a8d8a9d8aad8abd' +
        '8acd8add8aed8afd8b0d8b1d8b2d8b3d8b4d8b5d8b6d8b7d8b8d8b9' +
        'd8bad8bbd8bcd8bdd8bed8bfd980d981d982d983d984d985d986d98' +
        '7d988d989d98ad98bd98cd98dd98ed98fd990d991d992d993d994d9' +
        '95d996d997d998d999d99ad99bd99cd99dd99ed99fd9a0d9a1d9a2d' +
        '9a3d9a4d9a5d9a6d9a7d9a8d9a9d9aad9abd9acd9add9aed9afd9b0' +
        'd9b1d9b2d9b3d9b4d9b5d9b6d9b7d9b8d9b9d9bad9bbd9bcd9bdd9b' +
        'ed9bfda80da81da82da83da84da85da86da87da88da89da8ada8bda' +
        '8cda8dda8eda8fda90da91da92da93da94da95da96da97da98da99d' +
        'a9ada9bda9cda9dda9eda9fdaa0daa1daa2daa3daa4daa5daa6daa7' +
        'daa8daa9daaadaabdaacdaaddaaedaafdab0dab1dab2dab3dab4dab' +
        '5dab6dab7dab8dab9dabadabbdabcdabddabedabfdb80db81db82db' +
        '83db84db85db86db87db88db89db8adb8bdb8cdb8ddb8edb8fdb90d' +
        'b91db92db93db94db95db96db97db98db99db9adb9bdb9cdb9ddb9e' +
        'db9fdba0dba1dba2dba3dba4dba5dba6dba7dba8dba9dbaadbabdba' +
        'cdbaddbaedbafdbb0dbb1dbb2dbb3dbb4dbb5dbb6dbb7dbb8dbb9db' +
        'badbbbdbbcdbbddbbedbbfdc80dc81dc82dc83dc84dc85dc86dc87d' +
        'c88dc89dc8adc8bdc8cdc8ddc8edc8fdc90dc91dc92dc93dc94dc95' +
        'dc96dc97dc98dc99dc9adc9bdc9cdc9ddc9edc9fdca0dca1dca2dca' +
        '3dca4dca5dca6dca7dca8dca9dcaadcabdcacdcaddcaedcafdcb0dc' +
        'b1dcb2dcb3dcb4dcb5dcb6dcb7dcb8dcb9dcbadcbbdcbcdcbddcbed' +
        'cbfdd80dd81dd82dd83dd84dd85dd86dd87dd88dd89dd8add8bdd8c' +
        'dd8ddd8edd8fdd90dd91dd92dd93dd94dd95dd96dd97dd98dd99dd9' +
        'add9bdd9cdd9ddd9edd9fdda0dda1dda2dda3dda4dda5dda6dda7dd' +
        'a8dda9ddaaddabddacddadddaeddafddb0ddb1ddb2ddb3ddb4ddb5d' +
        'db6ddb7ddb8ddb9ddbaddbbddbcddbdddbeddbfde80de81de82de83' +
        'de84de85de86de87de88de89de8ade8bde8cde8dde8ede8fde90de9' +
        '1de92de93de94de95de96de97de98de99de9ade9bde9cde9dde9ede' +
        '9fdea0dea1dea2dea3dea4dea5dea6dea7dea8dea9deaadeabdeacd' +
        'eaddeaedeafdeb0deb1deb2deb3deb4deb5deb6deb7deb8deb9deba' +
        'debbdebcdebddebedebfdf80df81df82df83df84df85df86df87df8' +
        '8df89df8adf8bdf8cdf8ddf8edf8fdf90df91df92df93df94df95df' +
        '96df97df98df99df9adf9bdf9cdf9ddf9edf9fdfa0dfa1dfa2dfa3d' +
        'fa4dfa5dfa6dfa7dfa8dfa9dfaadfabdfacdfaddfaedfafdfb0dfb1' +
        'dfb2dfb3dfb4dfb5dfb6dfb7dfb8dfb9dfbadfbbdfbcdfbddfbedfb' +
        'f0000011f45c8e1ed9289f5ec7d4f6d7ce891a30ede7470e28d4639' +
        '8e0dc15c41c784b1862f132378382230d68b59e3592e72a32f310f8' +
        '8ea4baddb361a3709b664ba7375'
      
      skip "Suspect the original compare string might be incorrect."
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end
    
    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L600
    def test_feed_publish
      op = {
        type: :feed_publish,
        publisher: 'xeroc',
        exchange_rate: {
          base: '1.000 SBD',
          quote: '4.123 STEEM'
        }
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        publisher: hex[88..99],
        exchange_rate: hex[100..159]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '07', hex_segments[:op_id], 'expect op_id'
      assert_equal '057865726f63', hex_segments[:publisher], 'expect publisher'
      assert_equal 'e80300000000000003534244000000001b1000000000000003535445454d', hex_segments[:exchange_rate], 'expect exchange_rate'
      
      compare = 'f68585abf4dce7c804570107057865726f63e803000000000' +
        '00003534244000000001b1000000000000003535445454d00' +
        '000001203847a02aa76964cacfb41565c23286cc64b18f6bb' +
        '9260832823839b3b90dff18738e1b686ad22f79c42fca73e6' +
        '1bf633505a2a66cac65555b0ac535ca5ee5a61'
        
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end
    
    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L650
    def test_account_witness_vote
      op = {
        type: :account_witness_vote,
        account: 'xeroc',
        witness: 'chainsquad',
        approve: true
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        account: hex[88..99],
        witness: hex[100..121],
        approve: hex[122..123]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '0c', hex_segments[:op_id], 'expect op_id'
      assert_equal '057865726f63', hex_segments[:account], 'expect account'
      assert_equal '0a636861696e7371756164', hex_segments[:witness], 'expect witness'
      assert_equal '01', hex_segments[:approve], 'expect approve'
      
      compare = 'f68585abf4dce7c80457010c057865726f630a636' +
        '861696e73717561640100011f16b43411e11f4739' +
        '4c1624a3c4d3cf4daba700b8690f494e6add7ad9b' +
        'ac735ce7775d823aa66c160878cb3348e6857c531' +
        '114d229be0202dc0857f8f03a00369'
      
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end
    
    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L673
    def test_custom_json
      op = {
        type: :custom_json,
        required_auths: [],
        required_posting_auths: ['xeroc'],
        id: 'follow',
        json: '["reblog", {"account": "xeroc", "author": "chainsquad", "permlink": "streemian-com-to-open-its-doors-and-offer-a-20-discount"}]'
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        required_auths: hex[88..89],
        required_posting_auths: hex[90..103],
        id: hex[104..117],
        json: hex[118..373]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '12', hex_segments[:op_id], 'expect op_id'
      assert_equal '00', hex_segments[:required_auths], 'expect required_auths'
      assert_equal '01057865726f63', hex_segments[:required_posting_auths], 'expect required_posting_auths'
      assert_equal '06666f6c6c6f77', hex_segments[:id], 'expect id'
      assert_equal '7f5b227265626c6f67222c207b226163636f756e74223a20227865726f63222c2022617574686f72223a2022636861696e7371756164222c20227065726d6c696e6b223a202273747265656d69616e2d636f6d2d746f2d6f70656e2d6974732d646f6f72732d616e642d6f666665722d612d32302d646973636f756e74227d5d',
        hex_segments[:json], 'expect json'
      
      compare = 'f68585abf4dce7c8045701120001057865726f6306666f6c6c' +
        '6f777f5b227265626c6f67222c207b226163636f756e74223a' +
        '20227865726f63222c2022617574686f72223a202263686169' +
        '6e7371756164222c20227065726d6c696e6b223a2022737472' +
        '65656d69616e2d636f6d2d746f2d6f70656e2d6974732d646f' +
        '6f72732d616e642d6f666665722d612d32302d646973636f75' +
        '6e74227d5d00011f0cffad16cfd8ea4b84c06d412e93a9fc10' +
        '0bf2fac5f9a40d37d5773deef048217db79cabbf15ef29452d' +
        'e4ed1c5face51d998348188d66eb9fc1ccef79a0c0d4'
        
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end

    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L708
    def test_comment_options
      op = {
        type: :comment_options,
        author: 'xeroc',
        permlink: 'piston',
        max_accepted_payout: '1000000.000 SBD',
        percent_steem_dollars: 10000,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: []
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        author: hex[88..99],
        permlink: hex[100..113],
        max_accepted_payout: hex[114..145],
        percent_steem_dollars: hex[146..149],
        allow_votes: hex[150..151],
        allow_curation_rewards: hex[152..153],
        op_extensions: hex[154..155]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '13', hex_segments[:op_id], 'expect op_id'
      assert_equal '057865726f63', hex_segments[:author], 'expect author'
      assert_equal '06706973746f6e', hex_segments[:permlink], 'expect permlink'
      assert_equal '00ca9a3b000000000353424400000000', hex_segments[:max_accepted_payout], 'expect max_accepted_payout'
      assert_equal '1027', hex_segments[:percent_steem_dollars], 'expect percent_steem_dollars'
      assert_equal '01', hex_segments[:allow_votes], 'expect allow_votes'
      assert_equal '01', hex_segments[:allow_curation_rewards], 'expect allow_curation_rewards'
      assert_equal '00', hex_segments[:op_extensions], 'expect op_extensions'

      compare = 'f68585abf4dce7c804570113057865726f6306706973746f6e' +
        '00ca9a3b000000000353424400000000102701010000011f20' +
        'feacc3f917dfa2d6082afb5ab5aab82d7df1428130c7b7eec4' +
        '56d259e59fc54ee582a5a86073508f69ffebea4283f13d1a89' +
        '6243754a4a82fa18077f832225'
      
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end
    
    # See: https://github.com/steemit/steem-python/blob/master/tests/steem/test_transactions.py#L738
    def test_comment_options_with_beneficiaries
      op = {
        type: :comment_options,
        author: 'xeroc',
        permlink: 'piston',
        max_accepted_payout: '1000000.000 SBD',
        percent_steem_dollars: 10000,
        allow_replies: true,
        allow_votes: true,
        allow_curation_rewards: true,
        extensions: Radiator::Type::Beneficiaries.new('good-karma' => 2000, 'null' => 5000)
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        author: hex[88..99],
        permlink: hex[100..113],
        max_accepted_payout: hex[114..145],
        percent_steem_dollars: hex[146..149],
        allow_replies: hex[150..151],
        allow_votes: hex[152..153],
        allow_curation_rewards: hex[154..155],
        op_extensions: hex[156..199]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '13', hex_segments[:op_id], 'expect op_id'
      assert_equal '057865726f63', hex_segments[:author], 'expect author'
      assert_equal '06706973746f6e', hex_segments[:permlink], 'expect permlink'
      assert_equal '00ca9a3b000000000353424400000000', hex_segments[:max_accepted_payout], 'expect max_accepted_payout'
      assert_equal '1027', hex_segments[:percent_steem_dollars], 'expect percent_steem_dollars'
      assert_equal '01', hex_segments[:allow_replies], 'expect allow_replies'
      assert_equal '01', hex_segments[:allow_votes], 'expect allow_votes'
      assert_equal '01', hex_segments[:allow_curation_rewards], 'expect allow_curation_rewards'
      assert_equal '00020a676f6f642d6b61726d61d007046e756c6c8813',
        hex_segments[:op_extensions], 'expect op_extensions'
      
      compare = 'f68585abf4dce7c804570113057865726f6306706973746f6e' +
        '00ca9a3b000000000353424400000000102701010100020a67' +
        '6f6f642d6b61726d61d007046e756c6c881300011f59634e65' +
        '55fec7c01cb7d4921601c37c250c6746022cc35eaefdd90405' +
        'd7771b2f65b44e97b7f3159a6d52cb20640502d2503437215f' +
        '0907b2e2213940f34f2c'
          
      op_hex = sub_hex(hex_segments)
      assert compare.include?(op_hex), 'expect final comparison from original test'
    end
    
    def test_chronicle_comment_options
      op = {
        type: :comment_options,
        max_accepted_payout: '1000000.000 SBD',
        percent_steem_dollars: 10000,
        allow_replies: true,
        allow_votes: true,
        allow_curation_rewards: true,
        beneficiaries: [{"inertia":500}],
        author: "social",
        permlink: "lorem-ipsum4",
        extensions: Radiator::Type::Beneficiaries.new(inertia: 500)
      }
      
      @transaction.operations << op
      
      refute_nil bytes = @transaction.send(:to_bytes)
      hex = hexlify(bytes)
      hex_segments = seg(hex).merge(
        author: hex[88..101],
        permlink: hex[102..127],
        max_accepted_payout: hex[128..159],
        percent_steem_dollars: hex[160..163],
        allow_replies: hex[164..165],
        allow_votes: hex[166..167],
        allow_curation_rewards: hex[168..169],
        op_extensions: hex[170..193]
      )
      
      decoded_op_id = "0x#{hex_segments[:op_id]}".to_i(16)
      assert_equal Radiator::OperationIds::IDS.find_index(op[:type]), decoded_op_id
      
      assert_equal '13', hex_segments[:op_id], 'expect op_id'
      assert_equal '06736f6369616c', hex_segments[:author], 'expect author'
      assert_equal '0c6c6f72656d2d697073756d34', hex_segments[:permlink], 'expect permlink'
      assert_equal '00ca9a3b000000000353424400000000', hex_segments[:max_accepted_payout], 'expect max_accepted_payout'
      assert_equal '1027', hex_segments[:percent_steem_dollars], 'expect percent_steem_dollars'
      assert_equal '01', hex_segments[:allow_replies], 'expect allow_replies'
      assert_equal '01', hex_segments[:allow_votes], 'expect allow_votes'
      assert_equal '01', hex_segments[:allow_curation_rewards], 'expect allow_curation_rewards'
      assert_equal '000107696e6572746961f401', hex_segments[:op_extensions], 'expect op_extensions'
    end
    
    def test_operations_assignment
      @transaction.operations = [{type: :vote}]
      
      assert_equal Operation, @transaction.operations.first.class
    end
    
    def test_expiration_initialize
      exp = Time.now.utc
      tx = Transaction.new(expiration: exp)
      
      assert_equal exp, tx.expiration
    end
    
    def test_expiration_initialize_nil
      tx = Transaction.new
      
      assert_nil tx.expiration
    end
    
    def test_payload_persists_until_reprepared
      @transaction.send :prepare
      expected_payload = @transaction.send :payload
      assert_equal expected_payload, @transaction.send(:payload)
      @transaction.send :prepare
      refute_equal expected_payload, @transaction.send(:payload)
    end
  private
    def seg(hex)
      seg = {
        chain_id: hex[0..63], ref_block_num: hex[64..67],
        ref_block_prefix: hex[68..75], exp: hex[76..83], op_len: hex[84..85],
        op_id: hex[86..87], extensions: hex[(hex.size - 2)..hex.size]
      }
      
      seg.tap do |s|
        assert_equal '0' * 64, s[:chain_id], 'expect chain_id'
        assert_equal 'bd8c', s[:ref_block_num], 'expect ref_block_num'
        assert_equal '5fe26f45', s[:ref_block_prefix], 'expect ref_block_prefix'
        assert_equal 'f179a857', s[:exp], 'expect exp'
        assert_equal '01', s[:op_len], 'expect op_len'
        assert_equal '00', s[:extensions], 'expect extensions'
      end
    end
    
    def sub_hex(segments)
      exclude = %i(chain_id ref_block_num ref_block_prefix exp op_len op_id extensions)
      segments.map { |k, v| v unless exclude.include? k }.compact.join
    end
  end
end
