# Collapses and expands the sidebar's "Other" section of ungrouped sources.
class UngroupedCollapsesController < ApplicationController
  include RendersSidebar

  def create
    Current.user.update!(ungrouped_collapsed: true)
    render_sidebar
  end

  def destroy
    Current.user.update!(ungrouped_collapsed: false)
    render_sidebar
  end
end
