module JqGridRails
  module Helpers
    # arg:: Object
    # Does a simple transition on types from Ruby to Javascript.
    def format_type_to_js(arg)
      case arg
        when Array
          "[#{arg.map{|value| format_type_to_js(value)}.join(',')}]"
        when Hash
          "{#{arg.map{ |key, value|
            k = key.is_a?(Symbol) ? key.to_s.camelize.sub(/^./, key.to_s[0,1].downcase) : "'#{key}'"
            "#{k}:#{format_type_to_js(value)}"
          }.join(',')}}"
        when Fixnum
          arg.to_s
        when TrueClass
          arg.to_s
        when FalseClass
          arg.to_s
        else
          arg.to_s =~ %r{^\s*function\s*\(} ? arg.to_s : "'#{escape_javascript(arg.to_s)}'"
      end
    end

    # dom_id:: DOM ID
    # Convert DOM ID
    def convert_dom_id(dom_id)
      dom_id.to_s.start_with?('#') ? dom_id : "##{dom_id}"
    end
    
    # key:: ondbl_click_row/on_select_row
    # Sets up click event functions based on hash values
    def map_click(key, options)
      if(options[key].is_a?(Hash))
        @url_gen ||= JqGridRails::UrlGenerator.new
        args = options[key][:args].to_a
        args << '!!'
        if(options[key][:remote])
          options[key] = "function(id){ jQuery.get('#{@url_gen.send(options[key][:url], *args)}'.replace('!!', id)) + '#{options[key][:suffix]}'; }"
        else
          options[key] = "function(id){ window.location = '#{@url_gen.send(options[key][:url], *args)}'.replace('!!', id) + '#{options[key][:suffix]}'; }"
        end
      end
    end
  end
end
