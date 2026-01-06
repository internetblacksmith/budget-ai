class ChatController < ApplicationController
  def index
    @messages = ChatMessage.all
  end

  def create
    user_message = ChatMessage.create!(role: "user", content: params[:message])

    chat_service = ChatService.new
    response_text = chat_service.process_message(params[:message])

    assistant_message = ChatMessage.create!(role: "assistant", content: response_text)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: user_message }),
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: assistant_message }),
          turbo_stream.replace("chat-form", partial: "chat/form")
        ]
      end
      format.html { redirect_to chat_index_path }
      format.json { render json: { user: user_message, assistant: assistant_message } }
    end
  rescue LlmClient::LlmError => e
    error_message = ChatMessage.create!(role: "assistant", content: "Sorry, I couldn't process that request. #{e.message}")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: user_message }),
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: error_message }),
          turbo_stream.replace("chat-form", partial: "chat/form")
        ]
      end
      format.html { redirect_to chat_index_path, alert: "LLM error: #{e.message}" }
      format.json { render json: { error: e.message }, status: :service_unavailable }
    end
  end

  def retry
    message = ChatMessage.find(params[:id])
    original_content = message.content

    # Delete this message and everything after it
    ChatMessage.where("created_at >= ?", message.created_at).delete_all

    # Re-submit the question
    user_message = ChatMessage.create!(role: "user", content: original_content)
    chat_service = ChatService.new
    response_text = chat_service.process_message(original_content)
    assistant_message = ChatMessage.create!(role: "assistant", content: response_text)

    redirect_to chat_index_path
  rescue LlmClient::LlmError => e
    ChatMessage.create!(role: "assistant", content: "Sorry, I couldn't process that request. #{e.message}")
    redirect_to chat_index_path
  end

  def clear
    ChatMessage.delete_all
    redirect_to chat_index_path, notice: "Chat history cleared."
  end
end
