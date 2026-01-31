require "rails_helper"
require_relative "../../app/mcp_tools/analyze_spending_tool"

RSpec.describe AnalyzeSpendingTool do
  before do
    create(:transaction, :expense, amount: -50, description: "tesco weekly shop", category: "Groceries", date: Date.current)
    create(:transaction, :expense, amount: -55, description: "tesco weekly shop", category: "Groceries", date: 1.week.ago)
    create(:transaction, :expense, amount: -500, description: "New Laptop", category: "Electronics", date: Date.current)
    create(:transaction, :expense, amount: -10, description: "Bus Fare", category: "Transport", date: Date.current.beginning_of_week)
    create(:transaction, :expense, amount: -15, description: "Uber Ride", category: "Transport", date: Date.current.beginning_of_week + 5.days)
  end

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    context "with recurring analysis" do
      it "detects recurring transactions" do
        result = call(analysis_type: "recurring")
        expect(result).to be_an(Array)
        expect(result.any? { |r| r["count"] >= 2 }).to be true
      end
    end

    context "with high_value analysis" do
      it "returns high value transactions" do
        result = call(analysis_type: "high_value")
        expect(result).to be_an(Array)
        expect(result.any? { |t| t["amount"].abs >= 500 }).to be true
      end
    end

    context "with weekend_vs_weekday analysis" do
      it "returns weekend and weekday breakdowns" do
        result = call(analysis_type: "weekend_vs_weekday")
        expect(result).to have_key("weekend")
        expect(result).to have_key("weekday")
        expect(result["weekend"]).to have_key("count")
        expect(result["weekday"]).to have_key("count")
      end
    end

    context "with category_spending analysis" do
      it "returns spending by category" do
        result = call(analysis_type: "category_spending")
        expect(result).to be_a(Hash)
        expect(result["Groceries"].to_f).to be > 0
      end
    end

    context "with category_spikes analysis" do
      it "returns category spikes hash" do
        result = call(analysis_type: "category_spikes")
        expect(result).to be_a(Hash)
      end
    end

    it "respects date range parameters" do
      result = call(analysis_type: "category_spending", start_date: Date.current.to_s, end_date: Date.current.to_s)
      expect(result).to be_a(Hash)
    end

    it "returns empty data when no transactions in range" do
      result = call(analysis_type: "category_spending", start_date: "2020-01-01", end_date: "2020-01-31")
      expect(result).to eq({})
    end
  end
end
