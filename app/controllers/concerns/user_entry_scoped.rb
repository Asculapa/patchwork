# For controllers nested under /entries/:entry_id that change one entry's state.
module UserEntryScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_user_entry
  end

  private
    def set_user_entry
      @user_entry = Current.user.user_entries.includes(entry: :source, subscription: :source).find_by!(entry_id: params[:entry_id])
    end

    def render_entry_update
      respond_to do |format|
        format.turbo_stream { render "entries/update" }
        format.html { redirect_back_or_to entry_path(@user_entry.entry) }
      end
    end
end
