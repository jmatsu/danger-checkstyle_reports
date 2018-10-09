# frozen_string_literal: true

require "pathname"
require "rexml/document"

require_relative "gem_version"

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
    REPORT_LEVELS = %i(message warn error).freeze

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
    attr_accessor :report_level

    # The number of reported errors
    #
    # @return [Fixnum] non-negative value
    attr_reader :error_count

    # The array of files which include at least one error
    #
    # @return [Array<String>] a collection of relative paths
    attr_reader :reported_files

    # Report errors based on the given xml file if needed
    #
    # @param [String] xml_file which contains checkstyle results to be reported
    # @param [Boolean] modified_files_only which is a flag to filter out non-modified files
    # @return [void] void
    def report(xml_file, modified_files_only: true)
      raise "File path must not be blank" if xml_file.blank?
      raise "File not found" unless File.exist?(xml_file)

      @min_severity ||= :error
      @report_level ||= :error

      raise "Report level must be in #{REPORT_LEVELS}" unless REPORT_LEVELS.include?(report_level)

      files = parse_xml(xml_file, modified_files_only)

      @error_file_count = files.count
      @reported_files = files.map(&:relative_path)

      do_comment(files) unless files.empty?
    end

    private

    # Parse the given xml file and apply filters if needed
    #
    # @param [String] file_path which is a check-style xml file
    # @param [Boolean] modified_files_only a flag to determine to apply modified files-only filter
    # @return [Array<FoundFile>] filtered files
    def parse_xml(file_path, modified_files_only)
      prefix = root_path || `git rev-parse --show-toplevel`.chomp

      files = REXML::Document.new(File.read(file_path)).root.each("file") do |f|
        FoundFile.new(f, prefix: prefix)
      end

      if modified_files_only
        files.select! { git.modified_files.include?(f.relative_path) }
      end

      files.reject! { |f| f.errors.zero? }
      files
    end

    # Comment errors based on the given xml file to VCS
    #
    # @param [Array<FoundFile>] files which contains checkstyle results to be reported
    # @return [void] void
    def do_comment(files)
      files.each do |f|
        f.errors.each do |e|
          # check severity
          next if e.severity < min_severity

          if inline_comment
            self.public_send(report_level, e.html_unescaped_message, file: f.relative_path, line: e.line_number)
          else
            self.public_send(report_level, "#{e.relative_path} : #{e.html_unescaped_message} at #{e.line_number}")
          end
        end
      end
    end
  end
end
