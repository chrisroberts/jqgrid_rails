module JqGridRails
  module Controller
    
    # These are the valid search operators jqgrid uses
    # and the database translations for them. We use closures
    # for the value so we can modify the string if we see fit
    SEARCH_OPERS = {
      'eq' => ['= ?', lambda{|v| v}],
      'ne' => ['!= ?', lambda{|v|v}],
      'lt' => ['< ?', lambda{|v|v}],
      'le' => ['<= ?', lambda{|v|v}],
      'gt' => ['> ?', lambda{|v|v}],
      'ge' => ['>= ?', lambda{|v|v}],
      'bw' => ['ilike ?', lambda{|v| "#{v}%"}],
      'bn' => ['not ilike ?', lambda{|v| "#{v}%"}],
      'in' => ['in ?', lambda{|v| v.split(',').map(&:strip)}],
      'ni' => ['not in ?', lambda{|v| v.split(',').map(&:strip)}],
      'ew' => ['ilike ?', lambda{|v| "%#{v}"}],
      'en' => ['not ilike ?', lambda{|v| "%#{v}"}],
      'cn' => ['ilike ?', lambda{|v| "%#{v}%"}],
      'nc' => ['not ilike ?', lambda{|v| "%#{v}%"}]
    }

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid. Can be an array of attribute 
    #          names or a Hash mapping with the key being the model 
    #          attribute and value being the reference used within the grid
    # Provides generic JSON response for jqGrid requests (sorting/searching)
    def grid_response(klass, params, fields)
      unless((klass.is_a?(Class) && klass.ancestors.include?(ActiveRecord::Base)) || klass.is_a?(ActiveRecord::Relation))
        raise TypeError.new "Unexpected type received. Allowed types are Class or ActiveRecord::Relation. Received: #{klass.class.name}"
      end
      rel = apply_sorting(klass, params, fields)
      rel = apply_searching(rel, params, fields)
      rel = apply_filtering(rel, params, fields)
      hash = create_result_hash(rel, fields)
      hash.to_json
    end

    # given:: Field for searching
    # fields:: Array or Hash map of fields
    # Returns proper field if mapped and ensures field is valid
    def discover_field(given, fields)
      col = nil
      case fields
        when Hash
          col = fields.detect{|k,v| v.to_s == given}.try(:first)
        when Array
          col = given if fields.map(&:to_s).include?(given)
        else
          raise TypeError.new "Expecting fields to be Array or Hash. Received: #{fields.class.name}"
      end
      raise NameError.new "Requested field was not found in provided fields list. Given: #{given}" unless col
      col
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid
    # Applies any sorting to result set
    def apply_sorting(klass, params, fields)
      sort_col = params[[:sidx, :searchField].find{|sym| !params[:sym].blank?}]
      unless(sort_col)
        begin
          sort_col = discover_field(sort_col, fields)
        rescue NameError
          # continue on and let the sort_col be set to default below
        end
      end
      unless(sort_col)
        sort_col = fields.is_a?(Array) ? fields.first : fields.keys.first
      end
      sort_ord = params[:sord] == 'asc' ? 'ASC' : 'DESC'
      klass.order("#{klass.table_name}.#{sort_col} #{sort_ord}")
    end
    
    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid
    # Applies any search restrictions to result set
    def apply_searching(klass, params, fields)
      unless(params[:searchField].blank?)
        search_field = discover_field(params[:searchField], fields)
        search_oper = params[:searchOper]
        search_string = params[:searchString]
        raise ArgumentError.new("Invalid search operator received: #{search_oper}") unless SEARCH_OPERS.keys.include?(search_oper)
        klass.where([
          "#{search_field} #{SEARCH_OPERS[search_oper].first}",
          SEARCH_OPERS[search_oper].last.call(search_string)
        ])
      else
        klass
      end
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid
    # Applies any filter restrictions to result set
    # TODO: Currently this only supports AND'ing the filters. Need to add
    #       support for grabbing groupOp from parameters and using it for
    #       joining query parameters. 
    def apply_filtering(klass, params, fields)
      rel = klass
      unless(params[:filters].blank?)
        filters = JSON.load(params[:filters])
        filters['rules'].each do |filter|
          field = discover_field(filter['field'], fields)
          oper = filter['op']
          raise ArgumentError.new("Invalid search operator received: #{oper}") unless SEARCH_OPERS.keys.include?(oper)
          data = filter['data']
          rel = rel.where([
            "#{field} #{SEARCH_OPERS[oper].first}",
            SEARCH_OPERS[oper].last.call(data)
          ])
        end
      end
      rel
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # fields:: Fields used within grid
    # Creates a result Hash in the structure the grid is expecting
    def create_result_hash(klass, fields)
      dbres = klass.paginate(
        :page => params[:page], 
        :per_page => params[:rows]
      )
      res = {'total' => dbres.total_pages, 'page' => dbres.current_page, 'records' => dbres.total_entries}
      calls = fields.is_a?(Array) ? fields : fields.is_a?(Hash) ? fields.keys : nil
      maps = fields.is_a?(Hash) ? fields : nil
      res['rows'] = dbres.map do |row|
        hsh = {}
        calls.each do |method|
          if(row.respond_to?(method.to_sym))
            hsh[maps ? maps[method] : method] = row.send(method.to_sym).to_s
          end
        end
        hsh
      end
      res
    end
  end
end
