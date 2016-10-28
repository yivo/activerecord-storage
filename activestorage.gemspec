# encoding: utf-8
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name            = 'activestorage'
  s.version         = '1.0.2'
  s.authors         = ['Yaroslav Konoplov']
  s.email           = ['eahome00@gmail.com']
  s.summary         = 'Better ActiveRecord::Store'
  s.description     = 'Better ActiveRecord::Store'
  s.homepage        = 'http://github.com/yivo/activestorage'
  s.license         = 'MIT'

  s.executables     = `git ls-files -z -- bin/*`.split("\x0").map{ |f| File.basename(f) }
  s.files           = `git ls-files -z`.split("\x0")
  s.test_files      = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
  s.require_paths   = ['lib']

  s.add_dependency 'activesupport', '>= 3.0', '< 6.0'
  s.add_dependency 'activerecord',  '>= 3.0', '< 6.0'
end
