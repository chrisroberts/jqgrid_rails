module JqGridRails
  module Controller

    def grid_resort(klass, params, fields)
      sort_col = nil
      if(!params[:sidx].blank?)
        check = fields.is_a?(Hash) ? fields.detect{|k,v| v.to_s == params[:sidx]}.first
      end
      unless(sort_col)
        sort_col = fields.is_a?(Array) ? fields.first : fields.keys.first
      end
      sort_col = !params[:sidx].blank? && klass.attribute_method?(params[:sidx].to_sym) ? params[:sidx] : fields.is_a?(Array) ? fields.first : fields.keys.first
      sort_ord = params[:sord] == 'asc' ? 'ASC' : 'DESC'
      dbres = klass.paginate(
        :page => params[:page], 
        :per_page => params[:rows], 
        :order => "#{klass.table_name}.#{sort_col} #{sort_ord}"
      )
      res = {'total' => dbres.total_entries, 'page' => dbres.current_page, 'records' => dbres.count}
      calls = fields.is_a?(Array) ? fields : fields.is_a?(Hash) ? fields.keys : nil
      maps = fields.is_a?(Hash) ? fields : nil
      res['rows'] = dbres.map do |row|
        hsh = {}
        calls.each do |method|
          if(row.respond_to?(method.to_sym))
            hsh[maps ? maps[method] : method] = row.send(method.to_sym)
          end
        end
        hsh
      end
      res.to_json
    end

  end
end
