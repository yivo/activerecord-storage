# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  class << self
    def build_storage_attribute(activerecord, scope, attribute, type)
      activerecord.storages[scope.to_sym][:attributes][attribute.to_sym] = { type: type }

      activerecord.class_eval <<-BODY, __FILE__, __LINE__ + 1
        def #{attribute}
          read_attribute_from_#{scope}(:#{attribute})
        end

        def #{attribute}=(value)
          write_attribute_to_#{scope}(:#{attribute}, value)
        end

        def #{attribute}?
          #{attribute}.present?
        end

        alias #{attribute}_present? #{attribute}?

        def #{attribute}_blank?
          !#{attribute}?
        end

        def #{attribute}_nil?
          #{attribute}.nil?
        end

        # (1,2,3) - Methods for compatibility with gems expecting the ActiveModel::Dirty API.

        # 1
        def #{attribute}_was
          nil
        end

        # 2
        def #{attribute}_changed?
          !#{attribute}_nil?
        end

        # 3
        def #{attribute}_will_change!
          # no-op
        end
      BODY
    end
  end
end
