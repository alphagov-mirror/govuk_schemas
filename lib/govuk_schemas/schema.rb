module GovukSchemas
  class Schema
    CONTENT_SCHEMA_DIR = ENV["CONTENT_SCHEMA_DIR"] || "../govuk-content-schemas"

    # Find a schema by name
    #
    # @param schema_name [String] Name of the schema/format
    # @param schema_type [String] The type: frontend, backend or links
    def self.find(schema_name, schema_type:)
      schema_type = "publisher_v2" if schema_type == "publisher"
      file_path = "#{CONTENT_SCHEMA_DIR}/dist/formats/#{schema_name}/#{schema_type}/schema.json"
      JSON.parse(File.read(file_path))
    end

    # Return all schemas in a hash, keyed by schema name
    def self.all
      Dir.glob("#{CONTENT_SCHEMA_DIR}/dist/**/*.json").reduce({}) do |hash, file_path|
        hash[file_path] = JSON.parse(File.read(file_path))
        hash
      end
    end
  end
end
