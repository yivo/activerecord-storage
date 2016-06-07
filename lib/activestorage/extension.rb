# frozen_string_literal: true
module ActiveStorage
  module Extension
    extend ActiveSupport::Concern

    included do
      class_attribute :storage_names,                        instance_accessor: false, instance_predicate: false
      class_attribute :storage_attribute_names,              instance_accessor: false, instance_predicate: false
      class_attribute :storage_attributes_type_mapping,      instance_accessor: false, instance_predicate: false
      class_attribute :storage_names_mapping,                instance_accessor: false, instance_predicate: false
      class_attribute :storage_attributes_readonly_mapping,  instance_accessor: false, instance_predicate: false

      self.storage_names                        = []
      self.storage_attribute_names              = []
      self.storage_attributes_type_mapping      = {}
      self.storage_names_mapping                = {}
      self.storage_attributes_readonly_mapping  = {}
    end

    def read_storage_attribute(attr)
      send("read_attribute_from_#{self.class.storage_name_for(attr)}", attr)
    end

    def write_storage_attribute(attr, value)
      send("write_attribute_to_#{self.class.storage_name_for(attr)}", attr, value)
    end

    def [](name)
      if self.class.has_storage_attribute?(name)
        read_storage_attribute(name)
      else
        super
      end
    end

    # ActiveRecord 4.2.1
    def _read_attribute(name)
      if self.class.has_storage_attribute?(name)
        read_storage_attribute(name)
      else
        super
      end
    end

    def []=(name, value)
      if self.class.has_storage_attribute?(name)
        write_storage_attribute(name, value)
      else
        super
      end
    end

    def attributes
      self.class.storage_attribute_names.each_with_object(super) do |name, attrs|
        attrs[name.to_s] = read_storage_attribute(name)
      end
    end

    def typecast_storage_attribute(attr, type, value)
      case type
        when :string          then value.is_a?(String)  ? value : value.to_s
        when :integer         then value.is_a?(Integer) ? value : value.to_i
        when :decimal, :float then value.is_a?(Float)   ? value : value.to_f
        when :boolean         then !!value
        else value
      end
    end

    module ClassMethods
      def has_storage_attribute?(name)
        self.storage_attributes_type_mapping.key?(name.kind_of?(Symbol) ? name : name.to_sym)
      end

      def readonly_storage_attribute?(name)
        self.storage_attributes_readonly_mapping[name.kind_of?(Symbol) ? name : name.to_sym]
      end

      def storage_name_for(name)
        self.storage_names_mapping[name.kind_of?(Symbol) ? name : name.to_sym]
      end

      def storage_accessor(storage_attr, accessors)
        storage_attr = storage_attr.to_sym

        accessors.each do |k, v|
          attr = k.to_sym
          type, readonly = v.kind_of?(Hash) ?
            [v.fetch(:type), v.fetch(:readonly, false)] :
            [v.to_sym, false]

          self.storage_attribute_names += [attr]

          self.storage_attributes_type_mapping =
            self.storage_attributes_type_mapping.merge(attr => type)

          self.storage_attributes_readonly_mapping =
            self.storage_attributes_readonly_mapping.merge(attr => readonly)

          self.storage_names_mapping =
            self.storage_names_mapping.merge(attr => storage_attr)

          class_eval <<-BODY, __FILE__, __LINE__ + 1
            def #{attr}
              read_attribute_from_#{storage_attr}(:#{attr})
            end

            def #{attr}=(value)
              write_attribute_to_#{storage_attr}(:#{attr}, value)
            end

            def #{attr}?
              #{attr}.present?
            end

            alias #{attr}_present? #{attr}?

            def #{attr}_blank?
              #{attr}? == false
            end

            def #{attr}_nil?
              #{attr}.nil?
            end

            # (1,2,3) - Methods for compatibility with gems expecting the ActiveModel::Dirty API.

            # 1
            def #{attr}_was
              nil
            end

            # 2
            def #{attr}_changed?
              #{attr}_nil? == false
            end

            # 3
            def #{attr}_will_change!
              # no-op
            end
          BODY
        end
      end
    end
  end
end
