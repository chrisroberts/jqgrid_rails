require 'jqgrid_rails/javascript_helper'

module JqGridRails
  module View
    include ActionView::Helpers::JavaScriptHelper
    include JqGridRails::JavascriptHelper
    include ActionView::Helpers::TagHelper

    # grid:: JqGrid Object
    # Writes required HTML to page for grid
    def jqgrid_html(grid)
      output = ''
      if(grid.has_link_toolbar? && grid.link_toolbar_options[:top])
        output << "<div id=\"#{grid.table_id}_linkbar_container\" class=\"jqgrid_linkbar_container\">"
        output << "<div id=\"#{grid.table_id}_linkbar}\" class=\"jqgrid_linkbar\"></div>"
        output << "</div>"
      end
      output = "<table id=\"#{grid.table_id}\"></table>"
      if(grid.has_pager?)
        output << "<div id=\"#{grid.table_id}_pager\"></div>"
      end
      if(grid.has_link_toolbar? && grid.link_toolbar_options[:bottom])
        output << "<div id=\"#{grid.table_id}_linkbar_container\" class=\"jqgrid_linkbar_container\">"
        output << "<div id=\"#{grid.table_id}_linkbar}\" class=\"jqgrid_linkbar\"></div>"
        output << "</div>"
      end
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
