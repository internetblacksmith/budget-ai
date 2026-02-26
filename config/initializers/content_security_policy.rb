# frozen_string_literal: true

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com", "https://fonts.googleapis.com"
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.script_src  :self
    policy.img_src     :self, :data
    policy.connect_src :self
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
