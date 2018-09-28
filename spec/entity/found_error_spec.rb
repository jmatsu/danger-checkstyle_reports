# frozen_string_literal: true

require_relative "../spec_helper"

module CheckstyleReports::Entity
  ERROR_NODE_SAMPLE_1 = <<NODE
<error
  line="144"
  column="108"
  severity="error"
  message="&apos;+&apos; should be on a new line."
  source="com.puppycrawl.tools.checkstyle.checks.whitespace.OperatorWrapCheck"
/>
NODE

  ERROR_NODE_SAMPLE_2 = <<NODE
<error
  line="296"
  severity="error"
  message="Line has trailing spaces."
  source="com.puppycrawl.tools.checkstyle.checks.regexp.RegexpSinglelineCheck"
/>
NODE

  describe CheckstyleReports::Entity::FoundError do
    let(:error) { FoundError.new(REXML::Document.new(node).root) }

    context "sample1" do
      let(:node) { ERROR_NODE_SAMPLE_1 }

      it "should read it successfully" do
        expect(error.line_number).to eq(144)
        expect(error.column_number).to eq(108)
        expect(error.severity).to eq("error")
        expect(error.html_unescaped_message).to eq("'+' should be on a new line.")
        expect(error.source).to eq("com.puppycrawl.tools.checkstyle.checks.whitespace.OperatorWrapCheck")
      end
    end

    context "sample2" do
      let(:node) { ERROR_NODE_SAMPLE_2 }

      it "should read it successfully" do
        expect(error.line_number).to eq(296)
        expect(error.column_number).to be_nil
        expect(error.severity).to eq("error")
        expect(error.html_unescaped_message).to eq("Line has trailing spaces.")
        expect(error.source).to eq("com.puppycrawl.tools.checkstyle.checks.regexp.RegexpSinglelineCheck")
      end
    end
  end
end
