# frozen_string_literal: true

class GetImportStatusTool < MCP::Tool
  description "Get recent import jobs with status, error messages, and transaction counts."

  input_schema(
    properties: {
      limit: { type: "integer", description: "Number of recent imports to return. Defaults to 10." }
    }
  )

  class << self
    def call(server_context: nil, **params)
      limit = (params[:limit] || 10).to_i.clamp(1, 50)
      jobs = ImportJob.recent.limit(limit)

      result = jobs.map do |job|
        {
          id: job.id,
          status: job.status,
          display_status: job.display_status,
          source: job.source,
          filename: job.filename,
          imported_count: job.imported_count,
          duplicate_count: job.duplicate_count,
          error_messages: job.error_messages,
          started_at: job.started_at&.iso8601,
          completed_at: job.completed_at&.iso8601
        }
      end

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end
  end
end
