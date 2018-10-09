# frozen_string_literal: true

module CheckstyleReports
  class Severity
    VALUES = %i(ignore info warning error).freeze

    def initialize(base)
      @base = base&.to_sym
    end

    def <=(other)
      return if @base.nil?
      return true if other.nil?

      VALUES.index(@base) <= VALUES.index(other.to_sym)
    end
  end
end
