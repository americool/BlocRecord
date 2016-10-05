require 'sqlite3'
require 'bloc_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key])}

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end


    def update(ids, updates)
      if updates.keys.uniq == updates.keys
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL

        true
      else
        updates.delete "id"
        keys = updates.keys
        potential_duplicate = nil
        keys.each_with_index do |name, index|
          if potential_duplicate == name
            duplicate = name
            duplicate_index = index
            break
          else
            potential_duplicate = name
          end
        end
        new_hash = updates[duplicate]
        new_id = ids[duplicate_index]
        updates.delete(duplicate)
        ids.delete(duplicate_index)
        update(new_id, new_hash)
        update(ids, updates)
      end
    end

    def update_all(updates)
      update(nil, updates)
    end
  end

  def method_missing(method_name, *args, &block)
    first_part = method_name[0..5]
    second_part = method_name[7..-1]
    if first_part == "update"
      args.unshift(second_part)
      new_obj = {}
      new_obj[second_part] = *args
      self.send(:update, new_obj)
    end
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.ininstance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id}
    SQL

    true
  end

  def save
    self.save! rescue false
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

end
