require_dependency "git_hub_api/client"

class GistsController < ApplicationController

  before_filter :require_sign_in

  def index
    @gists = github_api_client.gists(page: params[:page])
  end

  def new
    @gist_form = GistForm.new
  end

  def create
    @gist_form = GistForm.new(gist_form_params)

    if @gist_form.valid?
      gist_info = github_api_client.create_private_gist(@gist_form.description,
                                                        @gist_form.file_name,
                                                        @gist_form.file_contents)
      flash[:info] = "Your gist has been created and can be viewed at this url: #{gist_info.url}"
      redirect_to gist_path(gist_info.id)
    else
      render :new
    end
  rescue GitHubAPI::RequestFailure => e
    flash[:danger] = e.message
    render :new
  end

  def show
    client = GitHubAPI::Client.new(current_user.token)
    @gist = client.gist_info(params[:id])
  rescue GitHubAPI::NonexistentGist => e
    flash.now[:danger] = e.message
    render status: 404
  end

  def destroy
    github_api_client.delete_gist(params[:id])
    flash[:info] = "The gist was deleted."
    redirect_to gists_path
  rescue GitHubAPI::Error => e
    flash[:danger] = "The gist could not be deleted: #{e.message}"
    redirect_to gists_path
  end

  private

  def gist_form_params
    params.require(:gist_form).permit(:description, :file_name, :file_contents)
  end

  def github_api_client
    @github_api_client ||= GitHubAPI::Client.new(current_user.token)
  end

end
