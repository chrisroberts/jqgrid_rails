require 'jqgrid_rails/version'
require 'jqgrid_rails/escape_mappings'

if(defined?(Rails))
  if(Rails.version.split('.').first == '3')
    require 'jqgrid_rails/railtie'
  else
    ActionView::Helpers::AssetTagHelper.register_javascript_expansion(
      :jqgrid_rails => %w(/jqgrid_rails/javascripts/jqgrid/grid.locale-en.js /jqgrid_rails/javascripts/jqgrid/jquery.jqGrid.min.js)
    )
    ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion(
      :jqgrid_rails => %w(/jqgrid_rails/stylesheets/jqgrid/ui.jqgrid.css)
    )
    Dir.glob(File.join(File.dirname(__FILE__), 'jqgrid_rails', '*.rb')).each do |file|
      unless(%w(railtie.rb tasks.rb version.rb).find{|skip| file.ends_with?(skip)})
        require file
      end
    end
  end
end
