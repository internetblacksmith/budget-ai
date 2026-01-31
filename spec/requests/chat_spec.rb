require 'rails_helper'

RSpec.describe "Chat", type: :request do
  describe "GET /chat" do
    it "returns a successful response" do
      get chat_index_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the chat page" do
      get chat_index_path
      expect(response.body).to include("Chat")
      expect(response.body).to include("Ask me anything about your finances")
    end

    context "with existing messages" do
      before do
        create(:chat_message, role: "user", content: "How much did I spend?")
        create(:chat_message, :assistant, content: "You spent £500 this month.")
      end

      it "displays message history" do
        get chat_index_path
        expect(response.body).to include("How much did I spend?")
        expect(response.body).to include("You spent £500 this month.")
      end
    end
  end

  describe "POST /chat" do
    before do
      allow_any_instance_of(ChatService).to receive(:process_message)
        .and_return("Based on your data, you spent £200 on groceries.")
    end

    it "creates user and assistant messages" do
      expect {
        post chat_index_path, params: { message: "What did I spend on groceries?" }
      }.to change(ChatMessage, :count).by(2)

      messages = ChatMessage.last(2)
      expect(messages.first.role).to eq("user")
      expect(messages.first.content).to eq("What did I spend on groceries?")
      expect(messages.last.role).to eq("assistant")
      expect(messages.last.content).to include("£200 on groceries")
    end

    it "redirects for HTML requests" do
      post chat_index_path, params: { message: "Hello" }
      expect(response).to redirect_to(chat_index_path)
    end

    context "when LLM fails" do
      before do
        allow_any_instance_of(ChatService).to receive(:process_message)
          .and_raise(LlmClient::ConnectionError, "Cannot connect")
      end

      it "creates an error message" do
        expect {
          post chat_index_path, params: { message: "Hello" }
        }.to change(ChatMessage, :count).by(2)

        error_message = ChatMessage.last
        expect(error_message.role).to eq("assistant")
        expect(error_message.content).to include("Sorry")
      end
    end
  end

  describe "DELETE /chat/clear" do
    before do
      create(:chat_message, content: "test message 1")
      create(:chat_message, :assistant, content: "test response 1")
    end

    it "deletes all messages" do
      expect {
        delete clear_chat_index_path
      }.to change(ChatMessage, :count).to(0)

      expect(response).to redirect_to(chat_index_path)
    end
  end
end
