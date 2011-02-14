require 'jqgrid_rails/jqgrid_rails_view'
require 'jqgrid_rails/jqgrid_rails_generators'

# Load everything into rails
if(defined? Rails)
  ActionView::Base.send :include, JqGridView
  ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridGenerators
end
