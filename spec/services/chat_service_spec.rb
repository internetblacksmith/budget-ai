require 'rails_helper'

RSpec.describe ChatService, type: :service do
  let(:service) { described_class.new }

  before do
    allow_any_instance_of(LlmService).to receive(:chat)
      .and_return("Here is my analysis of your spending.")
  end

  describe '#process_message' do
    it 'returns LLM response' do
      response = service.process_message("Analyze my spending")
      expect(response).to eq("Here is my analysis of your spending.")
    end

    it 'includes pre-computed monthly breakdown in prompt' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)

      expect_any_instance_of(LlmService).to receive(:chat) do |_, prompt|
        expect(prompt).to include("MONTHLY BREAKDOWN")
        expect(prompt).to include("expenses £50.0")
        "Response"
      end

      service.process_message("How am I doing?")
    end

    it 'includes pre-computed category spending per month' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)
      create(:transaction, category: "Bills", amount: -100, date: Date.current)

      expect_any_instance_of(LlmService).to receive(:chat) do |_, prompt|
        expect(prompt).to include("SPENDING BY CATEGORY PER MONTH")
        expect(prompt).to include("Groceries: £50.0")
        expect(prompt).to include("Bills: £100.0")
        "Response"
      end

      service.process_message("What did I spend on?")
    end

    it 'includes budget information with spent amounts' do
      create(:budget, category: "Bills", monthly_limit: 500)

      expect_any_instance_of(LlmService).to receive(:chat) do |_, prompt|
        expect(prompt).to include("BUDGETS")
        expect(prompt).to include("Bills")
        expect(prompt).to include("500.0")
        expect(prompt).to include("on track")
        "Response"
      end

      service.process_message("What are my budgets?")
    end

    it 'includes average monthly totals' do
      create(:transaction, category: "Income", amount: 2000, date: Date.current)
      create(:transaction, category: "Groceries", amount: -300, date: Date.current)

      expect_any_instance_of(LlmService).to receive(:chat) do |_, prompt|
        expect(prompt).to include("Average monthly income")
        expect(prompt).to include("Average monthly expenses")
        "Response"
      end

      service.process_message("What are my averages?")
    end

    it 'works with no transactions or budgets' do
      response = service.process_message("Hello")
      expect(response).to be_a(String)
    end
  end
end
