# encoding: utf-8
# frozen_string_literal: true

require 'active_support/concern'
require 'active_record'

require 'activestorage/macro'
require 'activestorage/extension'
require 'activestorage/evaluator'
require 'activestorage/builders/attribute_builder'
require 'activestorage/builders/scope_builder'
require 'activestorage/typecaster'
require 'activestorage/migration'

class ActiveRecord::Base
  include ActiveStorage::Macro
end

class ActiveRecord::ConnectionAdapters::TableDefinition
  include ActiveStorage::Migration
end
