module JqGridRails
  module Controller
    
    # These are the valid search operators jqgrid uses
    # and the database translations for them. We use closures
    # for the value so we can modify the string if we see fit
    SEARCH_OPERS = {
      'eq' => ['= ?', lambda{|v|v}],
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
    # fields:: Fields used within grid. Can be an array of attribute names or a Hash with keys of attributes and Hash values with options
    #   Array: [col1, col2, col3]
    #   Hash: {'col1' => {:fomatter => lambda{|v|v.to_s.upcase}, :order => 'other_table.col1'}}
    # Provides generic JSON response for jqGrid requests (sorting/searching)
    def grid_response(klass, params, fields)
      allowed_consts = %w(ActiveRecord::Base ActiveRecord::Relation ActiveRecord::NamedScope::Scope)
      unless(allowed_consts.detect{|const| klass.ancestors.detect{|c| c.to_s == const}})
        raise TypeError.new "Unexpected type received. Allowed types are Class or ActiveRecord::Relation. Received: #{klass.class.name}"
      end
      clean_fields = nil
      if(fields.is_a?(Hash))
        clean_fields = {}
        fields.each_pair do |k,v|
          clean_fields[k.to_s] = v.nil? ? {} : v
        end
      else
        clean_fields = fields.map(&:to_s)
      end
      if(clean_fields.is_a?(Hash))
        raise TypeError.new 'Hash values must be of Hash type or nil' if fields.values.detect{|v| !v.is_a?(Hash)}
      end
      rel = apply_sorting(klass, params, clean_fields)
      rel = apply_searching(rel, params, clean_fields)
      rel = apply_filtering(rel, params, clean_fields)
      hash = create_result_hash(rel, clean_fields)
      hash.to_json
    end

    # given:: Field for searching
    # fields:: Array or Hash map of fields
    # Returns proper field if mapped and ensures field is valid
    def discover_field(given, fields)
      col = nil
      case fields
        when Hash
          col = fields.keys.detect{|key| key.to_s == given}
        when Array
          col = given if fields.map(&:to_s).include?(given)
        else
          raise TypeError.new "Expecting fields to be Array or Hash. Received: #{fields.class.name}"
      end
      raise NameError.new "Requested field was not found in provided fields list. Given: #{given}" unless col
      col
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # col:: Sort column
    # fields:: Aray or Hash map of fields
    # Returns proper sorter based on inference or user defined
    def discover_sorter(klass, col, fields)
      if(fields.is_a?(Hash) && fields[col][:order].present?)
        fields[col][:order]
      else
        parts = col.split('.')
        if(parts.size > 1)
          parts = parts[-2,2]
          "#{parts.first.pluralize}.#{parts.last}"
        else
          "#{klass.table_name}.#{parts.first}"
        end
      end
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid
    # Applies any sorting to result set
    def apply_sorting(klass, params, fields)
      sort_col = params[[:sidx, :searchField].find{|sym| !params[sym].blank?}]
      unless(sort_col)
        begin
          sort_col = discover_field(sort_col, fields)
        rescue NameError
          # continue on and let the sort_col be set to default below
        end
      end
      unless(sort_col)
        sort_col = (fields.is_a?(Hash) ? fields.keys : fields).first
      end
      sorter = discover_sorter(klass, sort_col, fields)
      sort_ord = params[:sord] == 'asc' ? 'ASC' : 'DESC'
      if(defined?(ActiveRecord::Relation) && klass.is_a?(ActiveRecord::Relation))
        klass.order("#{sorter} #{sort_ord}")
      else
        klass.scoped(:order => "#{sorter} #{sort_ord}")
      end
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
        if(defined?(ActiveRecord::Relation) && klass.is_a?(ActiveRecord::Relation))
          klass.where([
            "#{search_field} #{SEARCH_OPERS[search_oper].first}",
            SEARCH_OPERS[search_oper].last.call(search_string)
          ])
        else
          klass.scoped(
            :conditions => [
              "#{search_field} #{SEARCH_OPERS[search_oper].first}",
              SEARCH_OPERS[search_oper].last.call(search_string)
            ]
          )
        end
      else
        klass
      end
    end

    # klass:: ActiveRecord::Base class or ActiveRecord::Relation
    # params:: Request params
    # fields:: Fields used within grid
    # Applies any filter restrictions to result set
    #
    # TODO: Currently this only supports AND'ing the filters. Need 
    # to add support for grabbing groupOp from parameters and using it for
    # joining query parameters. 
    def apply_filtering(klass, params, fields)
      rel = klass
      unless(params[:filters].blank?)
        filters = JSON.load(params[:filters])
        filters['rules'].each do |filter|
          field = discover_field(filter['field'], fields)
          oper = filter['op']
          raise ArgumentError.new("Invalid search operator received: #{oper}") unless SEARCH_OPERS.keys.include?(oper)
          data = filter['data']
          if(defined?(ActiveRecord::Relation) && rel.is_a?(ActiveRecord::Relation))
            rel = rel.where([
              "#{field} #{SEARCH_OPERS[oper].first}",
              SEARCH_OPERS[oper].last.call(data)
            ])
          else
            rel = rel.scoped(
              :conditions => [
                "#{field} #{SEARCH_OPERS[oper].first}",
                SEARCH_OPERS[oper].last.call(data)
              ]
            )
          end
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
          value = method.to_s.split('.').inject(row) do |result,meth|
            if(result.try(:respond_to?, meth))
              result.send(meth)
            else
              nil
            end
          end
          if(fields.is_a?(Hash) && fields[method][:formatter].is_a?(Proc))
            value = fields[method][:formatter].call(value, row)
          end
          hsh[method] = value
        end
        hsh
      end
      res
    end
  end
end

ActionController::Base.send :include, JqGridRails::Controller
