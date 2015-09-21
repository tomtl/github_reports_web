class SessionsController < ApplicationController

  def create
    auth = request.env["omniauth.auth"]

    @user = User.find_or_create_by!(remote_id: auth.uid, provider: "github") do |user|
      user.name = auth.info.nickname
      user.token = auth.credentials.token
    end

    session[:user_id] = @user.id
    flash[:info] = "You have signed in with GitHub."
    redirect_to root_path
  end

  def failure
    flash[:danger] = "Authorization failed."
    redirect_to root_path
  end
end