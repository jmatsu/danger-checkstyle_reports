# frozen_string_literal: true

require_relative "../spec_helper"

module CheckstyleReports
  describe CheckstyleReports::Severity do
    let(:data) do
      [
        [:ignore, :ignore, true],
        [:ignore,  :info,    true],
        [:ignore,  :warning, true],
        [:ignore,  :error,   true],
        [:info,    :ignore,  false],
        [:info,    :info,    true],
        [:info,    :warning, true],
        [:info,    :error,   true],
        [:warning, :ignore,  false],
        [:warning, :info,    false],
        [:warning, :warning, true],
        [:warning, :error,   true],
        [:error,   :ignore,  false],
        [:error,   :info,    false],
        [:error,   :warning, false],
        [:error,   :error,   true],
      ]
    end

    context "<=" do
      it do
        data.each do |d|
          base, other, expected = d

          severity = CheckstyleReports::Severity.new(base)

          expect(severity <= other).to eq(expected)
        end
      end
    end
  end
end
