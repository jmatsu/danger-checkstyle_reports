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

    def initialize(node, prefix:)
      raise "Wrong node was passed. expected file but #{node.name}" if node.name != "file"

      if prefix.end_with?(file_separator)
        @prefix = prefix
      else
        @prefix = prefix + file_separator
      end

      @path = node.attributes["name"]
      @errors = node.elements.each("error") { |n| FoundError.new(n) }
    end

    def relative_path
      @relative_path ||= begin
        if Pathname.new(path).absolute?
          path.delete_prefix(@prefix)
        else
          path
        end
      end
    end

    private

    def file_separator
      File::ALT_SEPARATOR || File::SEPARATOR
    end
  end
end
