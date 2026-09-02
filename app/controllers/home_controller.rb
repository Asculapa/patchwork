class HomeController < ApplicationController
  allow_unauthenticated_access

  layout "home"

  def index
    redirect_to entries_path if authenticated?
  end
end
