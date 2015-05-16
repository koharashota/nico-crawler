dir_current = Dir.pwd + "/files"
Dir.foreach(dir_current) do |item|
  puts item
  if /.*\.m4a/ =~ item
    file_orig = "./files/" + item
    file_new = file_orig.sub(/\.m4a/, ".mp4")
    File.rename(file_orig, file_new)
  end
end
