require 'active_record'
require 'active_support/all'

require 'activestorage/migration'

class ActiveRecord::Base
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

  def self.storage(storage_attr, type: nil, &block)
    storage_attr = storage_attr.to_sym

    if type && !storage_names.include?(storage_attr)
      serialize(storage_attr, type)
      self.storage_names += [storage_attr]
      class_eval <<-BODY, __FILE__, __LINE__ + 1
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
      BODY
    end

    if block
      @storage_evaluator ||= StorageEvaluator.new(self)
      @storage_evaluator.attribute = storage_attr
      @storage_evaluator.instance_eval(&block)
    end
  end

  def self.has_storage_attribute?(name)
    self.storage_attributes_type_mapping.key?(name.kind_of?(Symbol) ? name : name.to_sym)
  end

  def self.readonly_storage_attribute?(name)
    self.storage_attributes_readonly_mapping[name.kind_of?(Symbol) ? name : name.to_sym]
  end

  def self.storage_name_for(name)
    self.storage_names_mapping[name.kind_of?(Symbol) ? name : name.to_sym]
  end

  def self.storage_accessor(storage_attr, accessors)
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
      when :identifier, :integer  then value.to_i
      when :string                then value.to_s
      when :decimal, :float       then value.to_f
      when :boolean               then !!value
      else value
    end
  end

  class StorageEvaluator
    attr_accessor :attribute

    def initialize(model_class)
      @model_class = model_class
    end

    def accessor(accessors)
      @model_class.storage_accessor(attribute, accessors)
    end
  end
end