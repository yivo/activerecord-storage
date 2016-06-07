# frozen_string_literal: true
module ActiveStorage
  module ColumnTypes
    def storage(*args)
      options = args.extract_options!.reverse_merge!(null: false, default: {}.to_json, limit: 2**9-1)
      args.each { |name| column(name, :string, options) }
    end
  end
end
