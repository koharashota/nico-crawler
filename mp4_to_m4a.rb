dir_current = Dir.pwd + "/files"
Dir.foreach(dir_current) do |item|
  if /.*\.mp4/ =~ item
    file_orig = "./files/" + item
    file_new = file_orig.sub(/\.mp4/, ".m4a")
    File.rename(file_orig, file_new)
  end
end
