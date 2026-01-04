require "open3"

# Handles LLM provider initialization and API communication
class LlmClient
  class LlmError < StandardError; end
  class ConnectionError < LlmError; end
  class TimeoutError < LlmError; end

  attr_reader :config, :provider_client

  def initialize(config)
    @config = config
    @provider_client = build_client
  end

  def generate(prompt, temperature: nil, max_tokens: nil)
    temperature ||= @config[:temperature]
    max_tokens ||= @config[:max_tokens]

    case @config[:provider]
    when "claude_cli"
      generate_with_claude_cli(prompt)
    when "ollama"
      generate_with_ollama(prompt, temperature, max_tokens)
    when "mock"
      MockLlmClient.generate(prompt)
    else
      raise LlmError, "Unsupported LLM provider: #{@config[:provider]}"
    end
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "LLM request timed out: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    if e.message.include?("execution expired")
      raise TimeoutError, "LLM request timed out: #{e.message}"
    else
      raise ConnectionError, "Failed to connect to LLM service: #{e.message}"
    end
  rescue StandardError => e
    Rails.logger.error { "LLM generation failed: #{e.message}" }
    raise LlmError, "LLM generation failed: #{e.message}"
  end

  def generate_stream(prompt, temperature: nil, max_tokens: nil, &block)
    temperature ||= @config[:temperature]
    max_tokens ||= @config[:max_tokens]

    case @config[:provider]
    when "claude_cli"
      generate_stream_with_claude_cli(prompt, &block)
    when "ollama"
      generate_stream_with_ollama(prompt, temperature, max_tokens, &block)
    when "mock"
      yield "This is a mock streaming response for testing."
    else
      raise LlmError, "Unsupported LLM provider: #{@config[:provider]}"
    end
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "LLM request timed out: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    if e.message.include?("execution expired")
      raise TimeoutError, "LLM request timed out: #{e.message}"
    else
      raise ConnectionError, "Failed to connect to LLM service: #{e.message}"
    end
  end

  private

  def build_client
    case @config[:provider]
    when "ollama"
      build_ollama_client
    when "mock"
      MockLlmClient.new
    end
  end

  def build_ollama_client
    Faraday.new(url: ollama_base_url) do |f|
      f.request :json
      f.response :json
      f.request :retry, max: 3, interval: 0.5
      f.adapter Faraday.default_adapter
      f.options.timeout = @config[:timeout]
      f.options.read_timeout = @config[:read_timeout]
    end
  end

  def ollama_base_url
    "http://#{@config[:host]}:#{@config[:port]}"
  end

  def generate_with_ollama(prompt, temperature, max_tokens)
    full_prompt = "#{@config[:system_prompt]}\n\n#{prompt}"
    Rails.logger.debug { "[LLM Request] model=#{@config[:model]} temperature=#{temperature} max_tokens=#{max_tokens}" }
    Rails.logger.debug { "[LLM Prompt]\n#{full_prompt}" }

    response = @provider_client.post("/api/generate") do |req|
      req.body = {
        model: @config[:model],
        prompt: full_prompt,
        temperature: temperature,
        options: {
          num_predict: max_tokens
        },
        stream: false
      }
    end

    if response.success?
      result = response.body["response"]
      Rails.logger.debug { "[LLM Response] (#{result&.length} chars)\n#{result}" }
      result
    else
      raise LlmError, "Ollama API error: #{response.status} - #{response.body}"
    end
  end

  def generate_stream_with_ollama(prompt, temperature, max_tokens)
    full_prompt = "#{@config[:system_prompt]}\n\n#{prompt}"
    buffer = +""

    conn = Faraday.new(url: ollama_base_url) do |f|
      f.adapter Faraday.default_adapter
      f.options.timeout = @config[:timeout]
      f.options.read_timeout = @config[:read_timeout]
    end

    conn.post("/api/generate") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: @config[:model],
        prompt: full_prompt,
        temperature: temperature,
        options: { num_predict: max_tokens },
        stream: true
      }.to_json

      req.options.on_data = proc do |chunk, _size|
        buffer << chunk
        while (newline_idx = buffer.index("\n"))
          line = buffer.slice!(0, newline_idx + 1).strip
          next if line.empty?

          begin
            data = JSON.parse(line)
            yield data["response"] if data["response"].present?
          rescue JSON::ParserError
            next
          end
        end
      end
    end
  end

  # Claude CLI provider methods

  def generate_with_claude_cli(prompt)
    command = build_claude_command(prompt, stream: false)
    Rails.logger.debug { "[Claude CLI] Running: claude -p ..." }

    stdout, status = Open3.capture2(clean_env, *command)

    unless status.success?
      raise LlmError, "Claude CLI exited with status #{status.exitstatus}: #{stdout}"
    end

    Rails.logger.debug { "[Claude CLI Response] (#{stdout.length} chars)" }
    stdout
  end

  def generate_stream_with_claude_cli(prompt)
    command = build_claude_command(prompt, stream: true)
    Rails.logger.debug { "[Claude CLI Stream] Running: claude -p ... --output-format stream-json" }

    Open3.popen2(clean_env, *command) do |stdin, stdout, wait_thread|
      stdin.close
      stdout.each_line do |line|
        line.strip!
        next if line.empty?

        begin
          data = JSON.parse(line)
          next unless data["type"] == "stream_event"

          delta = data.dig("event", "delta")
          yield delta["text"] if delta&.dig("type") == "text_delta" && delta["text"].present?
        rescue JSON::ParserError
          next
        end
      end

      status = wait_thread.value
      unless status.success?
        raise LlmError, "Claude CLI stream exited with status #{status.exitstatus}"
      end
    end
  end

  def build_claude_command(prompt, stream:)
    cmd = [
      "claude",
      "-p",
      "--no-session-persistence",
      "--tools", "",
      "--model", @config[:model].to_s
    ]

    if @config[:system_prompt].present?
      cmd += [ "--system-prompt", @config[:system_prompt].to_s.strip ]
    end

    if stream
      cmd += [ "--output-format", "stream-json", "--verbose", "--include-partial-messages" ]
    else
      cmd += [ "--output-format", "text" ]
    end
    cmd << prompt.to_s
    cmd
  end

  def clean_env
    ENV.to_h.except("CLAUDECODE")
  end

  # Mock client for testing
  class MockLlmClient
    def self.generate(prompt)
      "This is a mock response for testing. In production, this would be actual LLM analysis."
    end
  end
end
