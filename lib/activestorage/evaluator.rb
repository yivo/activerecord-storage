module ActiveStorage
  class Evaluator
    include Singleton

    attr_accessor :storage_attribute
    attr_accessor :active_record

    def accessor(accessors)
      @active_record.storage_accessor(@storage_attribute, accessors)
    end

    def evaluate(&block)
      instance_eval(&block)
    end
  end
end