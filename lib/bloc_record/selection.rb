require 'sqlite3'

module Selection

  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      begin
        ids.each do |x|
          x >= 0
        end
      rescue
        return puts "Invalid input"
      end
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table} WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    raise ArgumentError, 'ID must be at least 0' if id < 0 #had to change this from <= to < checkpoint4 to work with the address book selection in the menu

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def method_missing(method_name, *args, &block)
    first_part = method_name[0..6]
    second_part = method_name[8..-1]
    if first_part == "find_by"
      args.unshift(second_part)
      self.send(:find_by, *args)
    else
      super
    end
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table} WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_each(batch_hash={})
    find_in_batches(batch_hash) do |collection|
      collection.each do |record|
        yield record
      end
    end
  end

  def find_in_batches(batch_hash)
    if batch_hash.empty?
      connection.all.each do |item|
        yield item
      end
    else
      start = batch_hash[:start]
      limit = batch_hash[:batch_size]
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} LIMIT #{limit} OFFSET #{start}
      SQL
      yield rows_to_array(rows)
    end
  end

  def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
     SQL

     init_object_from_row(row)
  end

  def take(num=1)
    raise ArgumentError, 'Must be an Integer' unless num.is_a?(Integer)
    if num > 1
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT #{num};
     SQL
     rows_to_array(rows)
   else
     take_one
   end
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end


    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    case args.first
    when String
      if args.count > 1
        order = args.join(",")
      end
    when Hash
      order_hash = BlocRecord::Utility.convert_keys(args)
      order = order_hash.map {|key, value| "#{key} #{BlocRecord::Utility.sql_strings(value)}"}.join(",")
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map {|arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(arg.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{arg} ON #{arg.first}.#{table}_id = #{table}.id
        SQL
      end
    end
    rows_to_array(rows)
  end

  def joins(args)
    hash = BlocRecord::Utility.convert_keys(args)
    string = hash.map {|key, value| "#{key},#{BlocRecord::Utility.sql_strings(value)}"}.join(",")
    array = string.split(',')
    joins += array.each {|arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
    rows = connection.execute <<-SQL
      SELECT * FROM #{table} #{joins}
    SQL
    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
