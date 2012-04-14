module JqGridRails
  # GridStructure acts as a container for the various jqgrid_rails elements. It is used to store
  # the grid's scopes, column data, and response options. These elements can then be used to 
  # generate the ultimate, grid, response and scope meant to be used in the controller
  class JqGridStructure
    # base_class:: name of model containing GridStructure (used to generate some grid defaults)
    # grid_name:: used to identify grid (convention is action_name_grid; eg: index_grid)
    def initialize(base_class, grid_name)
      @grid_name = grid_name
      @base_class = base_class
      @columns = []
      @scopes = []
      @response = {}
    end

    # Get scope (1st arg of grid_response) by merging @scopes together (first added is the base)
    def scope 
      scope = @scopes.first
      last_index = @scopes.length - 1
      1.upto(last_index) { |i| scope = scope.merge(@scopes[i]) }
      scope
    end

    # Returns response for grid (last argument in json grid_response call)
    def response
      @response
    end

    # Adds column info for later grid creation; arguments accepted are similar to Grid#add_column
    # Only adds column if the unique key (field_name) does not exist in the response hash
    # label:: label for grid column
    # field_name:: used during the grid response
    # opts:: hash containing :columns and :response keys to specify these options for column
    def add_column(label, field_name, opts = {})
      unless(@response.has_key?(field_name))
        @columns << { :label => label, :field_name => field_name, :column_opts => (opts[:columns] || {}) }
        @response[field_name] = opts[:response]
      end
    end

    # Remove grid element from columns and response based on field_name
    # field_name:: element to delete from columns and response
    def remove_column(field_name)
      @columns.delete_if { |col_hash| col_hash[:field_name] == field_name }
      @response.delete(field_name)
    end
    
    # Adds scope to be used in grid response 
    # scope:: scope to be merged with the rest in the array (array acts as a queue)
    # location:: optional location of scope (:first or :last (:last is default))
    def add_scope(scope, location = :last)
      insert_location = (location.to_sym == :first)? 0 : -1
      @scopes.insert(insert_location, scope)
    end

    # Generates grid that will be used in controller
    # custom_grid_options:: hash that will be added to default options for grid
    def create_grid(custom_grid_options = {})
      grid = JqGridRails::JqGrid.new(@grid_name, default_options(custom_grid_options))
      @columns.each { |c| grid.add_column(c[:label], c[:field_name], c[:column_opts]) }
      grid
    end

    # Main grid options (last arg or Grid#new); contains reasonable defaults that may be overriden
    # options:: custom options to override any defaults or to add other options not specified
    def default_options(options = {})
      tbl = @base_class.table_name
      { :caption => "#{@base_class.to_s.pluralize} List",
        :url => "/#{tbl}/",
        :ondbl_click_row => { :url => "#{tbl.singularize}_path".to_sym},
        :link_toolbar => true,
        :filter_toolbar => true,

        :sortname => "#{tbl}.id",
        :sortorder => "desc",

        :height => '100%',
        :width => '100%',
        :autowidth => true,
        :ignore_case => true,
        
        :row_id => :id,
        :row_num => 50,
        :pager => true,
        :multiselect => true }.merge(options)
    end

  end
end


