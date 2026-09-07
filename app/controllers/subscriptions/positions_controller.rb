module Subscriptions
  class PositionsController < ApplicationController
    include RendersSidebar

    def update
      subscription = Current.user.subscriptions.find(params[:subscription_id])
      group = Current.user.groups.find(params[:group_id]) if params[:group_id].present?
      subscription.move_to(params.expect(:position), group: group)
      render_sidebar
    end
  end
end
