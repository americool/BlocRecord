module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def group(*args)
      ids = self.map(&:id)
     # #9
     self.any? ? self.first.class.group_by_ids(ids, args) : false
    end

    def distinct
      ids = self.map(&:id).join(", ")
      rows = self.first.class.connection.execute <<-SQL
        SELECT DISTINCT #{self.first.class.attributes} FROM #{self.first.class.table} WHERE id IN (#{ids})
      SQL
      rows_to_array(rows)
    end
  end
end
