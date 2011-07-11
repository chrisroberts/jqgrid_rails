require 'rails_javascript_helpers'

module JqGridRails
  module Helpers
    include RailsJavaScriptHelpers

    alias_method :convert_dom_id, :format_id
    
    # key:: ondbl_click_row/on_select_row
    # Sets up click event functions based on hash values
    def map_click(key, options)
      id_replacement = '000'
      if(options[key].is_a?(Hash))
        @url_gen ||= JqGridRails::UrlGenerator.new
        args = options[key][:args].to_a
        args << id_replacement
        if(options[key][:remote])
          options[key] = "function(id){ jQuery.get('#{@url_gen.send(options[key][:url], *args)}'.replace('000', id)) + '#{options[key][:suffix]}'; }"
        else
          options[key] = "function(id){ window.location = '#{@url_gen.send(options[key][:url], *args)}'.replace('000', id) + '#{options[key][:suffix]}'; }"
        end
      end
    end
  end
end
