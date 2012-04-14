require 'jqgrid_rails/jqgrid_rails_structure'

module JqGridRails
  # JqGridStructureRegistry is a module that, once included, adds some class methods to enable
  # registering and fetching of grid structures by the grid's name
  # see examples/usage.rb file for more details
  module JqGridStructureRegistry

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Creates a new GridStructure object and stores it in a slot with grid_name as key 
      # grid_name:: grid name symbol (first arg of JqGrid.new(...))
      def register_grid(grid_name)
        @grids ||= {}
        @grids[grid_name.to_sym] = JqGridRails::JqGridStructure.new(self, grid_name)
      end

      # Fetches grid from grid_name symbol
      def get_grid(grid_name)
        @grids[grid_name.to_sym]
      end
    end
    
  end
end
