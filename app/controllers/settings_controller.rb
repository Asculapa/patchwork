class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(params.expect(user: [ :time_zone ]))
      redirect_to settings_path, notice: "Settings saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = Current.user
    end
end
