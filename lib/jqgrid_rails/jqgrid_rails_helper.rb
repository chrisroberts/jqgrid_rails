require 'jqgrid_rails/jqgrid_rails_helpers'

module JqGridRails
  class Helper
    include ActionView::Helpers::JavaScriptHelper
    include JqGridRails::Helpers
    attr_accessor :table_id
    def initialize(dom_id)
      @table_id = dom_id
    end
  end
end
