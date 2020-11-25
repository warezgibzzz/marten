require "./predicate/**"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          @@registry = {} of String => Base.class

          def self.register(predicate_klass : Base.class)
            @@registry[predicate_klass.predicate_name] = predicate_klass
          end

          def self.registry
            @@registry
          end

          register Contains
          register EndsWith
          register Exact
          register IContains
          register IEndsWith
          register IExact
          register IStartsWith
          register StartsWith
        end
      end
    end
  end
end