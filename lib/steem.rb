# Steem chain client for broadcasting common operations.
# 
# @see Radiator::Chain
# @deprecated Using Steem class provided by Radiator is deprecated.  Please use: Radiator::Chain.new(chain: :steem)
class Steem < Radiator::Chain
  def initialize(options = {})
    unless defined? @@deprecated_warning_shown
      warn "[DEPRECATED] Using Steem class provided by Radiator is deprecated.  Please use: Radiator::Chain.new(chain: :steem)"
      @@deprecated_warning_shown = true
    end
    
    super(options.merge(chain: :steem))
  end
  
  alias steem_per_mvest base_per_mvest
  alias steem_per_usd base_per_debt
end
