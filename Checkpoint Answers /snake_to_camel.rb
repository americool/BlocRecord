def snake_to_camel(word)
  #Make first letter captialized
  #Make letter after any "_" captialized
  #remove "_"
  word.gsub!(/\A./){$&.upcase}
  word.gsub!(/_(.)/){$&.upcase}
  word.tr!("_", "")
end


a = snake_to_camel("blah_blah_blah")
puts a
