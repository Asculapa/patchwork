module Groups
  class PositionsController < ApplicationController
    include RendersSidebar

    def update
      Current.user.groups.find(params[:group_id]).move_to(params.expect(:position))
      render_sidebar
    end
  end
end
