$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jqgrid_rails/version'
Gem::Specification.new do |s|
  s.name = 'jqgrid_rails'
  s.version = JqGridRails::VERSION
  s.summary = 'jqGrid for Rails'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'http://github.com/ctisol/jqgrid_rails'
  s.description = 'jqGrid for Rails'
  s.require_path = 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE.rdoc', 'CHANGELOG.rdoc']
  s.add_dependency 'rails', '>= 2.3'
  s.files = %w(README.rdoc CHANGELOG.rdoc) + Dir.glob("{app,files,lib,rails}/**/*")
end
