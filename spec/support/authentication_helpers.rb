module AuthenticationHelpers
  def sign_in(user)
    # For controller tests
    if defined?(RSpec) && RSpec.current_example.metadata[:type] == :controller
      session[:user_id] = user.id if respond_to?(:session)
      # Also stub the controller methods to be sure
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:require_authentication).and_return(true)
    else
      # For request/integration tests
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(true)
    end
  end

  def sign_out
    if respond_to?(:session)
      session.delete(:user_id)
    else
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
    end
  end

  def current_user
    if respond_to?(:session) && session[:user_id]
      User.find_by(id: session[:user_id])
    else
      nil
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
