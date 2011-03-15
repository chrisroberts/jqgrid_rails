module JqGridRails
  module Generators

    def jqgrid(grid)
      self << grid.build
    end

  end 
end

ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridRails::Generators
