# frozen_string_literal: true

module CheckstyleReports::Entity
  class FoundFile
    attr_reader :path # String
    attr_reader :errors # Array<FoundError>

    def initialize(node)
      raise "Wrong node was passed. expected file but #{node.name}" if node.name != "file"

      @path = node.attributes["name"]
      @errors = node.elements.each("error") { |n| FoundError.new(n) }
    end
  end
end
