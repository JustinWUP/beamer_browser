require "sinatra"
require "time"

BEAMER = "/Applications/Beamer.app"
ROOT = "/Volumes/Media/Watching/"

get '/' do
  current_path = params[:path] != nil ? params[:path] : ROOT
  current_path = current_path.include?(ROOT) ? current_path : ROOT 
  back = ''
  playing = params[:playing] || true
  if(File.directory?(current_path)) 
    list = Dir.entries(current_path)
    directories, movies = [], []
    i = ii = 0
    list.each do |m|
      unless m.include?('.DS_Store')
        back = File.absolute_path(m, current_path) if m == '..'
        if File.directory?(File.absolute_path(m, current_path)) && !%w[. ..].include?(m)
          directories[ii] = {name: m, path: File.absolute_path(m, current_path) }
          ii += 1
        elsif %w[.mkv .avi .m2ts .mp4 .m4v].include?(File.extname(m)) 
          movies[i] = {name: m, path: File.absolute_path(m, current_path) }
          i += 1
        end
      end
    end
    current_show = `ls ~/projects/server/*.txt`
    unless current_show == ""
      current_array = current_show.split("+=+")
      last_time = Time.parse(current_array[0])
      if Time.now - last_time < 10000
        current_show = current_array[1].gsub(".txt", "") 
      else
        `rm ~/projects/server/*.txt`
         current_show = `lsof | grep "/Volumes/Media/Watching/"` 
         current_show = current_show == "" ? false : current_show.split("/Volumes/Media/Watching/")[1].gsub("TV Shows/", "").gsub("Movies/", "").gsub("\n", "")
         whoami = `whoami`
         whoami = whoami.gsub("\n", "")
         system("touch \"/Users/#{whoami}/projects/server/#{Time.now}+=+#{current_show}.txt\"") unless current_show == "false"
      end
    else
      current_show = false
    end
    erb :movies, :locals => {movies: movies, directories: directories, back: back, current_path: current_path, current_show: current_show, playing: false}
  else
     system("open -a #{BEAMER} \"#{current_path}\"")
     `rm ~/projects/server/*.txt`
     whoami = `whoami`
     whoami = whoami.gsub("\n", "")
     system("touch \"/Users/#{whoami}/projects/server/#{Time.now}+=+#{File.basename(current_path)}.txt\"")
     erb :movies, :locals => {movies: movies, directories: directories, back: File.dirname(current_path), current_path: current_path, playing: true}
  end
end


