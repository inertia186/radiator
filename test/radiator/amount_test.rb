require 'test_helper'

module Radiator
  class AmountTest < Radiator::Test
    def test_to_s
      _amount = Type::Amount.new('0.000 STEEM', :steem)

      assert_equal '0.000 SBD', Type::Amount.to_s(['0', 3, '@@000000013'], :steem)
      assert_equal '0.000 STEEM', Type::Amount.to_s(['0', 3, '@@000000021'], :steem)
      assert_equal '0.000000 VESTS', Type::Amount.to_s(['0', 6, '@@000000037'], :steem)

      assert_raises TypeError do
        Type::Amount.to_s(['0', 3, '@@00000000'], :steem)
      end
    end

    def test_to_h
      assert_equal({amount: '0', precision: 3, nai: '@@000000013'}, Type::Amount.to_h('0.000 SBD', :steem))
      assert_equal({amount: '0', precision: 3, nai: '@@000000021'}, Type::Amount.to_h('0.000 STEEM', :steem))
      assert_equal({amount: '0', precision: 6, nai: '@@000000037'}, Type::Amount.to_h('0.000000 VESTS', :steem))

      assert_raises TypeError do
        Type::Amount.to_h('0.000 BOGUS', :steem)
      end
    end

    def test_to_bytes
      _amount = Type::Amount.new('0.000 STEEM', :steem)

      assert _amount.to_bytes
    end

    def test_new_00
      _test = Type::Amount.new({:amount => 1000, :precision => 3, :nai => "@@000000021"}, :steem)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000", _test.amount, "test amount  should be “1.000”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("STEEM", _test.asset, "test asset should be  “STEEM”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.000 STEEM", _test.to_s, "string value should be “1.0 STEEM”")
      assert_equal(["1000", 3, "@@000000021"], _test.to_a, "test array should be [“1000”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1000", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test hash should be {:amount=>“1000”, :nai=>“@@000000021”, :precision=>3}]")
    end

    def test_new_01
      _test = Type::Amount.new(["1234", 3, "@@000000021"], :steem)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234", _test.amount, "test amount  should be “1.234”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("STEEM", _test.asset, "test asset should be  “STEEM”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.234 STEEM", _test.to_s, "string value should be “1.234 STEEM”")
      assert_equal(["1234", 3, "@@000000021"], _test.to_a, "test array should be [“1234”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_02
      _test = Type::Amount.new("1234.567 STEEM", :steem)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("STEEM", _test.asset, "test asset should be  “STEEM”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1234.567 STEEM", _test.to_s, "string value should be “1234.567 STEEM”")
      assert_equal(["1234567", 3, "@@000000021"], _test.to_a, "test array should be [“1234567”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_03
      _source = Type::Amount.new("1234.567 STEEM", :steem)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("STEEM", _test.asset, "test asset should be  “STEEM”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1234.567 STEEM", _test.to_s, "string value should be “1234.567 STEEM”")
      assert_equal(["1234567", 3, "@@000000021"], _test.to_a, "test array should be [“1234567”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_04
      _test = Type::Amount.new({:amount => 1000, :precision => 3, :nai => "@@000000021"}, :hive)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000", _test.amount, "test amount  should be “1.000”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HIVE", _test.asset, "test asset should be  “HIVE”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.000 HIVE", _test.to_s, "string value should be “1.0 HIVE”")
      assert_equal(["1000", 3, "@@000000021"], _test.to_a, "test array should be [“1000”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1000", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test hash should be {:amount=>“1000”, :nai=>“@@000000021”, :precision=>3}]")
    end

    def test_new_05
      _test = Type::Amount.new(["1234", 3, "@@000000021"], :hive)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234", _test.amount, "test amount  should be “1.234”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HIVE", _test.asset, "test asset should be  “HIVE”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.234 HIVE", _test.to_s, "string value should be “1.234 HIVE”")
      assert_equal(["1234", 3, "@@000000021"], _test.to_a, "test array should be [“1234”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_06
      _test = Type::Amount.new("1234.567 HIVE", :hive)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HIVE", _test.asset, "test asset should be  “HIVE”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1234.567 HIVE", _test.to_s, "string value should be “1234.567 HIVE”")
      assert_equal(["1234567", 3, "@@000000021"], _test.to_a, "test array should be [“1234567”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_07
      _source = Type::Amount.new("1234.567 HIVE", :hive)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HIVE", _test.asset, "test asset should be  “HIVE”")
      assert_equal("@@000000021", _test.nai, "test nai should be “@@000000021”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1234.567 HIVE", _test.to_s, "string value should be “1234.567 HIVE”")
      assert_equal(["1234567", 3, "@@000000021"], _test.to_a, "test array should be [“1234567”, 3, “@@000000021”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000021", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000021”, :precision =>  3}")
    end

    def test_new_10
      _test = Type::Amount.new({:amount => 1000, :precision => 3, :nai => "@@000000013"}, :steem)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000", _test.amount, "test amount  should be “1.000”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("SBD", _test.asset, "test asset should be  “SBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.000 SBD", _test.to_s, "string value should be “1.0 SBD”")
      assert_equal(["1000", 3, "@@000000013"], _test.to_a, "test array should be [“1000”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1000", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1000”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_11
      _test = Type::Amount.new([1234, 3, "@@000000013"], :steem)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234", _test.amount, "test amount  should be “1.234”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("SBD", _test.asset, "test asset should be  “SBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.234 SBD", _test.to_s, "string value should be “1.234 SBD”")
      assert_equal(["1234", 3, "@@000000013"], _test.to_a, "test array should be [“1234”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_12
      _test = Type::Amount.new("1234.567 SBD", :steem)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("SBD", _test.asset, "test asset should be  “SBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1234.567 SBD", _test.to_s, "string value should be “1234.567 SBD”")
      assert_equal(["1234567", 3, "@@000000013"], _test.to_a, "test array should be [“1234567”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_13
      _source = Type::Amount.new("1234.567 SBD", :steem)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("SBD", _test.asset, "test asset should be  “SBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1234.567 SBD", _test.to_s, "string value should be “1234.567 SBD”")
      assert_equal(["1234567", 3, "@@000000013"], _test.to_a, "test array should be [“1234567”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_14
      _test = Type::Amount.new({:amount => 1000, :precision => 3, :nai => "@@000000013"}, :hive)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000", _test.amount, "test amount  should be “1.000”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HBD", _test.asset, "test asset should be  “HBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.000 HBD", _test.to_s, "string value should be “1.0 HBD”")
      assert_equal(["1000", 3, "@@000000013"], _test.to_a, "test array should be [“1000”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1000", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1000”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_15
      _test = Type::Amount.new([1234, 3, "@@000000013"], :hive)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234", _test.amount, "test amount  should be “1.234”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HBD", _test.asset, "test asset should be  “HBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.234 HBD", _test.to_s, "string value should be “1.234 HBD”")
      assert_equal(["1234", 3, "@@000000013"], _test.to_a, "test array should be [“1234”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_16
      _test = Type::Amount.new("1234.567 HBD", :hive)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HBD", _test.asset, "test asset should be  “HBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1234.567 HBD", _test.to_s, "string value should be “1234.567 HBD”")
      assert_equal(["1234567", 3, "@@000000013"], _test.to_a, "test array should be [“1234567”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_17
      _source = Type::Amount.new("1234.567 HBD", :hive)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(1234.567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1234.567", _test.amount, "test amount  should be “1234.567”")
      assert_equal(3, _test.precision, "test precision should be 3'")
      assert_equal("HBD", _test.asset, "test asset should be  “HBD”")
      assert_equal("@@000000013", _test.nai, "test nai should be “@@000000013”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1234.567 HBD", _test.to_s, "string value should be “1234.567 HBD”")
      assert_equal(["1234567", 3, "@@000000013"], _test.to_a, "test array should be [“1234567”, 3, “@@000000013”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000013", :precision => 3},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000013”, :precision =>  3}")
    end

    def test_new_20
      _test = Type::Amount.new({:amount => 1000000, :precision => 6, :nai => "@@000000037"}, :steem)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000000", _test.amount, "test amount  should be “1.000000”")
      assert_equal(6, _test.precision, "test precision should be 3'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.000000 VESTS", _test.to_s, "string value should be “1.0 VESTS”")
      assert_equal(["1000000", 6, "@@000000037"], _test.to_a, "test array should be [“1000000”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1000000", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1000000”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_21
      _test = Type::Amount.new([1234000, 6, "@@000000037"], :steem)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234000", _test.amount, "test amount  should be “1.234000”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.234000 VESTS", _test.to_s, "string value should be “1.234000 VESTS”")
      assert_equal(["1234000", 6, "@@000000037"], _test.to_a, "test array should be [“1234000”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1234000", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1234000”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_22
      _test = Type::Amount.new("1.234567 VESTS", :steem)

      assert_equal(1.234567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1.234567", _test.amount, "test amount  should be “1.234567”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("1.234567 VESTS", _test.to_s, "string value should be “1.234567 VESTS”")
      assert_equal(["1234567", 6, "@@000000037"], _test.to_a, "test array should be [“1234567”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_23
      _source = Type::Amount.new("123.4567 VESTS", :steem)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(123.4567, _test.to_f, "float value  should be 123.4456")
      assert_equal("123.4567", _test.amount, "test amount  should be “123.4567”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:steem, _test.chain, "test chain should be :steem")
      assert_equal("123.456700 VESTS", _test.to_s, "string value should be “123.4567 VESTS”")
      assert_equal(["123456700", 6, "@@000000037"], _test.to_a, "test array should be [“123456700”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "123456700", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “123456700”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_24
      _test = Type::Amount.new({:amount => 1000000, :precision => 6, :nai => "@@000000037"}, :hive)

      assert_equal(1.0, _test.to_f, "float value  should be 1.0")
      assert_equal("1.000000", _test.amount, "test amount  should be “1.000000”")
      assert_equal(6, _test.precision, "test precision should be 3'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.000000 VESTS", _test.to_s, "string value should be “1.0 VESTS”")
      assert_equal(["1000000", 6, "@@000000037"], _test.to_a, "test array should be [“1000000”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1000000", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1000000”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_25
      _test = Type::Amount.new([1234000, 6, "@@000000037"], :hive)

      assert_equal(1.234, _test.to_f, "float value  should be 1.234")
      assert_equal("1.234000", _test.amount, "test amount  should be “1.234000”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.234000 VESTS", _test.to_s, "string value should be “1.234000 VESTS”")
      assert_equal(["1234000", 6, "@@000000037"], _test.to_a, "test array should be [“1234000”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1234000", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1234000”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_26
      _test = Type::Amount.new("1.234567 VESTS", :hive)

      assert_equal(1.234567, _test.to_f, "float value  should be 1.234456")
      assert_equal("1.234567", _test.amount, "test amount  should be “1.234567”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("1.234567 VESTS", _test.to_s, "string value should be “1.234567 VESTS”")
      assert_equal(["1234567", 6, "@@000000037"], _test.to_a, "test array should be [“1234567”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "1234567", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “1234567”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_new_27
      _source = Type::Amount.new("123.4567 VESTS", :hive)
      _test   = Type::Amount.new(_source, _source.chain)

      assert_equal(123.4567, _test.to_f, "float value  should be 123.4456")
      assert_equal("123.4567", _test.amount, "test amount  should be “123.4567”")
      assert_equal(6, _test.precision, "test precision should be 6'")
      assert_equal("VESTS", _test.asset, "test asset should be  “VESTS”")
      assert_equal("@@000000037", _test.nai, "test nai should be “@@000000037”")
      assert_equal(:hive, _test.chain, "test chain should be :hive")
      assert_equal("123.456700 VESTS", _test.to_s, "string value should be “123.4567 VESTS”")
      assert_equal(["123456700", 6, "@@000000037"], _test.to_a, "test array should be [“123456700”, 6, “@@000000037”]")
      assert_equal(
         {:amount => "123456700", :nai => "@@000000037", :precision => 6},
         _test.to_h,
         "test array should be {:amount => “123456700”, :nai =>  “@@000000037”, :precision =>  6}")
    end

    def test_add_00
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 STEEM', :steem)
      _test   = _value1 + _value2

      assert_equal("5.000 STEEM", _test.to_s, "string value should be “5.000 STEEM”")
    end

    def test_add_01
      _value1 = Type::Amount.new('7.000 SBD', :steem)
      _value2 = Type::Amount.new('5.000 SBD', :steem)
      _test   = _value1 + _value2

      assert_equal("12.000 SBD", _test.to_s, "string value should be “12.000 SDB”")
    end

    def test_add_02
      _value1 = Type::Amount.new('47.000 VESTS', :steem)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)
      _test   = _value1 + _value2

      assert_equal("50.000000 VESTS", _test.to_s, "string value should be “50.000 VESTS”")
    end

    def test_add_03
      _value1 = Type::Amount.new('3.000 HIVE', :hive)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)
      _test   = _value1 + _value2

      assert_equal("5.000 HIVE", _test.to_s, "string value should be “5.000 HIVE”")
    end

    def test_add_04
      _value1 = Type::Amount.new('7.000 HBD', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)
      _test   = _value1 + _value2

      assert_equal("12.000 HBD", _test.to_s, "string value should be “12.000 HBD”")
    end

    def test_add_05
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :hive)
      _test   = _value1 + _value2

      assert_equal("50.000000 VESTS", _test.to_s, "string value should be “50.000 VESTS”")
    end

    def test_add_06
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)

      assert_raises ArgumentError do
        _test   = _value1 + _value2
      end
    end

    def test_add_07
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 + _value2
      end
    end

    def test_add_08
      _value1 = Type::Amount.new('7.000 STEEM', :steem)
      _value2 = Type::Amount.new('5.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 + _value2
      end
    end

    def test_add_09
      _value1 = Type::Amount.new('7.000 HIVE', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)

      assert_raises ArgumentError do
        _test   = _value1 + _value2
      end
    end
    def test_subtract_00
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 STEEM', :steem)
      _test   = _value1 - _value2

      assert_equal("1.000 STEEM", _test.to_s, "string value should be “1.000 STEEM”")
    end

    def test_subtract_01
      _value1 = Type::Amount.new('7.000 SBD', :steem)
      _value2 = Type::Amount.new('5.000 SBD', :steem)
      _test   = _value1 - _value2

      assert_equal("2.000 SBD", _test.to_s, "string value should be “2.000 SDB”")
    end

    def test_subtract_02
      _value1 = Type::Amount.new('47.000 VESTS', :steem)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)
      _test   = _value1 - _value2

      assert_equal("44.000000 VESTS", _test.to_s, "string value should be “44.000 VESTS”")
    end

    def test_subtract_03
      _value1 = Type::Amount.new('3.000 HIVE', :hive)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)
      _test   = _value1 - _value2

      assert_equal("1.000 HIVE", _test.to_s, "string value should be “1.000 HIVE”")
    end

    def test_subtract_04
      _value1 = Type::Amount.new('7.000 HBD', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)
      _test   = _value1 - _value2

      assert_equal("2.000 HBD", _test.to_s, "string value should be “2.000 HBD”")
    end

    def test_subtract_05
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :hive)
      _test   = _value1 - _value2

      assert_equal("44.000000 VESTS", _test.to_s, "string value should be “44.000 VESTS”")
    end

    def test_subtract_06
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)

      assert_raises ArgumentError do
        _test   = _value1 - _value2
      end
    end

    def test_subtract_07
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 - _value2
      end
    end

    def test_subtract_08
      _value1 = Type::Amount.new('7.000 STEEM', :steem)
      _value2 = Type::Amount.new('5.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 - _value2
      end
    end

    def test_subtract_09
      _value1 = Type::Amount.new('7.000 HIVE', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)

      assert_raises ArgumentError do
        _test   = _value1 - _value2
      end
    end

    def test_multiply_00
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 STEEM', :steem)
      _test   = _value1 * _value2

      assert_equal("6.000 STEEM", _test.to_s, "string value should be “6.000 STEEM”")
    end

    def test_multiply_01
      _value1 = Type::Amount.new('7.000 SBD', :steem)
      _value2 = Type::Amount.new('5.000 SBD', :steem)
      _test   = _value1 * _value2

      assert_equal("35.000 SBD", _test.to_s, "string value should be “35.000 SDB”")
    end

    def test_multiply_02
      _value1 = Type::Amount.new('47.000 VESTS', :steem)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)
      _test   = _value1 * _value2

      assert_equal("141.000000 VESTS", _test.to_s, "string value should be “141.000 VESTS”")
    end

    def test_multiply_03
      _value1 = Type::Amount.new('3.000 HIVE', :hive)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)
      _test   = _value1 * _value2

      assert_equal("6.000 HIVE", _test.to_s, "string value should be “6.000 HIVE”")
    end

    def test_multiply_04
      _value1 = Type::Amount.new('7.000 HBD', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)
      _test   = _value1 * _value2

      assert_equal("35.000 HBD", _test.to_s, "string value should be “35.000 HBD”")
    end

    def test_multiply_05
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :hive)
      _test   = _value1 * _value2

      assert_equal("141.000000 VESTS", _test.to_s, "string value should be “141.000 VESTS”")
    end

    def test_multiply_06
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)

      assert_raises ArgumentError do
        _test   = _value1 * _value2
      end
    end

    def test_multiply_07
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 * _value2
      end
    end

    def test_multiply_08
      _value1 = Type::Amount.new('7.000 STEEM', :steem)
      _value2 = Type::Amount.new('5.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 * _value2
      end
    end

    def test_multiply_09
      _value1 = Type::Amount.new('7.000 HIVE', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)

      assert_raises ArgumentError do
        _test   = _value1 * _value2
      end
    end

    def test_divide_00
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 STEEM', :steem)
      _test   = _value1 / _value2

      assert_equal("1.500 STEEM", _test.to_s, "string value should be “1.500 STEEM”")
    end

    def test_divide_01
      _value1 = Type::Amount.new('7.000 SBD', :steem)
      _value2 = Type::Amount.new('5.000 SBD', :steem)
      _test   = _value1 / _value2

      assert_equal("1.400 SBD", _test.to_s, "string value should be “1.400 SDB”")
    end

    def test_divide_02
      _value1 = Type::Amount.new('47.000 VESTS', :steem)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)
      _test   = _value1 / _value2

      assert_equal("15.666667 VESTS", _test.to_s, "string value should be “15.666667 VESTS”")
    end

    def test_divide_03
      _value1 = Type::Amount.new('3.000 HIVE', :hive)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)
      _test   = _value1 / _value2

      assert_equal("1.500 HIVE", _test.to_s, "string value should be “1.500”")
    end

    def test_divide_04
      _value1 = Type::Amount.new('7.000 HBD', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)
      _test   = _value1 / _value2

      assert_equal("1.400 HBD", _test.to_s, "string value should be “1.400 HBD”")
    end

    def test_divide_05
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :hive)
      _test   = _value1 / _value2

      assert_equal("15.666667 VESTS", _test.to_s, "string value should be “15.666667 VESTS”")
    end

    def test_divide_06
      _value1 = Type::Amount.new('3.000 STEEM', :steem)
      _value2 = Type::Amount.new('2.000 HIVE', :hive)

      assert_raises ArgumentError do
        _test   = _value1 / _value2
      end
    end

    def test_divide_07
      _value1 = Type::Amount.new('47.000 VESTS', :hive)
      _value2 = Type::Amount.new('3.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 / _value2
      end
    end

    def test_divide_08
      _value1 = Type::Amount.new('7.000 STEEM', :steem)
      _value2 = Type::Amount.new('5.000 VESTS', :steem)

      assert_raises ArgumentError do
        _test   = _value1 / _value2
      end
    end

    def test_divide_09
      _value1 = Type::Amount.new('7.000 HIVE', :hive)
      _value2 = Type::Amount.new('5.000 HBD', :hive)

      assert_raises ArgumentError do
        _test   = _value1 / _value2
      end
    end
  end
end
