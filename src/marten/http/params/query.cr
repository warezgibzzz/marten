module Marten
  module HTTP
    module Params
      # Represents a set of GET parameters, extracted from a request's query string.
      class Query < Base
        # :nodoc:
        alias Value = String

        # :nodoc:
        alias Values = Array(Value)

        # :nodoc:
        alias RawHash = Hash(String, Values)

        def initialize(@params : RawHash)
          if !Marten.settings.request_max_parameters.nil? && size > Marten.settings.request_max_parameters.as(Int32)
            raise Errors::TooManyParametersReceived.new("The number of parameters that were received is too large")
          end
        end
      end
    end
  end
end