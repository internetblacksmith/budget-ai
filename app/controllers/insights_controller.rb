class InsightsController < ApplicationController
  include ActionController::Live
  include AccountStatistics

  before_action :check_llm_availability

  def index
    @account_statistics = calculate_account_statistics
    @recent_transactions = Transaction.order(date: :desc).limit(100)
    @has_transactions = Transaction.exists?
  end

  def spending_analysis
    @period = params[:period] || "last_month"
    @account = params[:account]
  end

  def budget_suggestions
    @account_statistics = calculate_account_statistics
    @available_months = Transaction.distinct_months(limit: 6)
    @selected_months = params[:months].presence || @available_months
  end

  def categorize_transactions
    uncategorized = Transaction.where(category: [ nil, "" ])

    if uncategorized.any?
      @categorization_results = []

      uncategorized.limit(50).each do |transaction|
        begin
          category = llm_service.categorize_transaction(transaction)
          transaction.update(category: category.strip)
          TransactionEdit.record_edit(transaction, { category: category.strip })
          @categorization_results << { transaction: transaction, category: category, success: true }
        rescue LlmClient::LlmError => e
          @categorization_results << { transaction: transaction, error: e.message, success: false }
        end
      end
    else
      @categorization_results = []
      flash.now[:notice] = "All transactions are already categorized!"
    end
  end

  def explain_pattern
    pattern_type = params[:pattern_type]&.to_sym

    unless valid_pattern_types.include?(pattern_type)
      redirect_to insights_path, alert: "Invalid pattern type"
      return
    end

    @pattern_type = pattern_type
  end

  def stream
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    stream_llm_response
  rescue LlmClient::ConnectionError
    response.stream.write("\n\n[ERROR]Cannot connect to LLM service. Please check your configuration.")
  rescue LlmClient::TimeoutError
    response.stream.write("\n\n[ERROR]LLM request timed out. Please try again.")
  rescue StandardError => e
    response.stream.write("\n\n[ERROR]Analysis failed: #{e.message}")
  ensure
    response.stream.close
  end

  private

  def stream_llm_response
    case params[:type]
    when "spending_analysis"
      period = params[:period] || "last_month"
      account = params[:account]
      transactions = filtered_transactions(period, account)
      llm_service.stream_analyze_spending(transactions, period: period, account: account) do |token|
        response.stream.write(token)
      end
    when "budget_suggestions"
      account_stats = calculate_account_statistics
      selected_months = params[:months].presence || Transaction.distinct_months(limit: 6)
      monthly_data = selected_months.map do |month|
        date = Date.parse("#{month}-01")
        range = date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
        { month: month, transactions: Transaction.non_transfers.where(date: range) }
      end
      llm_service.stream_suggest_budget(account_stats, monthly_data) do |token|
        response.stream.write(token)
      end
    when "explain_pattern"
      pattern_type = params[:pattern_type]&.to_sym
      unless valid_pattern_types.include?(pattern_type)
        response.stream.write("[ERROR]Invalid pattern type")
        return
      end
      period = params[:period] || "last_month"
      transactions = filtered_transactions(period)
      llm_service.stream_explain_pattern(transactions, pattern_type) do |token|
        response.stream.write(token)
      end
    else
      response.stream.write("[ERROR]Unknown analysis type")
    end
  end

  def valid_pattern_types
    %i[weekend_spending recurring high_value category_spike]
  end

  def check_llm_availability
    unless llm_service
      redirect_to root_path, alert: "LLM service is not configured. Please check your settings."
      false
    end
  end

  def llm_service
    @llm_service ||= begin
      LlmService.new
    rescue StandardError => e
      Rails.logger.error { "Failed to initialize LLM service: #{e.message}" }
      nil
    end
  end

  def filtered_transactions(period, account = nil)
    transactions = Transaction.all
    transactions = transactions.where(account: account) if account.present?

    case period
    when "today"
      transactions.where(date: Date.current)
    when "this_week"
      transactions.where(date: Date.current.beginning_of_week..)
    when "last_week"
      transactions.where(date: 1.week.ago.beginning_of_week..1.week.ago.end_of_week)
    when "this_month"
      transactions.where(date: Date.current.beginning_of_month..)
    when "last_month"
      transactions.where(date: 1.month.ago.beginning_of_month.beginning_of_day..1.month.ago.end_of_month.end_of_day)
    when "last_3_months"
      transactions.where(date: 3.months.ago..)
    else
      transactions.where(date: 1.month.ago..)
    end
  end
end
