require 'sqlite3'
require 'bloc_record/utility'

module Schema
  def table
    BlocRecord::Utility.underscore(name)
  end

  def columns
    schema.keys
  end

  def attributes
    columns - ["id"]
  end

  def schema
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

  def count
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end

  def sql_strings(value)
    case value
    when String
      "'#{value}'"
    when Numeric
      value.to_s
    else
      "null"
    end
  end

  def convert_keys(options)
    options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
    options
  end 
end
