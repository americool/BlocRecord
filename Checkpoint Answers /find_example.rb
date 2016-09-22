def find_by(attribute, value)
    # something like this?
    answer = connection.get_first_row <<-SQL
      SELECT * FROM #{table}
      WHERE #{attribute} = #{value};
    SQL
    answer
end
