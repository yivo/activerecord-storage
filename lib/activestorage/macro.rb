module ActiveStorage
  module Macro
    extend ActiveSupport::Concern

    module ClassMethods
      def storage(storage_attr, type: Oj, &block)

        unless self < ActiveStorage::Extension
          include ActiveStorage::Extension
        end

        storage_attr = storage_attr.to_sym

        unless storage_names.include?(storage_attr)
          serialize(storage_attr, type)
          self.storage_names += [storage_attr]
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{storage_attr}_cache
              @#{storage_attr}_cache ||= {}
            end

            def read_attribute_from_#{storage_attr}(name)
              if name.kind_of?(Symbol)
                name     = name.to_s
                name_sym = name
              else
                name_sym = name.to_sym
              end

              if #{storage_attr}_cache.key?(name_sym)
                #{storage_attr}_cache[name_sym]

              elsif self[:#{storage_attr}].key?(name)
                #{storage_attr}_cache[name_sym] = begin
                  type  = self.class.storage_attributes_type_mapping[name_sym]
                  value = self[:#{storage_attr}][name]
                  typecast_storage_attribute(name_sym, type, value)
                end
              else
                nil
              end
            end

            def write_attribute_to_#{storage_attr}(name, value)
              if name.kind_of?(Symbol)
                name     = name.to_s
                name_sym = name
              else
                name_sym = name.to_sym
              end

              if self[:#{storage_attr}][name].nil? == false && self.class.readonly_storage_attribute?(name_sym)
                raise 'Attribute ' + name + ' is readonly!'
              else
                #{storage_attr}_cache.delete(name_sym)
                self[:#{storage_attr}][name] = value
              end
            end

            protected :#{storage_attr}_cache
            protected :read_attribute_from_#{storage_attr}
            protected :write_attribute_to_#{storage_attr}
          RUBY
        end

        if block
          evaluator = ActiveStorage::Evaluator.instance
          evaluator.active_record     = self
          evaluator.storage_attribute = storage_attr
          evaluator.evaluate(&block)
        end
      end
    end
  end
end