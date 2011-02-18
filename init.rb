require 'jqgrid_rails/jqgrid_rails_view'
require 'jqgrid_rails/jqgrid_rails_controller'
require 'jqgrid_rails/jqgrid_rails_generators'

#Load everything into rails
if(defined? Rails)
  ActionView::Base.send :include, JqGridRails::View
  ActionController::Base.send :include, JqGridRails::Controller
  ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods.send :include, JqGridRails::Generators
end
