# Golos chain client for broadcasting common operations.
# 
# @see Radiator::Chain
class Golos < Radiator::Chain
  def initialize(options = {})
    super(options.merge(chain: :golos))
  end
end
