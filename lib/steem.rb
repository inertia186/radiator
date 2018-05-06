# Steem chain client for broadcasting common operations.
# 
# @see Radiator::Chain
class Steem < Radiator::Chain
  def initialize(options = {})
    super(options.merge(chain: :steem))
  end
  
  alias steem_per_mvest base_per_mvest
  alias steem_per_usd base_per_debt
end
