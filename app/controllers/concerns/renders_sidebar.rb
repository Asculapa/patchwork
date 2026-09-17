# For controllers that change how the sidebar is arranged and reply with a fresh copy.
module RendersSidebar
  private
    def render_sidebar
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("sidebar", partial: "shared/sidebar") }
        format.html { redirect_back_or_to entries_path }
      end
    end
end
