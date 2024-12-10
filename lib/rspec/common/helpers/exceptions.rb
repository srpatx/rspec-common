module RSpec::Common
  module Helpers
    module Exceptions
      def fallible(suppress: :runtime)
        raise ArgumentError unless %i[none runtime all].include?(suppress)

        yield
      rescue
        raise if suppress == :none
      rescue Exception # standard:disable Lint/RescueException
        raise unless suppress == :all
      end
    end
  end
end
