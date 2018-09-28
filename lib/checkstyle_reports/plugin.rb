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
    # *Optional*
    # An absolute path to a root.
    # To comment errors to VCS, this needs to know relative path of files from the root.
    # The root path of git repository is used by default.
    #
    # @return [String]
    attr_accessor :root_path

    # Report errors based on the given xml file
    #
    # @param [String] xml_file which contains checkstyle results to be reported
    # @param [Boolean] inline_comment create inline comment if true, otherwise this reports a summary as a single comment
    # @param [String, nil] prefix_path be another prefix path instead of root path if you want
    # @return [void] void
    def report(xml_file, inline_comment: true, prefix_path: nil)
      raise "File not found" unless File.exist?(xml_file)

      prefix_path ||= (root_path || `git rev-parse --show-toplevel`.chomp)

      files = REXML::Document.new(File.read(xml_file)).root.each("file") do |f|
        FoundFile.new(f, prefix: prefix_path)
      end

      if inline_comment && files.empty?
        puts "STUB"
      end
    end
  end
end
