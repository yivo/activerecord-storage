# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  module Migration
    def storage(*args)
      options = args.extract_options!.reverse_merge!(null: false, default: {}.to_json)
      args.each { |name| column(name, :text, options) }
    end
  end
end
