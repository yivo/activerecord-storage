# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  module Macro
    extend ActiveSupport::Concern

    module ClassMethods
      def storage(scope, coder = nil, &block)

        unless self < ActiveStorage::Extension
          include ActiveStorage::Extension
        end

        unless storages[scope.to_sym]
          ActiveStorage.build_storage_scope(self, scope, coder || (defined?(Oj) ? Oj : JSON))
        end

        if block
          evaluator = ActiveStorage::Evaluator.instance
          evaluator.activerecord  = self
          evaluator.storage_scope = scope
          evaluator.evaluate(&block)
        end
      end
    end
  end
end
