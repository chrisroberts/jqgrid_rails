require 'jqgrid_rails/helpers'

module JqGridRails
  class Helper
    include JqGridRails::Helpers
    attr_accessor :table_id
    def initialize(dom_id)
      @table_id = dom_id
    end
  end
end
