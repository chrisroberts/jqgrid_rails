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
      @table_id = table_id.is_a?(String) ? table_id.gsub('#', '') : table_id
      @options = defaults.merge(args)
      @pager_options = {:edit => false, :add => false, :del => false}
      if(t_args = @options.delete(:filter_toolbar))
        enable_filter_toolbar(t_args.is_a?(Hash) ? t_args : nil)
      end
      if(t_args = options.delete(:link_toolbar))
        enable_link_toolbar(t_args.is_a?(Hash) ? t_args : nil)
      end
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

    def disable_filter_toolbar
      @filter_toolbar_options = nil
      self
    end

    def disable_link_toolbar
      @link_toolbar_options = nil
      self
    end

    # link:: url hash: :name, :url, :class
    # Enables link on link toolbar
    def link_toolbar_add(link)
      enable_link_toolbar unless has_link_toolbar?
      @link_toolbar_options[:links].push(link)
      self
    end
    alias_method :add_toolbar_link, :link_toolbar_add

    # name:: text for button
    # Exports current grid into excel document
    # TODO: Add options to turn off paging and the like
    def add_excel_export_button(name='Export to XLS')
      name = 'Export to XLS' unless name.is_a?(String)
      link_toolbar_add(
        :name => name,
        :empty_selection => true,
        :method => :post,
        :url => RawJS.new("' + jQuery(#{convert_dom_id(@table_id)}).jqGrid('getGridParam', 'url') + '"),
        :ajax_args => {
          :data => RawJS.new("(function(){
            vals = jQuery(#{convert_dom_id(@table_id)}).jqGrid('getGridParam', 'postData');
            res = {};
            Object.keys(vals).each(function(key){
              res[key] = vals[key];
            });
            res['rows'] = 10000000;
            res['page'] = 1;
            res['format'] = 'xls';
            return res;
          })()")
        }
      )
      self
    end

    def fix_grid_width
      js = "jQuery(#{convert_dom_id(@table_id)}).jqGrid('setGridWidth', jQuery(#{convert_dom_id(@table_id)} + '_holder').innerWidth(), true); }"
      if(@options[:load_complete])
        @options[:load_complete].sub!(/^(\s*function.*?\{)/, "\\1#{js}")
      else
        @options[:load_complete] = "function(){ #{js} return true; }"
      end
    end

    # Builds out the jqGrid javascript and returns the string
    def build
      output = ''
      fix_grid_width
      @options[:datatype] = 'local' unless @local.blank?
      resizable = @options.delete(:resizable_grid)
      ####################################
      load_multi_select_fix              # TODO: Remove this when fixed in jqGrid
      ####################################
      map_double_click
      map_single_click
      set_search_options
      @options = scrub_options_hash(@options)
      sortable_rows = @options.delete(:sortable_rows)
      has_pager? # convert if required
      if(@options[:excel_exportable])
        add_excel_export_button(@options.delete(:excel_exportable))
      end
      output << "jQuery(#{convert_dom_id(@table_id)}).jqGrid(#{format_type_to_js(@options)});\n"
      unless(@local.blank?)
        output << "if(typeof(jqgrid_local_data) == 'undefined'){ var jqgrid_local_data = new Hash(); }\n"
        output << "jqgrid_local_data.set(#{convert_dom_id(@table_id)}, #{format_type_to_js(@local)});\n"
        output << "for(var i = 0; i < jqgrid_local_data.get(#{convert_dom_id(@table_id)}).length; i++){ jQuery(#{convert_dom_id(@table_id)}).jqGrid('addRowData', i+1, jqgrid_local_data.get(#{convert_dom_id(@table_id)})[i]); }\n"
      end
      if(has_pager?)
        output << "jQuery(#{convert_dom_id(@table_id)}).jqGrid('navGrid', #{format_type_to_js(@options[:pager])}, #{format_type_to_js(@pager_options)});"
      end
      if(has_filter_toolbar?)
        output << "jQuery(#{convert_dom_id(@table_id)}).jqGrid('filterToolbar', #{format_type_to_js(@filter_toolbar_options)});\n"
      end
      if(has_link_toolbar?)
        @link_toolbar_options[:links].each do |url_hash|
          output << create_toolbar_button(url_hash)
        end
        output << "jQuery(#{convert_dom_id(@table_id)}).jqGrid('navGrid', #{convert_dom_id(@table_id)} + '_linkbar', {edit:false,add:false,del:false});\n"
      end
      if(sortable_rows)
        output << enable_sortable_rows(scrub_options_hash(sortable_rows))
      end
      unless(resizable == false)
        if(resizable.respond_to?(:[]))
          output << resizable_grid(resizable)
        else
          output << resizable_grid
        end
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
      @options[:pager] = RawJS.new("#{convert_dom_id(@table_id)} + '_pager'") if @options[:pager] == true
      @options.has_key?(:pager)
    end

    # Returns if the grid has a link toolbar enabled
    def has_link_toolbar?
      !@link_toolbar_options.blank? && !@link_toolbar_options[:links].empty?
    end

    # map:: Hash of key value mapping
    # Creates a client side value mapper using a randomized function name
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

    # Creates function callback for row double clicks
    def map_double_click
      map_click(:ondbl_click_row, options) if options[:ondbl_click_row]
    end

    # Creates function callback from row single clicks
    def map_single_click
      map_click(:on_cell_select, options) if options[:on_cell_select]
      map_click(:on_select_row, options) if options[:on_select_row]
    end

    # Syncs up filter toolbar values with advanced search values if the
    # advanced search values have not already been provided
    def set_search_options
      if(@options[:col_model])
        @options[:col_model].each do |column|
          if(column[:editoptions] && column[:editoptions][:value])
            column[:searchoptions] ||= {}
            unless(column[:searchoptions].has_key?(:value))
              column[:searchoptions][:value] = column[:editoptions][:value]
            end
          end
        end
      end
    end

    # url_hash:: Hash of url options. Use :method to specify request method other than 'get'
    # Creates a toolbar button on the grid
    def create_toolbar_button(url_hash)
      build_toolbar_button(url_hash)
    end

    # sortable_rows:: options hash
    # Enables row sorting on grid
    # TODO: Add helpers to build remote callbacks in the
    # same format as the click events and toolbar links
    def enable_sortable_rows(sortable_rows)
      sortable_rows = {} unless sortable_rows.is_a?(Hash)
      "jQuery(#{convert_dom_id(@table_id)}).sortableRows(#{format_type_to_js(sortable_rows)});\n"
    end
    
    # This is a fix for the multi select within jqGrid. Rouge values will
    # appear in the selection listing so this cleans things up properly
    def load_multi_select_fix
      @options[:on_select_all] = "function(row_ids, status){
        var grid = jQuery(this);
        grid.jqGrid('resetSelection');
        if(status){
          jQuery.each(grid.jqGrid('getRowData'), function(){
            grid.jqGrid(
              'setSelection', 
              this['id']
            );
          });
        }
        jQuery('#cb_' + #{convert_dom_id(@table_id)}.replace(/^#/, '')).attr('checked', status);
      }"
    end

    # pad:: Padding after resize
    # Binds to resizestop event on available parent that has been marked resizable
    # via jqquery-ui. Resizes grid after container is resized
    def resizable_grid(opts = {})
      "var _resizable_parent = jQuery(#{convert_dom_id(@table_id)}).parents('.ui-resizable');
       _resizable_parent.bind('resizestop', function(){
         var width = _resizable_parent.attr('clientWidth');
         if(width == null || width < 1){
           width = _resizable_parent.attr('offsetWidth');
         }
         if(width > 0 && ((Math.abs(width) - jQuery(#{convert_dom_id(@table_id)}).width() > 5) || (Math.abs(width) - jQuery(#{convert_dom_id(@table_id)}).width() < -5))){
           jQuery(#{convert_dom_id(@table_id)}).setGridWidth(width - #{(opts[:width_pad] || 40).to_i});
         }
         var height = _resizable_parent.attr('clientHeight');
         if(height == null || height < 1){
           height = _resizable_parent.attr('offsetHeight');
         }
         if(height > 0 && ((Math.abs(height) - jQuery(#{convert_dom_id(@table_id)}).height() > 5) || (Math.abs(height) - jQuery(#{convert_dom_id(@table_id)}).height() < -5))){
           jQuery(#{convert_dom_id(@table_id)}).setGridHeight(height - #{(opts[:height_pad] || 40).to_i});
         }
       }).trigger('resize');"
    end
  end
end
