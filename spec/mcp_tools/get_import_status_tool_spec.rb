require "rails_helper"
require_relative "../../app/mcp_tools/get_import_status_tool"

RSpec.describe GetImportStatusTool do
  before do
    create(:import_job, :completed, filename: "emma_jan.csv")
    create(:import_job, :failed, filename: "emma_feb.csv")
    create(:import_job, filename: "emma_mar.csv")
  end

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "returns recent import jobs" do
      result = call
      expect(result.length).to eq(3)
    end

    it "includes job details" do
      result = call
      completed = result.find { |j| j["filename"] == "emma_jan.csv" }
      expect(completed["status"]).to eq("completed")
      expect(completed["imported_count"]).to eq(10)
    end

    it "includes error messages for failed jobs" do
      result = call
      failed = result.find { |j| j["filename"] == "emma_feb.csv" }
      expect(failed["status"]).to eq("failed")
      expect(failed["error_messages"]).not_to be_empty
    end

    it "respects limit parameter" do
      result = call(limit: 1)
      expect(result.length).to eq(1)
    end

    it "returns empty array when no imports" do
      ImportJob.destroy_all
      result = call
      expect(result).to eq([])
    end
  end
end
