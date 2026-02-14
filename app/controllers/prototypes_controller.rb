class PrototypesController < ApplicationController
  layout "prototype"

  VALID_TEMPLATES = %w[1 2 3 4 5].freeze

  def show
    template = params[:id]

    unless VALID_TEMPLATES.include?(template)
      render plain: "Template not found", status: :not_found
      return
    end

    render "prototypes/template_#{template}"
  end
end
