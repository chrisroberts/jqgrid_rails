require 'jqgrid_rails/javascript_helper'
module JqGridRails
  class JqGrid
    
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::JavaScriptHelper
    include ActionView::Helpers::UrlHelper
    include JqGridRails::JavascriptHelper

    # Options used to build tables
    attr_accessor :options
    # Array of local data rows
    attr_accessor :local
    # table DOM ID
    attr_accessor :table_id
    # Options used for links toolbar
    attr_reader :link_toolbar_options


    # table_id:: DOM ID of table for grid to use
    # args:: Hash of grid options
    #   :url:: URL to query against (*required unless datatype is local)
    #   :datatype:: local/json/xml
    #   :row_id:: This is used by the JSON Reader as the unique ID for a row. By
    #             default this is the first column of the table. This can set it
    #             to any other column. For example, instead of looking up users
    #             by ID and including that information in the table, we can use
    #             username instead: :row_id => :username
    #   Exhaustive list: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:options
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
    end
    
    # name:: Name of column (Invoice)
    # attr:: Attribute of model (invoice_num)
    # args:: Argument hash (anything valid within jqgrid column hash)
    #   :name::
    #   :index::
    #   :width::
    #   :align::
    #   :sorttype::
    #   :formatter::
    #   :editable::
    def add_column(name, attr, args={})
      col = {:name => attr, :index => attr}.merge(args)
      @options[:col_names].push name
      @options[:col_model].push col
    end

    # ary:: Array of Hashes (rows in table)
    # Sets data to be loaded into table
    def set_local_data(ary)
      if(ary.is_a?(Array))
        @local = ary
      else
        raise TypeError.new "Expecting Array value. Received: #{ary.class}"
      end
    end

    # hsh:: Hash of row data for loading into table
    # Adds new row of data to be loaded into table
    def add_local_data(hsh)
      if(hsh.is_a?(Hash))
        @local.push hsh
      else
        raise TypeError.new "Expecting Hash value. Received: #{ary.class}"
      end
    end
    
    # options:: Options hash for the filter toolbar
    # Enables the filter toolbar for the grid
    def enable_filter_toolbar(options={})
      options = {} unless options.is_a?(Hash)
      @filter_toolbar_options = {
        :string_result => true,
        :search_on_enter => true
      }.merge(options)
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
    end

    # link:: url hash: :name, :url, :class
    # Enables link on link toolbar
    def link_toolbar_add(link)
      enable_link_toolbar unless has_link_toolbar?
      @link_toolbar_options[:links].push(link)
    end

    # Builds out the jqGrid javascript and returns the string
    def build
      output = ''
      @options[:datatype] = 'local' unless @local.blank?
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
          output << <<-EOS
jQuery('<div class="#{url_hash[:class]}" />')
  .text('#{escape_javascript(url_hash[:name])}')
    .click(
      function(){
        var ary = jQuery('##{@table_id}').jqGrid('getGridParam', 'selarrrow');
        if(!ary.length)
          ary = new Array();
        ary.push(jQuery('##{@table_id}').jqGrid('getGridParam', 'selrow'));
        ary = ary.filter(function(elm){ return elm != null && elm.length });
        if(!ary.length){
          alert('Please select items from table first.');
        } else {
          jQuery.ajax({url:'#{url_hash[:url]}/?ids[]=' + ary.join('&ids[]='),dataType:'script'});
        }
      }
    ).appendTo('#t_#{@table_id}');
EOS
        end
        output << "jQuery(\"##{@table_id}\").jqGrid('navGrid', '##{@table_id}_linkbar', {edit:false,add:false,del:false});\n"
      end
      output
    end
    alias_method :to_s, :build

    # Returns if the grid has a filter toolbar enabled
    def has_filter_toolbar?
      !@filter_toolbar_options.empty?
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

  end
end
