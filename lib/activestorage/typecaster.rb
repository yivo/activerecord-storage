# encoding: utf-8
# frozen_string_literal: true

module ActiveStorage
  class Typecaster
    class TypeError < StandardError

    end

    def typecast_attribute(attribute, type, value)
      unless value.nil?
        case type
          when :string  then string_attribute(attribute, type, value)
          when :integer then integer_attribute(attribute, type, value)
          when :float   then float_attribute(attribute, type, value)
          when :decimal then decimal_attribute(attribute, type, value)
          when :boolean then boolean_attribute(attribute, type, value)
          else          raise TypeError, "Unknown type: #{type.inspect}"
        end
      end
    end

  protected
    def string_attribute(attribute, type, value)
      value.kind_of?(String) ? value : value.to_s
    end

    def integer_attribute(attribute, type, value)
      case value
        when Numeric    then value.to_i
        when TrueClass  then 1
        when FalseClass then 0
        else value.to_s.to_i
      end
    end

    def float_attribute(attribute, type, value)
      case
        when Numeric then value.to_f
        else value.to_s.to_f
      end
    end

    def decimal_attribute(attribute, type, value)
      float_attribute(attribute, type, value)
    end

    def boolean_attribute(attribute, type, value)
      !!value
    end
  end
end
