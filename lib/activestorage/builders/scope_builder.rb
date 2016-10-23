# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  class << self
    def build_storage_scope(activerecord, scope, coder)
      activerecord.serialize(scope, coder)

      activerecord.storages[scope.to_sym] = {
        scope:      scope.to_sym,
        attributes: {},
        typecaster: ActiveStorage::Typecaster.new }

      activerecord.class_eval <<-BODY, __FILE__, __LINE__ + 1
        def read_attribute_from_#{scope}(attribute)
          attr_sym = attribute.to_sym
          attr_str = attribute.kind_of?(String) ? attribute : attribute.to_s
          cache    = attributes_cache_for_#{scope}

          if cache.key?(attr_sym)
            cache[attr_sym]
          else
            type  = self.class.storages[:#{scope}][:attributes].fetch(attr_sym)[:type]
            value = typecast_attribute_from_#{scope}(attr_sym, type, #{scope}[attr_str])
            cache[attr_sym] = value
          end
        end

        def write_attribute_to_#{scope}(attribute, value)
          attr_sym = attribute.to_sym
          attr_str = attribute.kind_of?(String) ? attribute : attribute.to_s

          attributes_cache_for_#{scope}.delete(attr_sym)
          #{scope}[attr_str] = value
        end

        def typecast_attribute_from_#{scope}(attribute, type, value)
          # As is (no typecast)
          if type.nil?
            value
          else
            self.class.storages[:#{scope}][:typecaster].typecast_attribute(attribute, type, value)
          end
        end

        def attributes_cache_for_#{scope}
          @attributes_cache_for_#{scope} ||= {}
        end

        protected :read_attribute_from_#{scope}
        protected :write_attribute_to_#{scope}
        protected :typecast_attribute_from_#{scope}
      BODY
    end
  end
end
