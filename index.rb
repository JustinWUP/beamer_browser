require 'byebug'
require 'json'
require "sinatra"
require "time"
require "open-uri"

BEAMER = "/Applications/Beamer.app"
ROOT = "/Volumes/Media/Watching/"

class String
  def readable
    self.gsub('.', ' ')
    .split('720p')[0]
    .split('1080p')[0]
    .split('19')[0]
    .split('20')[0]
    .split('DvDRIP')[0]
    .split('DVDRIP')[0]
    .split('DvDrip')[0]
    .split('DVDrip')[0]
    .split('DVDRip')[0]
    .split('avi')[0]
    .split('m2ts')[0]
    .split('mp4')[0]
    .split('{')[0]
    .split('(')[0]
    .split('[')[0].split.map(&:capitalize).join(' ')
  end
end

class Utils
  def self.whoami
    whoami = `whoami`
    whoami.gsub("\n", "")
  end
end

class ITunes
  def self.art(query, entity)
    query, path = ITunes.parsed(query)
    begin
      art_file = File.open(path)
      art_file.read.length < 1  ? "/#{entity}.png" : URI.encode("/art_cache/#{query}.jpg")
    rescue Errno::ENOENT
      type = $current_path.include?('Movie') ? 'movie' : 'tvShow'
      itunes_search = "https://itunes.apple.com/search?term=#{query}&media=#{type}&limit=1"
      uri = URI(itunes_search)
      uri.open do |f|
        results = JSON.parse(f.read)["results"]
        if f.status.include? '40' or results.length < 1
          art_file = File.new(path, 'w+')
          return  "/#{entity}.png"
        else
          art_file = File.new(path, 'w+')
          art_getter = URI(results[0]['artworkUrl100'])
          art_file << art_getter.read
          results[0]['artworkUrl100']
        end
      end
    end
  end

  def self.description(query)
    query, path = ITunes.parsed(query)
    begin
      description_file = File.open(path)
      contents = description_file.read
      contents.length < 1  ? "" : "Description: " + contents
    rescue Errno::ENOENT
      uri = ITunes.api(query)
      uri.open do |f|
        results = JSON.parse(f.read)["results"]
        if f.status.include? '40' or results.length < 1
          description_file = File.new(path, 'w+')
          return  ""
        else
          description_file = File.new(path, 'w+')
          description_getter = results[0]['longDescription']
          description_file << description_getter
          "#{description_getter}"
        end
      end
    end
  end

  private

  def self.api(query)
    type = $current_path.include?('Movie') ? 'movie' : 'tvShow'
    itunes_search = "https://itunes.apple.com/search?term=#{query}&media=#{type}&limit=1"
    URI(itunes_search)
  end

  def self.parsed(query)
    query = query.readable.gsub(' ', '-')
    caller = caller_locations(1,1)[0].label
    type = caller == 'art' ? 'jpg' : 'txt'
    path = "/Users/#{Utils.whoami}/projects/server/public/#{caller}_cache/#{query}.#{type}"
    return query, path
  end
end


get '/' do
  $current_path = params[:path] != nil ? params[:path] : ROOT
  $current_path = $current_path.include?(ROOT) ? $current_path : ROOT 
  back = ''
  playing = params[:playing] || true
  if(File.directory?($current_path)) 
    list = Dir.entries($current_path)
    directories, movies = [], []
    i = ii = 0
    list.each do |m|
      unless m.include?('.DS_Store')
        back = File.absolute_path(m, $current_path) if m == '..'
        if File.directory?(File.absolute_path(m, $current_path)) && !%w[. ..].include?(m)
          directories[ii] = {name: m, path: File.absolute_path(m, $current_path) }
          ii += 1
        elsif %w[.mkv .avi .m2ts .mp4 .m4v].include?(File.extname(m)) 
          movies[i] = {name: m, path: File.absolute_path(m, $current_path) }
          i += 1
        end
      end
    end
    current_show = `ls ./*.txt`
    unless current_show == ""
      current_array = current_show.split("+=+")
      last_time = Time.parse(current_array[0])
      if Time.now - last_time < 10000
        current_show = current_array[1].gsub(".txt", "") 
      else
        `rm ./*.txt`
         current_show = `lsof | grep "#{ROOT}"` 
         current_show = current_show == "" ? false : current_show.split(ROOT)[1].gsub("TV Shows/", "").gsub("Movies/", "").gsub("\n", "")
         system("touch \"/Users/#{Utils.whoami}/projects/server/#{Time.now}+=+#{current_show}.txt\"") unless current_show == "false"
      end
    else
      current_show = false
    end
    erb :movies, :locals => {movies: movies, directories: directories, back: back, current_path: $current_path, current_show: current_show, playing: false}
  else
     system("open -a #{BEAMER} \"#{$current_path}\"")
     `rm ./*.txt`
     $currently_playing = $current_path
     system("touch \"/Users/#{Utils.whoami}/projects/server/#{Time.now}+=+#{File.basename($current_path)}.txt\"")
     erb :movies, :locals => {movies: movies, directories: directories, back: File.dirname($current_path), current_path: $current_path, playing: true}
  end
end

get '/settings' do
  erb :settings, :locals => {flash: ''}
end

get '/settings/clear_cache' do 
  `rm ./public/art_cache/*.*`
  `rm ./public/description_cache/*.*`
  erb :settings, :locals => {flash: 'Cache has been cleared.'}
end
get '/settings/close_beamer' do 
  `killall Beamer`
  `rm ./*.txt`
  $currently_playing = nil
  erb :settings, :locals => {flash: 'Beamer has been closed.'}
end
get '/settings/restart_beamer' do 
  if $currently_playing != nil
    `killall Beamer`
    system("open -a #{BEAMER} \"#{$currently_playing}\"")
    erb :settings, :locals => {flash: 'Beamer has been restarted.'}
  else
    `killall Beamer`
    erb :settings, :locals => {flash: 'Beamer has been closed.'}
  end
end
