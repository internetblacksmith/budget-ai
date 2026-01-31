# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "returns a successful response" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the dashboard page" do
      get root_path
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Income")
      expect(response.body).to include("Expenses")
      expect(response.body).to include("Net Balance")
      expect(response.body).to include("Savings Rate")
    end

    context "with no transactions" do
      it "shows empty state for recent transactions" do
        get root_path
        expect(response.body).to include("No transactions yet")
        expect(response.body).to include("Import some data")
      end

      it "shows zero values for stats" do
        get root_path
        expect(response.body).to include("£0.00")
        expect(response.body).to include("0%")
      end

      it "shows empty state for categories" do
        get root_path
        expect(response.body).to include("No expense data yet")
      end
    end

    context "with transactions" do
      before do
        Transaction.create!(
          date: Date.current, description: "Monthly Salary", amount: 3000.0,
          account: "current", transaction_id: "sal-001", source: "emma_export",
          category: "Income", is_transfer: false
        )
        Transaction.create!(
          date: Date.current, description: "Tesco Groceries", amount: -85.50,
          account: "savings", transaction_id: "exp-001", source: "emma_export",
          category: "Groceries", is_transfer: false
        )
        Transaction.create!(
          date: Date.current, description: "Electric Bill", amount: -120.0,
          account: "current", transaction_id: "exp-002", source: "emma_export",
          category: "Bills", is_transfer: false
        )
      end

      it "displays computed stat values" do
        get root_path
        expect(response.body).to include("£3,000.00")
        expect(response.body).to include("£205.50")
      end

      it "renders recent transactions" do
        get root_path
        expect(response.body).to include("Monthly Salary")
        expect(response.body).to include("Tesco Groceries")
        expect(response.body).to include("Electric Bill")
      end

      it "renders category donut chart" do
        get root_path
        expect(response.body).to include("Spending by Category")
        expect(response.body).to include("Groceries")
        expect(response.body).to include("Bills")
      end

      it "renders the income vs expenses chart" do
        get root_path
        expect(response.body).to include("Income vs Expenses")
        expect(response.body).to include(Date.current.strftime("%b"))
      end
    end

    context "with transfer transactions" do
      before do
        Transaction.create!(
          date: Date.current, description: "Transfer to Savings", amount: -500.0,
          account: "current", transaction_id: "xfr-001", source: "emma_export",
          category: "Finances", is_transfer: true
        )
      end

      it "excludes transfers from stats" do
        get root_path
        expect(response.body).not_to include("Transfer to Savings")
      end
    end
  end

  describe "GET /dashboard" do
    it "returns a successful response" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
