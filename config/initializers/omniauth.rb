Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV['GITHUB_APP_KEY'], ENV['GITHUB_APP_SECRET'], scope: "user, gist"
end
