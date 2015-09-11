class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def user_signed_in?
    session[:user_id].present?
  end

  def current_user
    @current_user ||= User.find(session[:user_id])
  end

  helper_method :user_signed_in?
  helper_method :current_user

  def require_sign_in
    unless user_signed_in?
      flash[:info] = "You must sign in."
      redirect_to root_path
    end
  end
end
