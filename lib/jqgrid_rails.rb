require 'jqgrid_rails/version'
require 'jqgrid_rails/escape_mappings'

if(defined?(Rails))
  if(Rails.version.split('.').first == '3')
    require 'jqgrid_rails/railtie'
  else
    Dir.glob(File.join(File.dirname(__FILE__), 'jqgrid_rails', '*.rb')).each do |file|
      unless(%w(railtie.rb tasks.rb version.rb).find{|skip| file.ends_with?(skip)})
        require file
      end
    end
  end
end
