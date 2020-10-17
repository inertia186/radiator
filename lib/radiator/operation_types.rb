module Radiator
  
  # See: https://github.com/steemit/steem-js/blob/766746adb5ded86380be982c844f4c269f7800ae/src/auth/serializer/src/operations.js
  module OperationTypes
    TYPES = {
      transfer: {
        amount: Hive::Type::Amount
      },
      transfer_to_vesting: {
        amount: Hive::Type::Amount
      },
      withdraw_vesting: {
        vesting_shares: Hive::Type::Amount
      },
      limit_order_create: {
        orderid: Type::Uint32,
        amount_to_sell: Hive::Type::Amount,
        min_to_receive: Hive::Type::Amount,
        expiration: Type::PointInTime
      },
      limit_order_cancel: {
        orderid: Type::Uint32
      },
      feed_publish: {
        exchange_rate: Type::Price
      },
      convert: {
        requestid: Type::Uint32,
        amount: Hive::Type::Amount
      },
      account_create: {
        fee: Hive::Type::Amount,
        owner: Type::Permission,
        active: Type::Permission,
        posting: Type::Permission,
        memo: Type::PublicKey
      },
      create_claimed_account: {
        owner: Type::Permission,
        active: Type::Permission,
        posting: Type::Permission,
        memo: Type::PublicKey
      },
      account_update: {
        owner: Type::Permission,
        active: Type::Permission,
        posting: Type::Permission,
        memo: Type::PublicKey
      },
      custom: {
        id: Type::Uint16
      },
      comment_options: {
        max_accepted_payout: Hive::Type::Amount,
        allow_replies: Type::Future
      },
      set_withdraw_vesting_route: {
        percent: Type::Uint16
      },
      limit_order_create2: {
        orderid: Type::Uint32,
        amount_to_sell: Hive::Type::Amount,
        exchange_rate: Type::Price,
        expiration: Type::PointInTime
      },
      request_account_recovery: {
        new_owner_Permission: Type::Permission
      },
      recover_account: {
        new_owner_Permission: Type::Permission,
        recent_owner_Permission: Type::Permission
      },
      escrow_transfer: {
        sbd_amount: Steem::Type::Amount,
        hbd_amount: Hive::Type::Amount,
        steem_amount: Steem::Type::Amount,
        hive_amount: Hive::Type::Amount,
        escrow_id: Type::Uint32,
        fee: Hive::Type::Amount,
        ratification_deadline: Type::PointInTime,
        escrow_expiration: Type::PointInTime
      },
      escrow_dispute: {
        escrow_id: Type::Uint32
      },
      escrow_release: {
        escrow_id: Type::Uint32,
        sbd_amount: Steem::Type::Amount,
        hbd_amount: Hive::Type::Amount,
        steem_amount: Steem::Type::Amount,
        hive_amount: Hive::Type::Amount
      },
      escrow_approve: {
        escrow_id: Type::Uint32
      },
      transfer_to_savings: {
        amount: Hive::Type::Amount
      },
      transfer_from_savings: {
        request_id: Type::Uint32,
        amount: Hive::Type::Amount
      },
      cancel_transfer_from_savings: {
        request_id: Type::Uint32
      },
      reset_account: {
        new_owner_permission: Hive::Type::Amount
      },
      set_reset_account: {
        reward_steem: Steem::Type::Amount,
        reward_hive: Hive::Type::Amount,
        reward_sbd: Steem::Type::Amount,
        reward_hbd: Hive::Type::Amount,
        reward_vests: Hive::Type::Amount
      },
      claim_reward_balance: {
        reward_steem: Steem::Type::Amount,
        reward_hive: Hive::Type::Amount,
        reward_sbd: Steem::Type::Amount,
        reward_hbd: Hive::Type::Amount,
        reward_vests: Hive::Type::Amount
      },
      delegate_vesting_shares: {
        vesting_shares: Hive::Type::Amount
      },
      claim_account: {
        fee: Hive::Type::Amount
      },
      witness_update: {
        block_signing_key: Type::PublicKey,
        props: Type::Array
      },
      witness_set_properties: {
        props: Type::Hash
      }
    }
    
    def type(chain, key, param, value)
      return if value.nil?
      
      t = TYPES[key] or return value
      p = t[param] or return value
      
      if p == Hive::Type::Amount
        case chain
        when :steem then Steem::Type::Amount.new(value)
        else
          p.new(value)
        end
      else
        p.new(value)
      end
    end
  end
end
