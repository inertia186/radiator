# Steem chain client for broadcasting common operations.
# 
# @see Radiator::Chain
class Steem < Radiator::Chain
  def initialize(options = {})
    super(options.merge(chain: :steem))
  end
end
