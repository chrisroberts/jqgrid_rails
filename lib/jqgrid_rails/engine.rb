module JqGridRails
  class Engine < Rails::Engine

    rake_tasks do
      require 'jqgrid_rails/tasks'
    end

    # We do all our setup in here
    config.to_prepare do
      ActionView::Helpers::AssetTagHelper.register_javascript_expansion(
        :plugins => %w(/jqgrid_rails/javascripts/grid.locale-en.js /jqgrid_rails/javascripts/jquery.jqGrid.min.js)
      )
      ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion(
        :plugins => %w(ui.jqgrid.css)
      )
      Dir.glob('*.rb').each do |file|
        unless(file.starts_with?('engine') || file.starts_with?('task'))
          require file
        end
      end
    end
  end
end
