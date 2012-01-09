module JqGridRails
  module Generators

    # grid:: JqGridRails::JqGrid instance
    # Outputs javascript to build grid
    def jq_grid(grid)
      self << grid.build
    end
    alias_method :jqgrid, :jq_grid

    # dom_id:: DOM ID of grid
    # Instructs grid to reload itself
    def reload_grid(dom_id)
      dom_id = "##{dom_id}" unless dom_id.start_with?('#')
      self << "jQuery('#{dom_id}').trigger('reloadGrid');"
    end

  end 
end

if(defined?(ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods))
  ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridRails::Generators
end
