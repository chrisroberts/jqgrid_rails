= JqGridRails Quick Reference

== Assocation Values

=== Accessing assocations

  @grid.add_column('Bulletin Title', 'bulletin.title')

  format.json do
    grid_response(Bulletin, params, ['bulletin.title'])
  end

=== Ordering properly on assocations

  @grid.add_column('Bulletin Title', 'bulletin.title')

  format.json do
    grid_response(Bulletin, params, {
      'bulletin.title' => {
        :order => 'my_bulletins.title'
      }
    })
  end

== Value Formatting

=== Providing Ruby based formatting on values

  format.json do
    grid_response(User, params, {
      :username => nil,
      'core_company.name' => {
        :formatter => lambda{|value| value.to_s.upcase}
      },
      :email
    })
  end

=== Simple value mapping (applied client side)

  @grid.add_column('Active', 'active_user', :map_values => {true => 'Active', false => 'Inactive'})

== Events

=== Ajax call when row is single clicked

  @grid = JqGridRails::JqGrid.new('users_table',
    :row_id => :id,
    :on_cell_select => {:url => :users_path, :remote => true, :args => {:company_id => company.id}}
  )

=== Ajax call when row is double clicked

  @grid = JqGridRails::JqGrid.new('users_table',
    :row_id => :id,
    :ondbl_click_row => {:url => :users_path, :remote => true, :args => {:company_id => company.id}}
  )

== Add Toolbar Button

  @grid.link_toolbar_add(
    :name => 'Edit',
    :url => :edit_user_path,
    :remote => true,
    :class => 'custom-css-class'
  )

The :remote key will turn AJAX calls off/on. Both AJAX and non-AJAX calls are GET requests

