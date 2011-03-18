module JqGridRails
  class Railtie < Rails::Railtie

    rake_tasks do
      require 'jqgrid_rails/tasks'
    end

    # We do all our setup in here
    config.to_prepare do
      ActionView::Helpers::AssetTagHelper.register_javascript_expansion(
        :plugins => %w(/jqgrid_rails/javascripts/jqgrid/grid.locale-en.js /jqgrid_rails/javascripts/jqgrid/jquery.jqGrid.min.js)
      )
      ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion(
        :plugins => %w(/jqgrid_rails/stylesheets/jqgrid/ui.jqgrid.css)
      )
      Dir.glob(File.join(File.dirname(__FILE__), '*.rb')).each do |file|
        unless(%w(railtie.rb tasks.rb version.rb).find{|skip| file.ends_with?(skip))
          require file
        end
      end
    end
  end
end
