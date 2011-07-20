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
        ajax_args = options.delete(:ajax) || {}
        ajax_args[:type] ||= options.delete(:method) || ajax_args.delete(:method) || 'get'
        ajax_args[:type] = ajax_args[:type].to_s
        @url_gen ||= JqGridRails::UrlGenerator.new
        args = options[key][:args].to_a
        args << id_replacement
        if(options[key][:remote])
          options[key] = "function(id){ jQuery.ajax('#{@url_gen.send(options[key][:url], *args)}'.replace('000', id) + '#{options[key][:suffix]}', #{format_type_to_js(ajax_args)}); }"
        else
          options[key] = "function(id){
            jQuery('body').append('<form id=\"redirector\" action=\"#{@url_gen.send(options[key][:url], *args)}\" method=\"#{ajax_args[:type].upcase}\"></form>'.replace('000', id));
            jQuery('#redirector').submit();
          }"
        end
      end
    end
  end
end
