require 'jqgrid_rails/jqgrid_url_generator'
require 'jqgrid_rails/jqgrid_rails_helpers'
module JqGridRails
  class JqGrid
    
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::JavaScriptHelper
    include ActionView::Helpers::UrlHelper
    include JqGridRails::Helpers

    # Options used to build tables
    attr_accessor :options
    # Array of local data rows
    attr_accessor :local
    # table DOM ID
    attr_accessor :table_id
    # Options used for links toolbar
    attr_reader :link_toolbar_options


    # table_id:: DOM ID of table for grid to use
    # args:: Hash of {jqGrid options}[http://www.trirand.com/jqgridwiki/doku.php?id=wiki:options]
    def initialize(table_id, args={})
      defaults = {
        :datatype => :json,
        :col_names => [],
        :col_model => [],
        :viewrecords => true,
        :json_reader => {
          :root => 'rows',
          :page => 'page',
          :total => 'total',
          :records => 'records',
          :id => args.delete(:row_id) || 0,
          :repeatitems => false,
        }
      }
      if(args[:url].blank? && args[:datatype].to_s != 'local')
        raise ArgumentError.new 'URL is required unless :datatype is set to local'
      end
      @table_id = table_id.gsub('#', '')
      @options = defaults.merge(args)
      @pager_options = {:edit => false, :add => false, :del => false}
      if(t_args = @options.delete(:filter_toolbar))
        enable_filter_toolbar(t_args.is_a?(Hash) ? t_args : nil)
      end
      if(t_args = options.delete(:link_toolbar))
        enable_link_toolbar(t_args.is_a?(Hash) ? t_args : nil)
      end
      @options[:pager] = "#{@table_id}_pager" if @options[:pager] == true
      @local = []
      @output = ''
    end
    
    # name:: Name of column (Invoice)
    # attr:: Attribute of model (invoice_num)
    # args:: Hash of {colModel options}[http://www.trirand.com/jqgridwiki/doku.php?id=wiki:colmodel_options]
    def add_column(name, attr, args={})
      col = {:name => attr, :index => attr}.merge(args)
      map = col.delete(:map_values)
      col[:index] = JqGridRails.escape(col[:index]) unless @options[:no_index_escaping]
      col[:formatter] = add_value_mapper(map) if map
      @options[:col_names].push name
      @options[:col_model].push col
      self
    end

    # ary:: Array of Hashes (rows in table)
    # Sets data to be loaded into table
    def set_local_data(ary)
      if(ary.is_a?(Array))
        @local = ary
      else
        raise TypeError.new "Expecting Array value. Received: #{ary.class}"
      end
      self
    end

    # hsh:: Hash of row data for loading into table
    # Adds new row of data to be loaded into table
    def add_local_data(hsh)
      if(hsh.is_a?(Hash))
        @local.push hsh
      else
        raise TypeError.new "Expecting Hash value. Received: #{ary.class}"
      end
      self
    end
    
    # options:: Options hash for the filter toolbar
    # Enables the filter toolbar for the grid
    def enable_filter_toolbar(options={})
      options = {} unless options.is_a?(Hash)
      @filter_toolbar_options = {
        :string_result => true,
        :search_on_enter => true
      }.merge(options)
      self
    end

    # options:: Options for toolbar
    # Enables the link toolbar for the grid
    def enable_link_toolbar(options={})
      options = {} unless options.is_a?(Hash)
      @link_toolbar_options = {
        :top => true,
        :bottom => false,
        :links => []
      }.merge(options)
      @options[:toolbar] = [true, 'top']
      self
    end

    # link:: url hash: :name, :url, :class
    # Enables link on link toolbar
    def link_toolbar_add(link)
      enable_link_toolbar unless has_link_toolbar?
      @link_toolbar_options[:links].push(link)
      self
    end

    # Builds out the jqGrid javascript and returns the string
    def build
      output = ''
      @options[:datatype] = 'local' unless @local.blank?
      ####################################
      load_multi_select_fix              # TODO: Remove this when fixed in jqGrid
      ####################################
      map_double_click
      map_single_click
      output << "jQuery(\"##{@table_id}\").jqGrid(#{format_type_to_js(@options)});\n"
      unless(@local.blank?)
        output << "if(typeof(jqgrid_local_data) == 'undefined'){ var jqgrid_local_data = new Hash(); }\n"
        output << "jqgrid_local_data.set('#{@table_id}', #{format_type_to_js(@local)});\n"
        output << "for(var i = 0; i < jqgrid_local_data.get('#{@table_id}').length; i++){ jQuery(\"#{@table_id}\").jqGrid('addRowData', i+1, jqgrid_local_data.get('#{@table_id}')[i]); }\n"
      end
      if(has_pager?)
        output << "jQuery(\"##{@table_id}\").jqGrid('navGrid', '##{@options[:pager]}', #{format_type_to_js(@pager_options)});"
      end
      if(has_filter_toolbar?)
        output << "jQuery(\"##{@table_id}\").jqGrid('filterToolbar', #{format_type_to_js(@filter_toolbar_options)});\n"
      end
      if(has_link_toolbar?)
        @link_toolbar_options[:links].each do |url_hash|
          output << create_toolbar_button(url_hash)
        end
        output << "jQuery(\"##{@table_id}\").jqGrid('navGrid', '##{@table_id}_linkbar', {edit:false,add:false,del:false});\n"
      end
      "#{@output}\n#{output}"
    end
    alias_method :to_s, :build

    # Returns if the grid has a filter toolbar enabled
    def has_filter_toolbar?
      !@filter_toolbar_options.blank?
    end

    # Returns if the grid has a pager enabled
    def has_pager?
      @options[:pager] = "#{@table_id}_pager" if @options[:pager] == true
      @options.has_key?(:pager)
    end

    # Returns if the grid has a link toolbar enabled
    def has_link_toolbar?
      !@link_toolbar_options.blank? && !@link_toolbar_options[:links].empty?
    end

    def add_value_mapper(map)
      function_name = "map_#{Digest::SHA1.hexdigest(Time.now.to_f.to_s)}"
      @output << "jQuery.extend(jQuery.fn.fmatter, {
        #{function_name} : function(cellvalue, options, rowdata){
          keys = #{format_type_to_js(map.keys)}
          values = #{format_type_to_js(map.values)}
          return values[jQuery.inArray(cellvalue, keys)];
        }
      });"
      function_name
    end

    def map_double_click
      map_click(:ondbl_click_row, options)
    end

    def map_single_click
      map_click(:on_cell_select, options)
    end

    def create_toolbar_button(url_hash)
      url_hash[:method] = url_hash[:method].to_s if url_hash[:method]
      ajax_args = url_hash.delete(:ajax) || {}
      ajax_args[:type] ||= url_hash.delete(:method) || 'get'
      ajax_args[:type] = ajax_args[:type].to_s
      classes = ['grid_toolbar_item', 'button']
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
        if(!ary.length && #{format_type_to_js(!url_hash[:single])}){
          alert('Please select items from table first.');
        } else {
          if(!ary.length){
            #{
              if(url_hash[:remote])
                "jQuery.ajax('#{url_hash[:url]}', #{format_type_to_js(ajax_args)});"
              else
                "jQuery('<form action=\"#{url_hash[:url]}\" method=\"#{(url_hash[:method] || 'get').to_s.upcase}\"></form>').submit();"
                "window.location = '#{url_hash[:url]}';"
              end
            }
          }
          else{
            ary_hash = {'ids[]' : ary};
            #{
              if(url_hash[:remote])
                ajax_args[:data] = RawJS.new('ary_hash')
                "jQuery.ajax('#{url_hash[:url]}', #{format_type_to_js(ajax_args)});"
              else
                "
                  parts = ary.map(
                    function(item){
                      return '<input type=\"hidden\" name=\"ids[]\" value=\"'+item+'\"/>';
                    }
                  );
                  jQuery('<form action=\"#{url_hash[:url]}\" method=\"#{(url_hash[:method] || 'get').to_s.upcase}\">' + parts + '</form>').submit();
                "
              end
            }
          }
        }
      }
    ).appendTo('#t_#{@table_id}');
EOS
    end
    
    # This is a fix for the multi select within jqGrid. Rouge values will
    # appear in the selection listing so this cleans things up properly
    def load_multi_select_fix
      @options[:on_select_all] = 'function(row_ids, status){
        var grid = jQuery(this);
        grid.jqGrid("resetSelection");
        if(status){
          jQuery.each(grid.jqGrid("getRowData"), function(){
            grid.jqGrid(
              "setSelection", 
              this[grid.jqGrid("getGridParam", "jsonReader")["id"]]
            );
          });
        }
        jQuery("#cb_'+@table_id+'").attr("checked", status);
      }'
    end
  end
end
