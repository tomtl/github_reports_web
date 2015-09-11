module GitHubAPI
  module Middleware
    class Authentication < Faraday::Middleware
      def initialize(app, token = ENV["GITHUB_TOKEN"])
        super(app)
        @token = token
      end

      def call(env)
        env.request_headers["Authorization"] = "token #{@token}"
        @app.call(env).on_complete do |response_env|
          if response_env.status == 401
            raise AuthenticationFailure, response_env[:body]['message']
          end
        end
      end
    end
  end
end
