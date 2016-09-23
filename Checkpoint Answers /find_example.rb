def find_by(attribute, value)
    # something like this?
    connection.get_first_row <<-SQL
      SELECT * FROM #{self.table}
      WHERE #{attribute} = #{value};
    SQL
end
