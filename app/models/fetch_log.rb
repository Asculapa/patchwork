class FetchLog < ApplicationRecord
  belongs_to :source

  enum :status, { ok: "ok", not_modified: "not_modified", failed: "failed" }
end
