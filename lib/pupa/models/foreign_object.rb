module Pupa
  # A minimal model for a foreign object.
  class ForeignObject
    extend Forwardable
    include Concerns::IndifferentAccess

    attr_reader :attributes, :foreign_keys

    def_delegators :@attributes, :[], :[]=

    def initialize(properties = {})
      hash = symbolize_keys(properties)
      value = hash.delete(:foreign_keys) || {}
      @attributes = hash.merge(value)
      @foreign_keys = value.keys
    end

    def to_h
      {}.tap do |hash|
        attributes.each do |property,value|
          if value == false || value.present?
            hash[property] = value
          end
        end
      end
    end
  end
end
