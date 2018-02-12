# Golos chain client for broadcasting common operations.
# 
# @see Radiator::Chain
class Golos < Radiator::Chain
  def initialize(options = {})
    super(options.merge(chain: :golos))
  end
  
  alias golos_per_mgest base_per_mvest
  alias golos_per_gbg base_per_debt
end
