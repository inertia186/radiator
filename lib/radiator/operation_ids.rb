module Radiator
  module OperationIds
    # These IDS are derrived from:
    # https://github.com/steemit/steem/blob/127a441fbac2f06804359968bda83b66e602c891/libraries/protocol/include/steem/protocol/operations.hpp
    
    IDS = [
      :vote_operation,
      :comment_operation,
      
      :transfer_operation,
      :transfer_to_vesting_operation,
      :withdraw_vesting_operation,
      
      :limit_order_create_operation,
      :limit_order_cancel_operation,
      
      :feed_publish_operation,
      :convert_operation,
      
      :account_create_operation,
      :account_update_operation,
      
      :witness_update_operation,
      :account_witness_vote_operation,
      :account_witness_proxy_operation,
      
      :pow_operation,
      
      :custom_operation,
      
      :report_over_production_operation,
      
      :delete_comment_operation,
      :custom_json_operation,
      :comment_options_operation,
      :set_withdraw_vesting_route_operation,
      :limit_order_create2_operation,
      :claim_account_operation,
      :create_claimed_account_operation,
      :request_account_recovery_operation,
      :recover_account_operation,
      :change_recovery_account_operation,
      :escrow_transfer_operation,
      :escrow_dispute_operation,
      :escrow_release_operation,
      :pow2_operation,
      :escrow_approve_operation,
      :transfer_to_savings_operation,
      :transfer_from_savings_operation,
      :cancel_transfer_from_savings_operation,
      :custom_binary_operation,
      :decline_voting_rights_operation,
      :reset_account_operation,
      :set_reset_account_operation,
      :claim_reward_balance_operation,
      :delegate_vesting_shares_operation,
      :account_create_with_delegation_operation,
      :witness_set_properties_operation,
      
      # SMT operations
      :claim_reward_balance2_operation,
      
      :smt_setup_operation,
      :smt_cap_reveal_operation,
      :smt_refund_operation,
      :smt_setup_emissions_operation,
      :smt_set_setup_parameters_operation,
      :smt_set_runtime_parameters_operation,
      :smt_create_operation,
      
      # virtual operations below this point
      :fill_convert_request_operation,
      :author_reward_operation,
      :curation_reward_operation,
      :comment_reward_operation,
      :liquidity_reward_operation,
      :interest_operation,
      :fill_vesting_withdraw_operation,
      :fill_order_operation,
      :shutdown_witness_operation,
      :fill_transfer_from_savings_operation,
      :hardfork_operation,
      :comment_payout_update_operation,
      :return_vesting_delegation_operation,
      :comment_benefactor_reward_operation,
      :producer_reward_operation,
      :clear_null_account_balance_operation
    ]
    
    def id(op)
      if op.to_s =~ /_operation$/
        IDS.find_index op
      else
        IDS.find_index "#{op}_operation".to_sym
      end
    end
  end
end
