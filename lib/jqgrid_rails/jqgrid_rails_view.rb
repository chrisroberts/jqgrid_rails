require 'jqgrid_rails/jqgrid_rails_helpers'

module JqGridRails
  module View
    include ActionView::Helpers::JavaScriptHelper
    include JqGridRails::Helpers
    include ActionView::Helpers::TagHelper

    # grid:: JqGrid Object
    # Writes required HTML to page for grid
    def jqgrid_html(grid)
      output = "<div id=\"#{grid.table_id}_holder\" style=\"width:100%\"><table id=\"#{grid.table_id}\" width=\"100%\"></table></div>"
      if(grid.has_link_toolbar?)
        output << "<div id=\"#{grid.table_id}_linkbar\" class=\"jqgrid_linkbar\"></div>"
      end
      if(grid.has_pager? && grid.options[:pager] == "#{grid.table_id}_pager")
        output << "<div id=\"#{grid.options[:pager]}\"></div>"
      end
      output.html_safe
    end

    # grid:: JqGrid Object
    # Write jqGrid instructions out to page
    def jq_grid(grid)
      output = jqgrid_html(grid)
      output << javascript_tag(grid.build)
      output.html_safe
    end
    alias_method :jqgrid, :jq_grid

    def jqgrid_addrow(dom_id, idx, row_hash)
      "jQuery(\"#{convert_dom_id(dom_id)}\").add_row(#{format_type_to_js(idx)}, #{format_type_to_js(row_hash)});".html_safe
    end

    # dom_id:: DOM ID of existing table
    # options:: Options hash for jqgrid
    def table_to_grid(dom_id, options={})
      [:ondbl_click_row,:on_cell_select].each do |key|
        map_click(key, options)
      end
      options.each do |key,val|
        if(val.is_a?(Hash))
          options[key] = hash_to_callback(val)
        end
      end
      javascript_tag("tableToGrid(\"#{convert_dom_id(dom_id)}\", #{format_type_to_js(options)}); jQuery(\"#{convert_dom_id(dom_id)}\").trigger('reloadGrid');")
    end
  end 
end

ActionView::Base.send :include, JqGridRails::View
