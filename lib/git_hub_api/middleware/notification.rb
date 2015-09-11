module GitHubAPI::Middleware
  class Notification < Faraday::Middleware
    def call(env)
      ActiveSupport::Notifications.instrument("request.faraday", env) do
        @app.call(env)
      end
    end
  end
end
