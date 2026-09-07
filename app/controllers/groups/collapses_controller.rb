module Groups
  class CollapsesController < ApplicationController
    include RendersSidebar

    before_action :set_group

    def create
      @group.update!(collapsed: true)
      render_sidebar
    end

    def destroy
      @group.update!(collapsed: false)
      render_sidebar
    end

    private
      def set_group
        @group = Current.user.groups.find(params[:group_id])
      end
  end
end
