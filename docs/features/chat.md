# Chat with AI

## Overview

Conversational interface to discuss your finances with the local LLM. Ask questions about spending, get budget suggestions, and explore your transaction patterns.

## Usage

Navigate to **Chat** in the sidebar or visit `/chat`.

### Sending Messages

Type a question in the input bar and press Enter or click Send. The AI will respond based on your actual transaction and budget data.

### Quick Actions

When chat is empty, quick action chips are shown:
- **Analyze spending** — get a summary of your recent spending
- **Suggest budgets** — AI-recommended budget amounts per category
- **Top categories** — see where your money goes
- **Recurring payments** — identify subscriptions and regular charges

### Clearing Chat

Click the "Clear" button in the header to delete all chat history.

## What the AI Knows

The chat AI has access to:
- Your last 3 months of transactions
- Transaction summaries grouped by category
- Top spending categories with amounts
- All current budgets with spent/remaining amounts
- Total transaction count and date range

## Example Questions

- "How much did I spend on groceries this month?"
- "What are my biggest expenses?"
- "Suggest a monthly budget for entertainment"
- "Do I have any recurring payments I should review?"
- "Am I over budget on anything?"
- "How can I save more money?"

## Technical Details

- **Model**: `ChatMessage` (`app/models/chat_message.rb`) — stores conversation history
- **Service**: `ChatService` (`app/services/chat_service.rb`) — builds context and processes messages
- **Controller**: `ChatController` (`app/controllers/chat_controller.rb`)
- **Stimulus**: `chat_controller.js` — handles form submission, typing indicator, auto-scroll
- **LLM Integration**: Uses `LlmPromptBuilder#chat_prompt` and `LlmService#chat`
- **Routes**: `resources :chat, only: [:index, :create]` with `delete :clear` collection route

## Requirements

- Ollama must be running locally (or LLM configured in `config/llm.yml`)
- Transactions should be imported for meaningful responses
