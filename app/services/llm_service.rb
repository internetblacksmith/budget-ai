# Orchestrates LLM analysis by delegating to specialized services
class LlmService
  delegate :LlmError, :ConnectionError, :TimeoutError, to: :class

  def self.LlmError
    LlmClient::LlmError
  end

  def self.ConnectionError
    LlmClient::ConnectionError
  end

  def self.TimeoutError
    LlmClient::TimeoutError
  end

  def initialize
    @config = load_config
    @client = LlmClient.new(@config)
  end

  def analyze_spending(transactions, options = {})
    analyzer = TransactionAnalyzer.new(transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.spending_analysis(options)
    @client.generate(prompt)
  end

  def suggest_budget(account_stats, monthly_data, options = {})
    all_transactions = monthly_data.flat_map { |m| m[:transactions].to_a }
    analyzer = TransactionAnalyzer.new(all_transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.budget_suggestion(account_stats, monthly_data: monthly_data, **options)
    @client.generate(prompt)
  end

  def categorize_transaction(transaction)
    analyzer = TransactionAnalyzer.new([ transaction ])
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.transaction_categorization(transaction)
    @client.generate(prompt, temperature: 0.3, max_tokens: 50)
  end

  def chat(prompt)
    @client.generate(prompt)
  end

  def explain_spending_pattern(transactions, pattern_type)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.pattern_explanation(pattern_type)
    @client.generate(prompt)
  end

  def stream_analyze_spending(transactions, options = {}, &block)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.spending_analysis(options)
    @client.generate_stream(prompt, &block)
  end

  def stream_suggest_budget(account_stats, monthly_data, &block)
    all_transactions = monthly_data.flat_map { |m| m[:transactions].to_a }
    analyzer = TransactionAnalyzer.new(all_transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.budget_suggestion(account_stats, monthly_data: monthly_data)
    @client.generate_stream(prompt, &block)
  end

  def stream_explain_pattern(transactions, pattern_type, &block)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt_builder = LlmPromptBuilder.new(analyzer)
    prompt = prompt_builder.pattern_explanation(pattern_type)
    @client.generate_stream(prompt, &block)
  end

  private

  def load_config
    config_file = Rails.root.join("config", "llm.yml")
    erb_content = ERB.new(File.read(config_file)).result
    config = YAML.safe_load(erb_content, aliases: true)[Rails.env]
    config.deep_symbolize_keys
  end
end
