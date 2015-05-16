require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'uri'
require 'rexml/document'
require 'nokogiri'
require 'cgi'

MAIL = ENV["NICO_MAIL"]
PASS = ENV["NICO_PASS"]
ALL_MODE = false #trueにしたらurl先の動画全てDL
#ALL_MODE = true
original_file_name = Time.now.strftime("%Y%m%d")
#original_file_name = "pinokio"
FILE_PATH = "./files/#{original_file_name}" #保存先のディレクトリ
urls = [] #保存したい動画検索ページのurl

#vocaloid新曲リンク 再生数多い順
urls << "http://www.nicovideo.jp/tag/#{URI.escape("VOCALOID新曲リンク")}?sort=v"
#vocaloid 24時間以内の投稿 再生数多い順
urls << "http://www.nicovideo.jp/tag/#{URI.escape("VOCALOID")}?sort=v&f_range=1"
#urls << "http://www.nicovideo.jp/mylist/11284855"

agent = Mechanize.new
agent.post("https://secure.nicovideo.jp/secure/login?site=niconico","mail"=> MAIL,"password"=> PASS)


def get_dl_ids(urls, agent)
  ids = []
  urls.each do |url|
    puts "DL url:" + url
    agent.get(url) do |page|
      doc = Nokogiri::HTML(page.body)
      if ALL_MODE
        doc.xpath("//a").each {|a|
          id = a[:href].match(%r{/watch/sm(.+)\?})[1] if !a[:href].match(%r{/watch/sm(.+)\?}).nil?
          ids << id
        }
      else
        doc.xpath("//body/div[2]/div/div[1]/div[4]/ul/li").each {|item|
          a = item.xpath("div[1]/div[1]/div/div[@class='itemThumb']").css(".itemThumbWrap")
          id = a[0][:href].match(%r{/watch/sm(.+)\?})[1] if !a[0][:href].match(%r{/watch/sm(.+)\?}).nil?
          ids << id
        }
      end
    end
  end
  return ids.uniq.compact
end

def get_dl_url(id, agent)
  agent.get("http://www.nicovideo.jp/watch/sm#{id}")
  moviedate = agent.get("http://www.nicovideo.jp/api/getflv?v=sm#{id}")
  map = {};
  moviedate.body.scan(/([^&]+)=([^&]*)/).each do |i|
      map[i[0]] = i[1];
  end
  return CGI::unescape(map["url"])
end

def get_dl_filename(id)
  doc = REXML::Document.new(open("http://ext.nicovideo.jp/api/getthumbinfo/sm#{id}"));
  filetype = doc.elements['nicovideo_thumb_response/thumb/movie_type'].text.to_s;
  title = doc.elements['nicovideo_thumb_response/thumb/title'].text.to_s
  return "#{FILE_PATH}/#{title}.#{filetype}"
end

def dl(ids, agent)
  ids.each_with_index do |id, i|
    puts  "No.#{i}, sm#{id}"
    begin
      open(get_dl_filename(id), "wb") do |j|
        puts  "No.#{i}, sm#{id} DL start!"
        j.print agent.get_file(get_dl_url(id, agent));
        write_csv(id) #dl終了でcsvに書き込み
        puts  "sm#{id} is written on csv"
      end
    rescue
      puts  "sm#{id} has error"
    ensure
      sleep(200 * rand(4..9))
      next
    end
  end
end

def csv_ids_hash
  exist_ids = []
  open("dl_list.csv", "r"){|f| 
    f.each_line do |id|
      exist_ids << id.to_s.chomp
    end
  }
  return exist_ids
end

def write_csv(id)
  open("dl_list.csv", "a"){|f| 
    f.puts id
  }
end

ids = get_dl_ids(urls, agent)
dl_ids = ids - csv_ids_hash
puts "DL id lists"
p dl_ids
if dl_ids.length > 0
  FileUtils.mkdir_p(FILE_PATH) unless FileTest.exist?(FILE_PATH)
  dl(dl_ids, agent)
end
