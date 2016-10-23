# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :storages, instance_accessor: false, instance_predicate: false
      self.storages = {}
    end

    def reload
      self.class.storages.keys.each { |k| instance_variable_set("@attributes_cache_for_#{k}", nil) }
      super
    end

    module ClassMethods
      def storage_attribute(scope, attributes)
        attributes.each do |k, v|
          ActiveStorage.build_storage_attribute(self, scope, k, v)
        end
      end
    end
  end
end
