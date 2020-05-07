require 'radiator/chain_config'

module Radiator
  module Type

    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount < Serializer

      ##
      # information on a single coins available.
      #
      class Coin_Info
        attr_reader :symbol, :nai, :precision

        def initialize(symbol, nai, precision)
          @symbol    = symbol
          @nai       = nai
          @precision = precision
        end
      end
      private_constant :Coin_Info

      ##
      # information on the coins of a one chain
      #
      class Chain_Info
        attr_reader :core, :debt, :vest

        def initialize(core, debt, vest)
          @core = core
          @debt = debt
          @vest = vest
        end
      end
      private_constant :Chain_Info

      attr_reader :amount, :precision, :nai, :asset, :chain

      def initialize(value, chain)
        case value
        when Amount
          super(:amount, value.to_s)

          @chain     = value.chain
          @amount    = value.amount
          @precision = value.precision
          @nai       = value.nai
          @asset     = value.asset
        when ::Array
          super(:amount, value)

          @chain = chain
          @amount, @precision, @nai = value
          @asset = Amount.nai_to_asset(@nai, @chain)
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when ::Hash
          super(:amount, value)

          @chain = chain
          @amount, @precision, @nai = value.map do |k, v|
            v if %i(amount precision nai).include? k.to_sym
          end.compact
          @asset = Amount.nai_to_asset(@nai, @chain)
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        else
          super(:amount, value)

          @chain = chain
          @amount, @asset = value.strip.split(' ') rescue ['', '']
          @precision = Amount.asset_to_precision(@asset, @chain)
          @nai = Amount.asset_to_nai(@asset, @chain)
        end
      end

      def to_bytes
        asset = @asset.ljust(7, "\x00")
        amount = (@amount.to_f * 10 ** @precision).round

        [amount].pack('q') +
        [@precision].pack('c') +
        asset
      end

      def to_a
        _chain_info = @@chain_infos[chain]

        case @asset
        when _chain_info.core.symbol then [
          (@amount.to_f * 10 ** _chain_info.core.precision).to_i.to_s,
          _chain_info.core.precision,
          _chain_info.core.nai
        ]
        when _chain_info.debt.symbol then [
          (@amount.to_f * 10 ** _chain_info.debt.precision).to_i.to_s,
          _chain_info.debt.precision,
          _chain_info.debt.nai
        ]
        when _chain_info.vest.symbol then [
          (@amount.to_f * 10 ** _chain_info.vest.precision).to_i.to_s,
          _chain_info.vest.precision,
          _chain_info.vest.nai
        ]
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end

      def to_h
        _chain_info = @@chain_infos[chain]

        case @asset
        when _chain_info.core.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.core.precision).to_i.to_s,
          precision: _chain_info.core.precision,
          nai:       _chain_info.core.nai
        }
        when _chain_info.debt.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.debt.precision).to_i.to_s,
          precision: _chain_info.debt.precision,
          nai:       _chain_info.debt.nai
        }
        when _chain_info.vest.symbol then {
          amount:    (@amount.to_f * 10 ** _chain_info.vest.precision).to_i.to_s,
          precision: _chain_info.vest.precision,
          nai:       _chain_info.vest.nai
        }
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end

      def to_s
        return "%.#{@precision}f %s" % [@amount, @asset]
      end

      ##
      # return amount as float to be used for calculations
      #
      # @return [Float]
      #     actual amount as float
      #
      def to_f
        return @amount.to_f
      end

      ##
      # operator to add two balances
      #
      # @param [Amount]
      #     amount to add
      # @return [Amount]
      #     result of addition
      # @raise [ArgumentError]
      #    values of different asset type
      #
      def +(right)
        raise ArgumentError, 'chain types differ' unless @chain == right.chain
        raise ArgumentError, 'asset types differ' unless @asset == right.asset

        return Amount.to_amount(@amount.to_f + right.to_f, @asset, @chain)
      end

      ##
      # operator to subtract two balances
      #
      # @param [Amount]
      #     amount to subtract
      # @return [Amount]
      #     result of subtraction
      # @raise [ArgumentError]
      #    values of different asset type
      #
      def -(right)
        raise ArgumentError, 'chain types differ' unless @chain == right.chain
        raise ArgumentError, 'asset types differ' unless @asset == right.asset

        return Amount.to_amount(@amount.to_f - right.to_f, @asset, @chain)
      end

      ##
      # operator to divert two balances
      #
      # @param [Amount]
      #     amount to divert
      # @return [Amount]
      #     result of division
      # @raise [ArgumentError]
      #    values of different asset type
      #
      def *(right)
        raise ArgumentError, 'chain types differ' unless @chain == right.chain
        raise ArgumentError, 'asset types differ' unless @asset == right.asset

        return Amount.to_amount(@amount.to_f * right.to_f, @asset, @chain)
      end

      ##
      # operator to divert two balances
      #
      # @param [Amount]
      #     amount to divert
      # @return [Amount]
      #     result of division
      # @raise [ArgumentError]
      #    values of different asset type
      #
      def /(right)
        raise ArgumentError, 'chain types differ' unless @chain == right.chain
        raise ArgumentError, 'asset types differ' unless @asset == right.asset

        return Amount.to_amount(@amount.to_f / right.to_f, @asset, @chain)
      end

      class << self
        ##
        # information on all coins of all chain.
        #
        @@chain_infos = {
           steem: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_STEEM_CORE_SYMBOL,
                 nai       = ChainConfig::NETWORKS_STEEM_CORE_ASSET[2],
                 precision = ChainConfig::NETWORKS_STEEM_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_STEEM_DEBT_SYMBOL,
                 nai       = ChainConfig::NETWORKS_STEEM_DEBT_ASSET[2],
                 precision = ChainConfig::NETWORKS_STEEM_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_STEEM_VEST_SYMBOL,
                 nai       = ChainConfig::NETWORKS_STEEM_VEST_ASSET[2],
                 precision = ChainConfig::NETWORKS_STEEM_VEST_ASSET[1]
              )
           ),
           test: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_TEST_CORE_SYMBOL,
                 nai       = ChainConfig::NETWORKS_TEST_CORE_ASSET[2],
                 precision = ChainConfig::NETWORKS_TEST_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_TEST_DEBT_SYMBOL,
                 nai       = ChainConfig::NETWORKS_TEST_DEBT_ASSET[2],
                 precision = ChainConfig::NETWORKS_TEST_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_TEST_VEST_SYMBOL,
                 nai       = ChainConfig::NETWORKS_TEST_VEST_ASSET[2],
                 precision = ChainConfig::NETWORKS_TEST_VEST_ASSET[1]
              )
           ),
           hive: Chain_Info.new(
              core = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_HIVE_CORE_SYMBOL,
                 nai       = ChainConfig::NETWORKS_HIVE_CORE_ASSET[2],
                 precision = ChainConfig::NETWORKS_HIVE_CORE_ASSET[1]
              ),
              debt = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_HIVE_DEBT_SYMBOL,
                 nai       = ChainConfig::NETWORKS_HIVE_DEBT_ASSET[2],
                 precision = ChainConfig::NETWORKS_HIVE_DEBT_ASSET[1]
              ),
              vest = Coin_Info.new(
                 symbol    = ChainConfig::NETWORKS_HIVE_VEST_SYMBOL,
                 nai       = ChainConfig::NETWORKS_HIVE_VEST_ASSET[2],
                 precision = ChainConfig::NETWORKS_HIVE_VEST_ASSET[1]
              )
           )
        }

        ##
        # Helper factory method to create a new Amount from
        # an value and asset type.
        #
        # @param [Float] value
        #     the numeric value to create an amount from
        # @param [String] asset
        #     the asset type which should be STEEM, SBD or VESTS
        # @return [Amount]
        #     the value as amount
        def to_amount(value, asset, chain)
          return Amount.new(value.to_s + " " + asset, chain)
        end

        def to_h(amount, chain)
          return new(amount, chain).to_h
        end

        def to_s(amount, chain)
          return new(amount, chain).to_s
        end

        def to_bytes(amount, chain)
          return new(amount, chain).to_bytes
        end

        def asset_to_nai(asset, chain)
          _chain_info = @@chain_infos[chain]

          return case asset
                   when _chain_info.core.symbol then
                     _chain_info.core.nai
                   when _chain_info.debt.symbol then
                     _chain_info.debt.nai
                   when _chain_info.vest.symbol then
                     _chain_info.vest.nai
                   else
                     raise TypeError, "Asset #{@asset} unknown."
                 end
        end

        def asset_to_precision(asset, chain)
          _chain_info = @@chain_infos[chain]

          return case asset
                   when _chain_info.core.symbol then
                     _chain_info.core.precision
                   when _chain_info.debt.symbol then
                     _chain_info.debt.precision
                   when _chain_info.vest.symbol then
                     _chain_info.vest.precision
                   else
                     raise TypeError, "Asset «#{@asset}» unknown."
                 end
        end

        def nai_to_asset(nai, chain)
          _chain_info = @@chain_infos[chain]

          return case nai
                   when _chain_info.core.nai then
                     _chain_info.core.symbol
                   when _chain_info.debt.nai then
                     _chain_info.debt.symbol
                   when _chain_info.vest.nai then
                     _chain_info.vest.symbol
                   else
                     raise TypeError, "NAI «#{@nai}» unknown."
                 end
	end

        ##
        # get zero core amount for chain
        #
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [Amount]
        #     :steem "0.0 STEEM"
        #     :hive  "0.0 HIVE"
        #
        def core_zero(chain)
          _chain_info = @@chain_infos[chain]

          return Amount.new([0.0, _chain_info.core.precision, _chain_info.core.nai], chain)
        end
        ##
        # get zero dept amount for chain
        #
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [Amount]
        #   :steem "0.0 SBD"
        #   :hive  "0.0 HBD"
        #
        def debt_zero(chain)
          _chain_info = @@chain_infos[chain]

          return Amount.new([0.0, _chain_info.debt.precision, _chain_info.debt.nai], chain)
        end

        ##
        # get zero vest amount for chain
        # core symbol for chain
        #
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [Amount]
        #   :steem "0.0 VESTS"
        #   :hive  "0.0 VESTS"
        #
        def vest_zero(chain)
          _chain_info = @@chain_infos[chain]

          return Amount.new([0.0, _chain_info.vest.precision, _chain_info.vest.nai], chain)
        end

        ##
        # core symbol for chain
	#
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [String]
        #     :steem "STEEM"
        #     :hive  "HIVE"
        #
        def core_asset(chain)
          _chain_info = @@chain_infos[chain]

          return _chain_info.core.symbol
	end

        ##
        # debt symbol for chain
        #
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [String]
        #   :steem "SBD"
        #   :hive  "HBD"
        #
        def debt_asset(chain)
          _chain_info = @@chain_infos[chain]

          return _chain_info.debt.symbol
	end

        ##
        # core symbol for chain
        #
        # @param [Symbol] chain
        #     The chain for which we want to know the asset
        # @return [String]
        #   :steem "VESTS"
        #   :hive  "VESTS"
        #
        def vest_asset(chain)
          _chain_info = @@chain_infos[chain]

          return _chain_info.vest.symbol
        end
      end
    end
  end
end
