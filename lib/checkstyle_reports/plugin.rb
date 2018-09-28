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
  # All command need your apk filepath like below
  #
  #         apkstats.apk_filepath=<your new apk filepath>
  #
  # @example Compare two apk files and print it.
  #
  #         apkstats.compare_with(<your old apk filepath>, do_report: true) # report it in markdown table
  #         apkstats.compare_with(<your old apk filepath>, do_report: false) # just return results
  #
  # @example Show the file size of your apk file.
  #
  #         apkstats.file_size
  #
  # @example Show the download size of your apk file.
  #
  #         apkstats.download_size
  #
  # @example Show all required features of your apk file.
  #
  #         apkstats.required_features
  #
  # @example Show all non-required features of your apk file.
  #
  #         apkstats.non_required_features
  #
  # @example Show all requested permissions of your apk file.
  #
  #         apkstats.permissions
  #
  # @example Show the min sdk version of your apk file.
  #
  #         apkstats.min_sdk
  #
  # @example Show the target sdk version of your apk file.
  #
  #         apkstats.target_sdk
  #
  # @example Show the methods reference count of your apk file.
  #
  #         apkstats.method_reference_count
  #
  # @example Show the number of dex of your apk file.
  #
  #         apkstats.dex_count
  #
  # @see  Jumpei Matsuda/danger-apkstats
  # @tags android, apk_stats
  #
  class DangerCheckstyleReports < Plugin

    # *Optional*
    # A command type to be run.
    # One of keys of COMMAND_TYPE_MAP
    #
    # @return [Symbol, Nil] _
    attr_accessor :command_type

    # *Optional*
    # A custom command path
    #
    # @return [Symbol, Nil] _
    attr_accessor :command_path

    # *Required*
    # Your target apk filepath.
    #
    # @return [String]
    attr_accessor :apk_filepath

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

    # Get stats of two apk files and calculate diffs between them.
    #
    # @param [String] other_apk_filepath your old apk
    # @param [Boolean] do_report report markdown table if true, otherwise just return results
    # @return [Hash] see command/executable#compare_with for more detail
    def compare_with(other_apk_filepath, do_report: true)
      raise "apk filepaths must be specified" if apk_filepath.nil? || apk_filepath.empty?

      base_apk = Apkstats::Entity::ApkInfo.new(command, apk_filepath)
      other_apk = Apkstats::Entity::ApkInfo.new(command, other_apk_filepath)

      return {
          base: base_apk.to_h,
          other: base_apk.to_h,
          diff: Apkstats::Entity::ApkInfoDiff.new(base_apk, other_apk).to_h,
      }.tap do |result|
        break unless do_report

        diff = result[:diff]

        md = +"### Apk comparision results" << "\n\n"
        md << "Property | Summary" << "\n"
        md << ":--- | :---" << "\n"

        diff[:min_sdk].tap do |min_sdk|
          break if min_sdk.size == 1

          md << "Min SDK Change | Before #{min_sdk[1]} / After #{min_sdk[0]}" << "\n"
        end

        diff[:target_sdk].tap do |target_sdk|
          break if target_sdk.size == 1

          md << "Target SDK Change | Before #{target_sdk[1]} / After #{target_sdk[0]}" << "\n"
        end

        result[:base][:file_size].tap do |file_size|
          size = Apkstats::Helper::Bytes.from_b(file_size)

          md << "New File Size | #{size.to_b} Bytes. (#{size.to_mb} MB) " << "\n"
        end

        diff[:file_size].tap do |file_size|
          size = Apkstats::Helper::Bytes.from_b(file_size)

          md << "File Size Change | #{size.to_s_b} Bytes. (#{size.to_s_kb} KB) " << "\n"
        end

        diff[:download_size].tap do |download_size|
          size = Apkstats::Helper::Bytes.from_b(download_size)

          md << "Download Size Change | #{size.to_s_b} Bytes. (#{size.to_s_kb} KB) " << "\n"
        end

        result[:base][:method_reference_count].tap do |method_reference_count|
          md << "New Method Reference Count | #{method_reference_count}" << "\n"
        end

        diff[:method_reference_count].tap do |method_reference_count|
          md << "Method Reference Count Change | #{method_reference_count}" << "\n"
        end

        result[:base][:dex_count].tap do |dex_count|
          md << "New Number of dex file(s) | #{dex_count}" << "\n"
        end

        diff[:dex_count].tap do |dex_count|
          md << "Number of dex file(s) Change | #{dex_count}" << "\n"
        end

        report_hash_and_arrays = lambda { |key, name|
          list_up_entities = lambda { |type_key, label|
            diff[key][type_key].tap do |features|
              break if features.empty?

              md << "#{label} | " << features.map { |f| "- #{f}" }.join("<br>").to_s << "\n"
            end
          }

          list_up_entities.call(:new, "New #{name}")
          list_up_entities.call(:removed, "Removed #{name}")
        }

        report_hash_and_arrays.call(:required_features, "Required Features")
        report_hash_and_arrays.call(:non_required_features, "Non-required Features")
        report_hash_and_arrays.call(:permissions, "Permissions")

        markdown(md)
      end
    rescue StandardError => e
      warn("apkstats failed to execute the command due to #{e.message}")

      e.backtrace&.each { |line| STDOUT.puts line }
    end
  end
end
