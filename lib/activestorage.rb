require 'active_record'
require 'active_support/all'
require 'oj'
require 'oj_mimic_json'

require 'activestorage/macro'
require 'activestorage/extension'
require 'activestorage/evaluator'
require 'activestorage/column_types'

module ActiveRecord
  Base.include ActiveStorage::Macro
  ConnectionAdapters::TableDefinition.include ActiveStorage::ColumnTypes
end