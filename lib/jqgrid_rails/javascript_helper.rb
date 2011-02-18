module JqGridRails
  module JavascriptHelper
    # arg:: Object
    # Does a simple transition on types from Ruby to Javascript.
    def format_type_to_js(arg)
      case arg
        when Array
          "[#{arg.map{|value| format_type_to_js(value)}.join(',')}]"
        when Hash
          "{#{arg.map{ |key, value|
            k = key.is_a?(Symbol) ? key.to_s.camelize.sub(/^./, key.to_s[0,1].downcase) : key.to_s
            "#{k}:#{format_type_to_js(value)}"
          }.join(',')}}"
        when Fixnum
          arg.to_s
        when TrueClass
          arg.to_s
        when FalseClass
          arg.to_s
        else
          "'#{escape_javascript(arg.to_s)}'"
      end
    end
  end
end
