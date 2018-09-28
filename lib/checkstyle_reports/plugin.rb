# frozen_string_literal: true

require "pathname"
require "rexml/document"

require_relative "gem_version"

require_relative "entity/found_error"
require_relative "entity/found_file"

module Danger
  # Show stats of your apk file.
  # By default, it's done using apkanalyzer in android sdk.
  #
  # You need to specify the project root. You don't need do it if it is same with git's toplevel path.
  #
  #         checkstyle_reports.root_path=/path/to/project
  #
  # @example Report errors in app/build/checkstyle/checkstyle.xml
  #
  #         checkstyle_reports.report("app/build/checkstyle/checkstyle.xml")
  #
  # @see  Jumpei Matsuda/danger-apkstats
  # @tags android, apk_stats
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

    # Report errors based on the given xml file if needed
    #
    # @param [String] xml_file which contains checkstyle results to be reported
    # @return [void] void
    def report(xml_file)
      raise "File path must not be blank" if xml_file.blank?
      raise "File not found" unless File.exist?(xml_file)

      @min_severity ||= :error
      @report_level ||= :error

      raise "Report level must be in #{REPORT_LEVELS}" unless REPORT_LEVELS.include?(report_level)

      prefix = root_path || `git rev-parse --show-toplevel`.chomp

      files = REXML::Document.new(File.read(xml_file)).root.each("file") do |f|
        FoundFile.new(f, prefix: prefix)
      end

      unless files.empty?
        do_comment(files)
      end
    end

    private

    # Comment errors based on the given xml file to VCS
    #
    # @param [Array<FoundFile>] files which contains checkstyle results to be reported
    # @return [void] void
    def do_comment(files)
      files.each do |f|
        f.errors.each do |e|
          # see severity
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
