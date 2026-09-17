# A manually ordered sidebar item. Records the user hasn't arranged yet have no
# position and follow the arranged ones in alphabetical order.
module Positioned
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(Arel.sql("#{table_name}.position IS NULL, #{table_name}.position")).alphabetical }
  end

  private
    # Puts this record at `index` among `siblings` and renumbers them all, so
    # the whole list becomes explicitly ordered.
    def insert_at(index, siblings)
      ids = siblings.ordered.where.not(id: id).ids
      ids.insert(index.to_i.clamp(0, ids.size), id)
      ids.each_with_index { |sibling_id, position| self.class.where(id: sibling_id).update_all(position: position) }
    end
end
