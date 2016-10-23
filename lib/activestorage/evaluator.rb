# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  class Evaluator
    include Singleton

    attr_accessor :activerecord
    attr_accessor :storage_scope

    def attribute(*args)
      activerecord.storage_attribute(storage_scope, *args)
    end

    def evaluate(&block)
      instance_eval(&block)
    end
  end
end
