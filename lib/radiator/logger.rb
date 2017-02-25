require 'logger'

module Radiator
  # The logger that Radiator uses for reporting errors.
  #
  # @return [Logger]
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  # Sets the logger that Radiator uses for reporting errors.
  #
  # @param logger [Logger] The logger to set as Radiator's logger.
  # @return [void]
  def self.logger=(logger)
    @logger = logger
  end
end
