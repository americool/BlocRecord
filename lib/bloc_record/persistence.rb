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
      case updates
      when Hash
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
      when Array
        updates.each_with_index do |hash, index|
          update(ids[index], hash)
        end
      end
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end
      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

    def destroy_all(conditions_hash=nil, *extra_args)
      if conditions_hash && !conditions_hash.empty?
        case conditions_hash
        when Hash
          conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
          conditions = conditions_hash.map{|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        when String
          if extra_args.is_a?(Array)
            conditions_array = conditions_hash.split("?")
            conditions_array = conditions_array.each_with_index.map do |condition, index|
              condition + "'" + extra_args[index] + "'"
            end
            conditions = conditions_array.join(",")
          else
            conditions = conditions_hash
          end
        end
          connection.execute <<-SQL
            DELETE FROM #{table}
            WHERE #{conditions};
          SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end
      true
    end
  end

  def method_missing(method_name, *args, &block)
    first_part = method_name[0..5]
    second_part = method_name[7..-1]
    if first_part == "update"
      new_obj = {}
      new_obj[second_part] = args.first
      self.send(:update, self.id, new_obj)
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

  def destroy
    self.class.destroy(self.id)
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
