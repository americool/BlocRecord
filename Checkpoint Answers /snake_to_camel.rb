def snake_to_camel(word)
  #Make first letter captialized
  #Make letter after any "_" captialized
  #remove "_"
  word.gsub!(/\A[a-z]/){$&.upcase}
  word.gsub!(/_([a-z])/){$1.upcase}
end


a = snake_to_camel("blah_blah_blah")
puts a
