# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  module Migration
    def storage(*args)
      options = args.extract_options!.reverse_merge!(null: false, limit: 2**10-1, default: {}.to_json)
      args.each { |name| column(name, :string, options) }
    end
  end
end
