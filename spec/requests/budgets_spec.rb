require 'rails_helper'

RSpec.describe "Budgets", type: :request do
  describe "GET /budgets" do
    it "returns a successful response" do
      get budgets_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the budgets page" do
      get budgets_path
      expect(response.body).to include("Budgets")
    end

    context "with no budgets" do
      it "shows empty state" do
        get budgets_path
        expect(response.body).to include("No budgets yet")
      end
    end

    context "with existing budgets" do
      before do
        create(:budget, category: "Groceries", monthly_limit: 200)
        create(:budget, category: "Bills", monthly_limit: 500)
      end

      it "displays budget cards" do
        get budgets_path
        expect(response.body).to include("Groceries")
        expect(response.body).to include("Bills")
        expect(response.body).to include("200")
        expect(response.body).to include("500")
      end
    end
  end

  describe "POST /budgets" do
    it "creates a new budget" do
      expect {
        post budgets_path, params: { budget: { category: "Transport", monthly_limit: 150 } }
      }.to change(Budget, :count).by(1)

      expect(response).to redirect_to(budgets_path)
      follow_redirect!
      expect(response.body).to include("Transport")
    end

    it "rejects invalid budgets" do
      expect {
        post budgets_path, params: { budget: { category: "", monthly_limit: 0 } }
      }.not_to change(Budget, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate categories" do
      create(:budget, category: "Groceries")

      expect {
        post budgets_path, params: { budget: { category: "Groceries", monthly_limit: 300 } }
      }.not_to change(Budget, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /budgets/:id" do
    let!(:budget) { create(:budget, category: "Groceries", monthly_limit: 200) }

    it "updates the budget" do
      patch budget_path(budget), params: { budget: { monthly_limit: 300 } }

      expect(response).to redirect_to(budgets_path)
      expect(budget.reload.monthly_limit).to eq(300)
    end

    it "rejects invalid updates" do
      patch budget_path(budget), params: { budget: { monthly_limit: 0 } }

      expect(response).to redirect_to(budgets_path)
      expect(budget.reload.monthly_limit).to eq(200)
    end
  end

  describe "DELETE /budgets/:id" do
    let!(:budget) { create(:budget, category: "Groceries") }

    it "deletes the budget" do
      expect {
        delete budget_path(budget)
      }.to change(Budget, :count).by(-1)

      expect(response).to redirect_to(budgets_path)
    end
  end
end
