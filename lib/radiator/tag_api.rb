module Radiator
  class TagApi < Api
    def method_names
      @method_names ||= [:get_tags].freeze
    end
    
    def api_name
      :tag_api
    end
  end
end