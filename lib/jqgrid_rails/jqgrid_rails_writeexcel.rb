require 'writeexcel'

module JqGridRails
  module WriteExcel
    def write_excel(klass, params, fields, heading_format=nil)
      table = raw_response(klass, params, fields)
      heading_format ||= {:bold => 1, :align => :center, :bg_color => 5}
      fields = scrub_fields(fields)
      path = self.respond_to?(:create_tmpfile) ? create_tmpfile(:name => 'grid_export').path : Rails.root.join('tmp', "grid_export_#{Time.now.to_i.to_s + rand(999).to_s}.xls")
      book = ::WriteExcel.new(path)
      worksheet = book.add_worksheet
      h_format = book.add_format(heading_format)
      formats = {}
      worksheet.split_panes
      headings = ActiveSupport::OrderedHash.new
      if(fields.is_a?(Array))
        fields.each do |x|
          headings[x] = x.to_s.titlecase
        end
      else
        fields.each_pair do |key, value|
          headings[key] = value[:excel_heading] || key.to_s.titlecase
          if(value[:excel_format])
            format = book.add_format(value[:excel_format])
            formats[key] = format
          end
        end
      end
      idx = 0
      headings.each_pair do |key, heading|
        worksheet.write(0, idx, heading, h_format)
        idx += 1
      end
      row = 1
      table['rows'].each do |hash|
        headings.keys.each_with_index do |key, idx|
          worksheet.write(row, idx, hash[key], formats[key])
        end
        row += 1
      end
      book.close
      path
    end
  end
end
