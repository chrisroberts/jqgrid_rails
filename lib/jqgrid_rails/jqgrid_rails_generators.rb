module JqGridRails
  module Generators

    def jqgrid(grid)
      self << grid.build
    end

    def reload_grid(dom_id)
      dom_id = "##{dom_id}" unless dom_id.start_with?('#')
      self << "jQuery('#{dom_id}').trigger('reloadGrid');"
    end

  end 
end

ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridRails::Generators
