require "govuk_schemas/random"
require "govuk_schemas/random_item_generator"
require "json-schema"
require "json"

module GovukSchemas
  class RandomExample
    # Returns a new `GovukSchemas::RandomExample` object.
    #
    # For example:
    #
    #     schema = GovukSchemas::Schema.find(frontend_schema: "detailed_guide")
    #     GovukSchemas::RandomExample.new(schema: schema).payload
    #
    # @param [Hash] schema A JSON schema.
    # @return [GovukSchemas::RandomExample]
    def initialize(schema:)
      @schema = schema
      @random_generator = RandomItemGenerator.new(schema: schema)
    end

    # Returns a new `GovukSchemas::RandomExample` object.
    #
    # Example without block:
    #
    #      GovukSchemas::RandomExample.for_schema(frontend_schema: "detailed_guide")
    #      # => {"base_path"=>"/e42dd28e", "title"=>"dolor est...", "publishing_app"=>"elit"...}
    #
    # Example with block:
    #
    #      GovukSchemas::RandomExample.for_schema(frontend_schema: "detailed_guide") do |payload|
    #        payload.merge('base_path' => "Test base path")
    #      end
    #      # => {"base_path"=>"Test base path", "title"=>"dolor est...", "publishing_app"=>"elit"...}
    #
    # @param schema_key_value [Hash]
    # @param [Block] the base payload is passed inton the block, with the block result then becoming
    #   the new payload. The new payload is then validated. (optional)
    # @return [GovukSchemas::RandomExample]
    # @param [Block] the base payload is passed inton the block, with the block result then becoming
    #   the new payload. The new payload is then validated. (optional)
    def self.for_schema(schema_key_value, &block)
      schema = GovukSchemas::Schema.find(schema_key_value)
      GovukSchemas::RandomExample.new(schema: schema).payload(&block)
    end

    # Return a content item merged with a hash and with the excluded fields removed.
    # If the resulting content item isn't valid against the schema an error will be raised.
    #
    # Example without block:
    #
    #      generator.payload
    #      # => {"base_path"=>"/e42dd28e", "title"=>"dolor est...", "publishing_app"=>"elit"...}
    #
    # Example with block:
    #
    #      generator.payload do |payload|
    #        payload.merge('base_path' => "Test base path")
    #      end
    #      # => {"base_path"=>"Test base path", "title"=>"dolor est...", "publishing_app"=>"elit"...}
    #
    # @param [Block] the base payload is passed inton the block, with the block result then becoming
    #   the new payload. The new payload is then validated. (optional)
    # @return [Hash] A content item
    # @raise [GovukSchemas::InvalidContentGenerated]
    def payload
      payload = @random_generator.payload
      # ensure the base payload is valid
      errors = validation_errors_for(payload)
      raise InvalidContentGenerated, error_message(payload, errors) if errors.any?

      if block_given?
        payload = yield(payload)
        # check the payload again after customisation
        errors = validation_errors_for(payload)
        raise InvalidContentGenerated, error_message(payload, errors, true) if errors.any?
      end

      payload
    end

  private

    def validation_errors_for(item)
      JSON::Validator.fully_validate(@schema, item, errors_as_objects: true)
    end

    def error_message(item, errors, customised = false)
      details = <<~ERR
        Validation errors:
        --------------------------

        #{JSON.pretty_generate(errors)}

        Generated payload:
        --------------------------

        #{JSON.pretty_generate([item])}
      ERR

      if customised
        <<~ERR
          The content item you are trying to generate is invalid against the schema.
          The item was valid before being customised.

          #{details}
        ERR
      else
        <<~ERR
          An invalid content item was generated.

          This probably means there's a bug in the generator that causes it to output
          invalid values. Below you'll find the generated payload, the validation errors
          and the schema that was used.

          #{details}
        ERR
      end
    end
  end
end
