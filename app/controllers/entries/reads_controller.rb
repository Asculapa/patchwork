module Entries
  class ReadsController < ApplicationController
    include UserEntryScoped

    def create
      @user_entry.mark_read!
      render_entry_update
    end

    def destroy
      @user_entry.mark_unread!
      render_entry_update
    end
  end
end
