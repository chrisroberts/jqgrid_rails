#TODO: :with_row option is currently only applied to remote calls. Needs to be updated
#      for non-ajax calls by adding dynamic form updates to include inputs for row data
require 'rails_javascript_helpers'

module JqGridRails
  module Helpers
    include RailsJavaScriptHelpers

    # id:: String or RawJS object
    # Ensures a DOM ID is returned from id. Does simple
    # string replacement client side to force a # prefix.
    # Client side conversion allows the id to be a RawJS
    # instance for dynamic grid IDs
    def convert_dom_id(id)
      RawJS.new("#{format_type_to_js(id)}.replace(/^#*/, '#')")
    end

    # hash:: Argument hash for callback generation
    # Generates a javascript callback from a Ruby hash. Important hash keys:
    # :build_callback -> [false|:item|:selection] (false will stop callback from being created and simply return original hash)
    # :url            -> Symbol of route method name or string for actual url
    # :args           -> Arguments to be used when generating URL from :url value
    # :method         -> Request method (defaults to 'get')
    # :ajax_args      -> Arguments for jQuery.ajax options hash
    # :remote         -> [true|false] Request should be made via ajax
    # :id_replacement -> Value used for dynamic ID replacement (generally not to be altered)
    # :item_id        -> Use for :item type callbacks to set URL generated ID if not the generic 'id' variable
    def hash_to_callback(hash)
      if(hash.is_a?(Hash) && hash[:build_callback] != false && hash[:url])
        case hash[:build_callback]
        when :item
          build_single_callback(hash)
        when :selection
          build_selection_callback(hash)
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
        url_args = hash[:args].is_a?(Array) ? hash[:args] : [hash[:args]]
        args[:url] = @url_gen.send(hash[:url], *(url_args.sort_by{|x,y| if(x.is_a?(Hash) && y.is_a?(Hash)) then 0 elsif(x.is_a?(Hash)) then 1 else -1 end}))
      else
        args[:url] = hash[:url]
      end
      if(hash[:args_replacements].present?)
        if(hash[:args_replacements].is_a?(Hash))
          args[:args_replacements] = hash[:args_replacements].map{|fake_id, js_id| "replace(#{format_type_to_js(fake_id)}, #{format_type_to_js(js_id)})" }.join('.')
          unless(args[:args_replacements].blank?)
            args[:args_replacements] = ".#{args[:args_replacements]}"
          end
        else
          args[:args_replacements] = hash[:args_replacements]
        end
      end
      args[:ajax_args][:type] = args[:method] if hash[:remote]
      args
    end

    # hash:: Argument hash
    # Builds callback function for single selection
    def build_single_callback(hash)
      hash[:id_replacement] ||= '000'
      hash[:args] = Array(hash[:args]) unless hash[:args].is_a?(Array)
      hash[:args].push hash[:id_replacement]
      args = extract_callback_variables(hash)
      item_id = args[:item_id].present? ? args[:item_id] : RawJS.new('id')
      if(hash[:remote])
        if(hash[:with_row])
          args[:ajax_args] ||= {}
          args[:ajax_args][:data] = {:row_data => RawJS.new("jQuery(#{convert_dom_id(@table_id)}).jqGrid('getRowData', id)")}
        end
        " function(id){
            jQuery.ajax(#{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, #{format_type_to_js(item_id)})#{args[:args_replacements]}, #{format_type_to_js(args[:ajax_args])});
          }
        "
      else
        form_rand = rand(999)
        " function(id){
            jQuery('body').append('<form id=\"redirector_#{form_rand}\" action=\"#{args[:url]}\" method=\"#{args[:method]}\"></form>'.replace(#{format_type_to_js(args[:id_replacement])}, #{format_type_to_js(item_id)})#{args[:args_replacements]});
            jQuery('#redirector_#{form_rand}').submit();
          }
        "
      end
    end

    # Returns callable function to get current selection in array form
    def selection_array(error_when_empty=true, table_id=nil)
      dom_id = convert_dom_id(table_id || @table_id)
      " function(){ 
          ary = jQuery(#{dom_id}).jqGrid('getGridParam', 'selarrrow');
          if(!ary.length){ ary = []; }
          ary.push(jQuery(#{dom_id}).jqGrid('getGridParam', 'selrow'));
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
      hash[:args] = Array(hash[:args]) unless hash[:args].is_a?(Array)
      hash[:args].push hash[:id_replacement]
      args = extract_callback_variables(hash)
      function = "function(){ 
        rows_func = #{selection_array(true, table_id)} 
        ary = rows_func();
        if(!ary.length){ return false; }
      "
      if(hash[:remote])
        args[:ajax_args][:data] = {:ids => RawJS.new('ary')}
        if(hash[:with_row])
          args[:ajax_args][:data][:row_data => RawJS.new("jQuery(#{convert_dom_id(@table_id)}).jqGrid('getRowData')")]
        end
        function << "jQuery.ajax(#{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, ary[0])#{args[:args_replacements]}, #{format_type_to_js(args[:ajax_args])}); }"
      else
        randomizer = rand(99999)
        function << "parts = ary.map(
          function(item){
            return '<input type=\"hidden\" name=\"ids[]\" value=\"'+item+'\"/>';
          });
          target_url = #{format_type_to_js(args[:url])}.replace(#{format_type_to_js(args[:id_replacement])}, ary[0])#{args[:args_replacements]};
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
        "function(){ jQuery.ajax(#{format_type_to_js(args[:url])}#{args[:args_replacements]}, #{format_type_to_js(args[:ajax_args])}); }"
      else
        randomizer = rand(99999)
        output = " function(){ 
            jQuery('body').append('<form id=\"jqgrid_redirector_#{randomizer}\" action=\"#{args[:url]}#{args[:args_replacements]}\" method=\"#{args[:method]}\"></form>');"
        if(hash[:ajax_args] && hash[:ajax_args][:data])
          output << "var args = #{format_type_to_js(hash[:ajax_args][:data])};
            Object.keys(args).each(function(key){
              jQuery('#{format_id("jqgrid_redirector_#{randomizer}")}').append(jQuery('<input/>')
                .attr('type', 'hidden')
                .attr('name', key)
                .val(args[key])
              );
            });"
        end
        output << "jQuery(#{format_type_to_js(format_id("jqgrid_redirector_#{randomizer}"))}).submit();
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

    # url_hash:: hash for url building
    # Creates a toolbar button for the grid
    def build_toolbar_button(url_hash)
      url_hash[:empty_selection] ||= url_hash[:single]
      url_hash[:build_callback] ||= :selection unless url_hash[:empty_selection]
      classes = ['grid_toolbar_item', 'button', 'ui-state-default', 'ui-corner-all']
      s = <<-EOS
jQuery('<div class="#{(classes + Array(url_hash[:class])).compact.join(' ')}" />')
  .text('#{escape_javascript(url_hash[:name])}')
    .button()
      .click(
        #{hash_to_callback(url_hash)}
      ).appendTo('#t_' + #{format_type_to_js(@table_id)});
EOS
    end

    # options_hash:: Hash of options
    # Inserts callbacks in any applicable values
    def scrub_options_hash(options_hash)
      options_hash.each do |key,value|
        options_hash[key] = hash_to_callback(value)
      end
      options_hash
    end
  end
end
