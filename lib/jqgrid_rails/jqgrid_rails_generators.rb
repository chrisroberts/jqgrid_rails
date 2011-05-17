module JqGridRails
  module Generators

    # grid:: JqGridRails::JqGrid instance
    # Outputs javascript to build grid
    def jqgrid(grid)
      self << grid.build
    end

    # dom_id:: DOM ID of grid
    # Instructs grid to reload itself
    def reload_grid(dom_id)
      dom_id = "##{dom_id}" unless dom_id.start_with?('#')
      self << "jQuery('#{dom_id}').trigger('reloadGrid');"
    end

  end 
end

ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridRails::Generators
