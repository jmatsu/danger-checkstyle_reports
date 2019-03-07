# frozen_string_literal: true

require "pathname"
require "rexml/document"

require_relative "gem_version"

require_relative "lib/severity"

require_relative "entity/found_error"
require_relative "entity/found_file"

module Danger
  # Comment checkstyle reports.
  #
  # You need to specify the project root. You don't need do it if it is same with git's top-level path.
  #
  #         checkstyle_reports.root_path=/path/to/project
  #
  # @example Report errors whose files have been modified (By default)
  #
  #         checkstyle_reports.report("app/build/checkstyle/checkstyle.xml"[, modified_files_only: true])
  #
  # @example Report all errors in app/build/checkstyle/checkstyle.xml
  #
  #         checkstyle_reports.report("app/build/checkstyle/checkstyle.xml", modified_files_only: false)
  #
  # @see  Jumpei Matsuda/danger-checkstyle_reports
  # @tags android, checkstyle
  #
  class DangerCheckstyleReports < Plugin
    REPORT_METHODS = %i(message warn fail).freeze

    # *Optional*
    # An absolute path to a root.
    # To comment errors to VCS, this needs to know relative path of files from the root.
    #
    # @return [String] the root path of git repository by default.
    attr_accessor :root_path

    # *Optional*
    # Create inline comment if true.
    #
    # @return [Boolean] true by default
    attr_accessor :inline_comment

    # *Optional*
    # minimum severity to be reported (inclusive)
    #
    # @return [String, Symbol] error by default
    attr_accessor :min_severity

    # *Optional*
    # Set report method
    #
    # @return [String, Symbol] error by default
    attr_accessor :report_method

    # The array of files which include at least one error
    #
    # @return [Array<String>] a collection of relative paths
    attr_reader :reported_files

    # Report errors based on the given xml file if needed
    #
    # @param [String] xml_file which contains checkstyle results to be reported
    # @param [Boolean] modified_files_only which is a flag to filter out non-added/non-modified files
    # @param [Boolean] modified_lines_only only report modified lines
    # @return [void] void
    def report(xml_file, modified_files_only: true, modified_lines_only: true)
      raise "File path must not be empty" if xml_file.empty?
      raise "File not found" unless File.exist?(xml_file)

      @min_severity = (min_severity || :error).to_sym
      @report_method = (report_method || :fail).to_sym

      raise "Unknown severity found" unless CheckstyleReports::Severity::VALUES.include?(min_severity)
      raise "Unknown report method" unless REPORT_METHODS.include?(report_method)

      files = parse_xml(xml_file, modified_files_only)

      @reported_files = files.map(&:relative_path)

      do_comment(files, modified_lines_only) unless files.empty?
    end

    private

    # find the from and to positions of a chunk in a file diff
    # adapted from https://github.com/danger/danger/blob/master/lib/danger/request_sources/github/github.rb#L371
    #
    # @param [Array<String>] diff_lines lines in chunk
    # @param [String] filename the name of the file
    # @return [Map] map of to and from position in the source file
    def find_position_in_diff(diff_lines, filename)
      range_header_regexp = /@@ -([0-9]+)(,([0-9]+))? \+(?<start>[0-9]+)(,(?<end>[0-9]+))? @@.*/
      file_header_regexp = %r{^diff --git a/.*}

      pattern = "+++ b/" + filename + "\n"
      file_start = diff_lines.index(pattern)

      return nil if file_start.nil?

      position = -1
      file_line = nil

      diff_lines.drop(file_start).each do |line|
        # If the line has `No newline` annotation, position need increment
        if line.eql?("\\ No newline at end of file\n")
          position += 1
          next
        end
        # If we found the start of another file diff, we went too far
        break if line.match file_header_regexp

        match = line.match range_header_regexp

        # file_line is set once we find the hunk the line is in
        # we need to count how many lines in new file we have
        # so we do it one by one ignoring the deleted lines
        if !file_line.nil? && !line.start_with?("-")
          file_line += 1
        end

        # We need to count how many diff lines are between us and
        # the line we're looking for
        position += 1

        next unless match

        range_start = match[:start].to_i
        if match[:end]
          range_end = match[:end].to_i + range_start
        else
          range_end = range_start
        end

        file_line = range_start

        return { from: range_start, to: range_end } unless file_line.nil?
      end

      { from: position, to: position } unless file_line.nil?
    end

    # Parse the given xml file and apply filters if needed
    #
    # @param [String] file_path which is a check-style xml file
    # @param [Boolean] modified_files_only a flag to determine to apply added/modified files-only filter
    # @return [Array<FoundFile>] filtered files
    def parse_xml(file_path, modified_files_only)
      prefix = root_path || `git rev-parse --show-toplevel`.chomp

      files = []

      REXML::Document.new(File.read(file_path)).root.elements.each("file") do |f|
        files << CheckstyleReports::Entity::FoundFile.new(f, prefix: prefix)
      end

      if modified_files_only
        target_files = git.modified_files + git.added_files

        files.select! { |f| target_files.include?(f.relative_path) }
      end

      files.reject! { |f| f.errors.empty? }
      files
    end

    # Comment errors based on the given xml file to VCS
    #
    # @param [Array<FoundFile>] files which contains checkstyle results to be reported
    # @param [Boolean] modified_lines_only only report modified lines
    # @return [void] void
    def do_comment(files, modified_lines_only)
      base_severity = CheckstyleReports::Severity.new(min_severity)

      files.each do |f|
        f.errors.each do |e|
          # check severity
          next unless base_severity <= e.severity

          difffile = git.diff_for_file(f.relative_path)
          if modified_lines_only && !difffile.nil?
            linearray = difffile.patch.split("\n").map { |l| l + "\n" }
            linenumbers = find_position_in_diff(linearray, difffile.path)
            next unless e.line_number >= linenumbers[:from] && e.line_number <= linenumbers[:to]
          end

          if inline_comment
            self.public_send(report_method, e.html_unescaped_message, file: f.relative_path, line: e.line_number)
          else
            self.public_send(report_method, "#{f.relative_path}: #{e.html_unescaped_message} at #{e.line_number}")
          end
        end
      end
    end
  end
end
