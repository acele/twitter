module Typhoeus
  class Request

    # This module contains custom serializer.
    module Marshal

      # Return the important data needed to serialize this Request, except the
      # `on_complete` handler, since they cannot be marshalled.
      def marshal_dump
        (instance_variables - ['@on_complete', :@on_complete]).map do |name|
          [name, instance_variable_get(name)]
        end
      end

      # Load.
      def marshal_load(attributes)
        attributes.each { |name, value| instance_variable_set(name, value) }
      end
    end
  end
end
