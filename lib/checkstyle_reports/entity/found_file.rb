# frozen_string_literal: true

module CheckstyleReports::Entity
  class FoundFile
    # A absolute path to this file
    #
    # @return [String]
    attr_reader :path

    # A relative path to this file
    #
    # @return [String]
    attr_reader :relative_path

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

      name = node.attributes["name"]

      if Pathname.new(name).absolute?
        raise "Bad prefix was found for #{name}. #{@prefix} was a prefix." unless name.start_with?(@prefix)

        # Use delete_prefix when min support version becomes ruby 2.5
        @relative_path = name[@prefix.length, name.length - @prefix.length]
      else
        @relative_path = name
      end

      @path = @prefix + @relative_path

      @path = node.attributes["name"]
      @errors = []

      node.elements.each("error") { |n| @errors << FoundError.new(n) }
    end

    private

    def file_separator
      File::ALT_SEPARATOR || File::SEPARATOR
    end
  end
end
