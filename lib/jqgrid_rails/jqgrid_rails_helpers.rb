require 'rails_javascript_helpers'

module JqGridRails
  module Helpers
    include RailsJavaScriptHelpers

    alias_method :convert_dom_id, :format_id

    # hash:: Argument hash for callback generation
    # Generates a javascript callback from a Ruby hash. Important hash keys:
    # :build_callback -> [false|:item|:selection] (false will stop callback from being created and simply return original hash)
    # :url            -> Symbol of route method name or string for actual url
    # :args           -> Arguments to be used when generating URL from :url value
    # :method         -> Request method (defaults to 'get')
    # :ajax_args      -> Arguments for jQuery.ajax options hash
    # :remote         -> [true|false] Request should be made via ajax
    # :id_replacement -> Value used for dynamic ID replacement (generally not to be altered)
    def hash_to_callback(hash)
      if(hash.is_a?(Hash) && hash[:build_callback] != false && hash[:url])
        case hash[:build_callback]
        when :item
          build_single_callback(hash)
        when :selection
          build_collection_callback(hash)
        else
          build_default_callback(hash)
        end
      else
        hash
      end
    end

    # hash:: Argument hash
    # Extracts and formats argument hash for callbacks
    def extract_callback_variables(hash)
      @url_gen ||= JqGridRails::UrlGenerator.new
      args = hash.dup
      args[:ajax_args] = hash.delete(:ajax) || {}
      args[:method] = args[:ajax_args][:type] || args[:ajax_args].delete(:method) || hash.delete(:method) || 'get'
      if(hash[:url].is_a?(Symbol))
        args[:url] = @url_gen.send(hash[:url], *hash[:args].to_a)
      else
        args[:url] = hash[:url]
      end
      args[:ajax_args][:type] = args[:method] if hash[:remote]
      args
    end

    # hash:: Argument hash
    # Builds callback function for single selection
    def build_single_callback(hash)
      hash[:id_replacement] ||= '000'
      hash[:args] ||= []
      hash[:args].push hash[:id_replacement]
      args = extract_callback_variables(hash)
      if(hash[:remote])
        " function(id){
            jQuery.ajax(#{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, id), #{format_type_to_js(args[:ajax_args])});
          }
        "
      else
        form_rand = rand(999)
        " function(id){
            jQuery('body').append('<form id=\"redirector_#{form_rand}\" action=\"#{args[:url]}\" method=\"#{args[:method]}\"></form>'.replace(#{format_type_to_js(args[:id_replacement])}, id));
            jQuery('#redirector_#{form_rand}').submit();
          }
        "
      end
    end

    # Returns callable function to get current selection in array form
    def selection_array(error_when_empty=true, table_id=nil)
      dom_id = table_id || @table_id
      " function(){ 
          ary = jQuery(#{format_type_to_js(format_id(dom_id))}).jqGrid('getGridParam', 'selarrrow');
          if(!ary.length){ ary = []; }
          ary.push(jQuery(#{format_type_to_js(format_id(dom_id))}).jqGrid('getGridParam', 'selrow'));
          ary = jQuery.grep(ary, function(value,key){ return value != null && value.length && jQuery.inArray(value, ary) === key; });
          if(!ary.length && #{format_type_to_js(error_when_empty)}){
            alert('Please select items from the table first.');
          }
          return ary;
        }
      "
    end

    # hash:: Argument has
    # Builds callback function for full selection
    # NOTE: In general you will want the URL to be auto generated within jqgrid_rails. The route
    # should accept an ID which will be the first ID of the current selection. An extra parameter named
    # 'ids' will be provided which will be an array of all selected values, included the ID given
    # to the route
    def build_selection_callback(hash, table_id=nil)
      dom_id = table_id || @table_id
      hash[:id_replacement] ||= '000'
      args = extract_callback_variables(hash)
      function = "function(){ 
        rows_func = #{selection_array(true, table_id)} 
        ary = rows_func();
        if(!ary.length){ return false; }
      "
      if(hash[:remote])
        args[:ajax_args][:data] = {:ids => RawJS.new('ary')}
        function << "jQuery.ajax(#{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, ary[0]), #{format_type_to_js(args[:ajax_args])});"
      else
        randomizer = rand(99999)
        function << "parts = ary.map(
          function(item){
            return '<input type=\"hidden\" name=\"ids[]\" value=\"'+item+'\"/>';
          });
          target_url = #{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, ary[0]);
          jQuery('body').append('<form id=\"jqgrid_redirector_#{randomizer}\" action=\"#{args[:url]}\" method=\"#{args[:method]}\">' + parts + '</form>');
          jQuery(#{format_type_to_js(format_id("jqgrid_redirector_#{randomizer}"))}).submit();
        }"
      end
    end

    # hash:: Argument hash
    # Builds a default callback based on argument hash. No interaction with
    # grid is provided via this method
    def build_default_callback(hash)
      args = extract_callback_variables(hash)
      if(hash[:remote])
        "function(){ jQuery.ajax(#{format_type_to_js(args[:url])}, #{format_type_to_js(args[:ajax_args])}); }"
      else
        randomizer = rand(99999)
        " function(){ 
            jQuery('body').append('<form id=\"jqgrid_redirector_#{randomizer}\" action=\"#{args[:url]}\" method=\"#{args[:method]}\"></form>');
            jQuery(#{format_type_to_js(format_id("jqgrid_redirector_#{randomizer}"))}).submit();
          }"
      end
    end

    # key:: ondbl_click_row/on_select_row
    # Sets up click event functions based on hash values
    def map_click(key, options)
      if(options[key].is_a?(Hash))
        options[key][:build_callback] = :item
        options[key] = hash_to_callback(options[key])
      end
    end

    def build_toolbar_button(url_hash)
      url_hash[:empty_selection] ||= !url_hash[:single]
      classes = ['grid_toolbar_item', 'button']
      s = <<-EOS
jQuery('<div class="#{(classes + url_hash[:class].to_a).compact.join(' ')}" />')
  .text('#{escape_javascript(url_hash[:name])}')
    .click(
      #{hash_to_callback(url_hash)}
    ).appendTo('#t_#{@table_id}');
EOS
    end
  end
end
