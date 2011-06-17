module JqGridRails
  ESCAPES = {
    '.' => '___'
  }

  class << self
    def escape(string)
      string = string.to_s.dup
      ESCAPES.each_pair do |orig,mapping|
        string.gsub!(orig,mapping)
      end
      string
    end

    def unescape(string)
      string = string.to_s.dup
      ESCAPES.each_pair do |orig,mapping|
        string.gsub!(mapping,orig)
      end
      string
    end
  end
end
