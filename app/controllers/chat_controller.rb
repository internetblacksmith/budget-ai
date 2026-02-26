class ChatController < ApplicationController
  def index
    @messages = ChatMessage.chronological
  end

  def create
    user_message = ChatMessage.create!(role: "user", content: params[:message])

    response_text = LlmService.new.chat(params[:message])

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
    Rails.logger.error("LLM error: #{e.message}")
    error_message = ChatMessage.create!(role: "assistant", content: "Sorry, I couldn't process that request. Please try again later.")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: user_message }),
          turbo_stream.append("chat-messages", partial: "chat/message", locals: { message: error_message }),
          turbo_stream.replace("chat-form", partial: "chat/form")
        ]
      end
      format.html { redirect_to chat_index_path, alert: "Could not reach AI service. Please try again later." }
      format.json { render json: { error: "Service unavailable" }, status: :service_unavailable }
    end
  end

  def retry
    message = ChatMessage.find(params[:id])

    unless message.role == "user"
      redirect_to chat_index_path, alert: "Can only retry user messages."
      return
    end

    original_content = message.content

    # Delete this message and everything after it
    ChatMessage.where("created_at >= ?", message.created_at).delete_all

    # Re-submit the question
    user_message = ChatMessage.create!(role: "user", content: original_content)
    response_text = LlmService.new.chat(original_content)
    ChatMessage.create!(role: "assistant", content: response_text)

    redirect_to chat_index_path
  rescue LlmClient::LlmError => e
    Rails.logger.error("LLM retry error: #{e.message}")
    ChatMessage.create!(role: "assistant", content: "Sorry, I couldn't process that request. Please try again later.")
    redirect_to chat_index_path
  end

  def clear
    ChatMessage.delete_all
    redirect_to chat_index_path, notice: "Chat history cleared."
  end
end
