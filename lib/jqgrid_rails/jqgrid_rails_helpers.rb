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
          options[key] = "function(id){ jQuery.ajax('#{@url_gen.send(options[key][:url], *args)}'.replace('#{id_replacement}', id) + '#{options[key][:suffix]}', #{format_type_to_js(ajax_args)}); }"
        else
          options[key] = "function(id){
            jQuery('body').append('<form id=\"redirector\" action=\"#{@url_gen.send(options[key][:url], *args)}\" method=\"#{ajax_args[:type].upcase}\"></form>'.replace('#{id_replacement}', id));
            jQuery('#redirector').submit();
          }"
        end
      end
    end

    def build_toolbar_button(url_hash)
      id_replacement = '000'
      url_hash[:empty_selection] ||= !url_hash[:single]
      url_hash[:method] = url_hash[:method].to_s if url_hash[:method]
      ajax_args = url_hash.delete(:ajax) || {}
      ajax_args[:type] ||= url_hash.delete(:method) || 'get'
      ajax_args[:type] = ajax_args[:type].to_s
      classes = ['grid_toolbar_item', 'button']
      if(url_hash[:url].is_a?(Symbol))
        @url_gen ||= JqGridRails::UrlGenerator.new
        args = url_hash[:args].to_a
        args.push(id_replacement) #unless url_hash[:empty_selection]
        url_hash[:url] = @url_gen.send(url_hash[:url], *args)
      end
      s = <<-EOS
jQuery('<div class="#{(classes + url_hash[:class].to_a).compact.join(' ')}" />')
  .text('#{escape_javascript(url_hash[:name])}')
    .click(
      function(){
        var ary = jQuery('##{@table_id}').jqGrid('getGridParam', 'selarrrow');
        if(!ary.length)
          ary = new Array();
        ary.push(jQuery('##{@table_id}').jqGrid('getGridParam', 'selrow'));
        ary = ary.filter(function(elm){ return elm != null && elm.length });
        if(!ary.length && #{format_type_to_js(url_hash[:empty_selection])}){
          alert('Please select items from table first.');
        } else {
          if(!ary.length){
            #{
              if(url_hash[:remote])
                "jQuery.ajax('#{url_hash[:url]}', #{format_type_to_js(ajax_args)});"
              else
                "jQuery('body').append('<form id=\"redirector\" action=\"#{url_hash[:url]}\" method=\"#{(url_hash[:method] || 'get').to_s.upcase}\"></form>'); jQuery('#redirector').submit();"
              end
            }
          }
          else{
            ary_hash = {'ids[]' : ary};
            #{
              if(url_hash[:remote])
                ajax_args[:data] = RawJS.new('ary_hash')
                "jQuery.ajax('#{url_hash[:url]}'.replace('#{id_replacement}', ary[0]), #{format_type_to_js(ajax_args)});"
              else
                "
                  parts = ary.map(
                    function(item){
                      return '<input type=\"hidden\" name=\"ids[]\" value=\"'+item+'\"/>';
                    }
                  );
                  jQuery('body').append('<form id=\"redirector\" action=\"#{url_hash[:url]}\" method=\"#{(url_hash[:method] || 'get').to_s.upcase}\">' + parts + '</form>'.replace('#{id_replacement}', ary[0])); jQuery('#redirector').submit();
                "
              end
            }
          }
        }
      }
    ).appendTo('#t_#{@table_id}');
EOS
    end
  end
end
