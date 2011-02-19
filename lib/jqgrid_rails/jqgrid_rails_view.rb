require 'jqgrid_rails/javascript_helper'

module JqGridRails
  module View
    include ActionView::Helpers::JavaScriptHelper
    include JqGridRails::JavascriptHelper

    # grid:: JqGrid Object
    # Writes required HTML to page for grid
    def jqgrid_html(grid)
      output = "<table id=\"#{grid.table_id}\"></table>"
      output << "<div id=\"#{grid.options[:pager]}\"></div>" if grid.has_pager?
      output.html_safe
    end

    # grid:: JqGrid Object
    # Write jqGrid instructions out to page
    def jqgrid(grid)
      output = jqgrid_html(grid)
      output << javascript_tag(grid.build)
      output.html_safe
    end

    def jqgrid_addrow(dom_id, idx, row_hash)
      "jQuery(\"##{dom_id}\").add_row(#{format_type_to_js(idx)}, #{format_type_to_js(row_hash)});".html_safe
    end
  end 
end
