# frozen_string_literal: true

module CheckstyleReports::Entity
  class FoundError
    # A detected line number
    #
    # @return [Fixnum]
    attr_reader :line_number

    # A detected column
    # Optionality depends on 'source'
    #
    # @return [Fixnum, nil]
    attr_reader :column_number

    # A severity of this error
    #
    # @return [String]
    attr_reader :severity

    # An error message
    #
    # @return [String]
    attr_reader :html_unescaped_message

    # A name of a detector
    #
    # @return [String]
    attr_reader :source # String

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
