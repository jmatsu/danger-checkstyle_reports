# frozen_string_literal: true

module CheckstyleReports::Entity
  class FoundError
    attr_reader :line_number # Fixnum
    attr_reader :column_number # Optional Fixnum
    attr_reader :severity, :html_unescaped_message, :source # String

    def initialize(node)
      raise "Wrong node was passed. expected error but #{node.name}" if node.name != "error"

      attributes = node.attributes

      @line_number = attributes["line"].to_i
      @column_number = attributes["column"]&.to_i
      @severity = attributes["severity"]
      @html_unescaped_message = attributes["message"] # unescape implicitly
      @source = attributes["source"]
    end
  end
end
