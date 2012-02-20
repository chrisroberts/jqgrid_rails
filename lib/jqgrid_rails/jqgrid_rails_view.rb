require 'jqgrid_rails/jqgrid_rails_helpers'

module JqGridRails
  module View
    include ActionView::Helpers::JavaScriptHelper
    include JqGridRails::Helpers
    include ActionView::Helpers::TagHelper

    # grid_or_id:: JqGrid Object or ID
    # Returns required HTML for grid
    def jqgrid_html(grid_or_id, *args)
      dom_id = grid_or_id.respond_to?(:table_id) ? grid_or_id.table_id : grid_or_id
      output = "<div id=\"#{dom_id}_holder\" style=\"width:100%\"><table id=\"#{dom_id}\" width=\"100%\"></table></div>"
      if((grid_or_id.respond_to?(:has_link_toolbar?) && grid_or_id.has_link_toolbar?) || args.include?(:with_link_toolbar))
        output << "<div id=\"#{dom_id}_linkbar\" class=\"jqgrid_linkbar\"></div>"
      end
      if((grid_or_id.respond_to?(:has_pager?) && grid_or_id.has_pager?) || args.include?(:with_pager))
        output << "<div id=\"#{dom_id}_pager\"></div>"
      end
      output.html_safe
    end

    # grid:: JqGrid Object
    # Returns required javascript for grid
    def jqgrid_js(grid, *args)
      args.include?(:notag) || args.include?(:raw) ? grid.build : javascript_tag(grid.build)
    end

    # grid:: JqGrid Object
    # Returns complete jqGrid instructions for building within HTML document
    def jq_grid(grid)
      output = jqgrid_html(grid)
      output << jqgrid_js(grid)
      if grid.detached_javascript.present?
        output << javascript_tag{ "jQuery(document).ready(function(){ #{grid.detached_javascript.join("\n")}});".html_safe }
      end
      output.html_safe
    end
    alias_method :jqgrid, :jq_grid

    def jqgrid_addrow(dom_id, idx, row_hash)
      "jQuery(#{convert_dom_id(dom_id)}).add_row(#{format_type_to_js(idx)}, #{format_type_to_js(row_hash)});".html_safe
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
      javascript_tag("tableToGrid(#{convert_dom_id(dom_id)}, #{format_type_to_js(options)}); jQuery(#{convert_dom_id(dom_id)}).trigger('reloadGrid');")
    end

    # dom_id:: Grid DOM ID
    # args:: Extra arguments. :raw for no tag wrapping
    # Reload given table
    def reload_grid(dom_id, *args)
      dom_id = "##{dom_id}" unless dom_id.start_with?('#')
      output = "jQuery('#{dom_id}').trigger('reloadGrid');".html_safe
      if(args.include?(:wrapped))
        javascript_tag(output)
      else 
        output
      end
    end
  end 
end

ActionView::Base.send :include, JqGridRails::View
