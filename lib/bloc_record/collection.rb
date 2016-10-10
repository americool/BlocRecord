module BlocRecord
  class Collection < Array
    def take(count=1)
      self[0..count-1]
    end

    def where(*args)
      if args.count > 1
        expression = args.shift
        # params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        end
      end

      ids = self.map(&:id).join(", ")
      rows = self.first.class.connection.execute <<-SQL
        SELECT #{self.first.class.attributes} FROM #{self.first.class.table} WHERE (#{expression}) AND id IN (#{ids})
      SQL
      rows_to_array(rows)
    end

    def not(*args)
      expression_hash = BlocRecord::Utility.convert_keys(args.first)
      expression = expression_hash.map {|key, value| "#{key}!=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      ids = self.map(&:id).join(", ")
      rows = self.first.class.connection.execute <<-SQL
        SELECT #{self.first.class.attributes} FROM #{self.first.class.table} WHERE (#{expression}) AND id IN (#{ids})
      SQL
      rows_to_array(rows)
    end

    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def destroy_all
      ids = self.map(&:id)
      self.any? ? self.first.class.destroy(*ids) : false
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
