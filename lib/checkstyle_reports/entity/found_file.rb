# frozen_string_literal: true

module CheckstyleReports::Entity
  class FoundFile

    # A file path to this file
    #
    # @return [String]
    attr_reader :path

    # Errors which were detected in this file
    #
    # @return [Array<FoundError>]
    attr_reader :errors

    def initialize(node)
      raise "Wrong node was passed. expected file but #{node.name}" if node.name != "file"

      @path = node.attributes["name"]
      @errors = node.elements.each("error") { |n| FoundError.new(n) }
    end

    def relative_path(prefix:)
      @relative_path ||= begin
        if Pathname.new(path).absolute?
          path.delete_prefix(prefix)
        else
          path
        end
      end
    end
  end
end
