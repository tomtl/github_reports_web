require_dependency "git_hub_api/client"

class GistsController < ApplicationController

  before_filter :require_sign_in

  def index
    @gists = github_api_client.gists
  end

  private

  def github_api_client
    @github_api_client ||= GitHubAPI::Client.new(current_user.token)
  end

end
