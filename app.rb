require 'sinatra'
require 'date'
require 'ftools'
require 'fileutils'
require 'digest/sha1'
require 'zipruby'
require 'chronic'
require 'json'



# Default action is to allow the user to upload a new file
get '/' do
  erb :upload, :locals => { :queue => Dir[File.join(File.dirname(__FILE__), "uploads", "*")].count }
end


# simple jukebox playback
get '/play/?' do
  today = Date.today
  t = Time.mktime(today.year, today.month, today.day)
  redirect "/play/%i" % t.to_i
end


get '/play/:prior_file_time' do |prior_file_time|
  sound_path = next_audio(prior_file_time)
  if (sound_path!=0 and File.exists? sound_path) then
    @sound_file = File.basename sound_path
    @upload_time = File.ctime(sound_path)
    @file_time = File.ctime(sound_path).to_i
    erb :play
  else
    erb :waiting, :locals => { :note => "End of queue reached." }
  end
end

get '/playlist.m3u' do
  audio_files = Dir[File.join(File.dirname(__FILE__), "uploads", "*")].sort_by{ |f| File.ctime(f) }
  content_type "audio/mpegurl"
  erb :playlist, :locals => { :tracks => audio_files }, :layout => false
end


def next_audio prior_file_time
  audio_files = Dir[File.join(File.dirname(__FILE__), "uploads", "*")].sort_by{ |f| File.ctime(f) }
  audio_files.each do |f|
    if (File.ctime(f).to_i > prior_file_time.to_i) then
      return f
    end
  end
  return 0
end

get '/seek/:offset' do |offset|
	p Chronic.parse(offset)
	t = Chronic.parse(offset)
	if t then
		redirect "/play/%i" % t.to_i
	else
		redirect "/play"
	end
end





# Any file posted to the root is added to the jukebox
post '/' do
  
  filetypes = [".mp3",".mp4",".m4a"]
  
  if request.xhr?
    json_return = []
    
    params[:files].each do |afile|
      unless afile && (tmpfile = afile[:tempfile]) && (name = afile[:filename])
        @error = "No file selected"
        #erb :upload, :locals => { :error_string => @error }
        json_return.push({:name => "No file arrived."})
      else
        tmpfile   = afile[:tempfile].path
        filename  = afile[:filename]
        extension = File.extname filename
  
        # rudimentary test for the correct filetype
        # should probably use the content-type: audio/xxx instead
        unless filetypes.include? extension.downcase
          @error = "Bad filetype, please only upload files of the following types: %s" % filetypes.join(", ")
          #erb :upload, :locals => { :error_string => @error }
          json_return.push({:name => "Only %s allowed" % filetypes.to_s})
        else
          # move the file into app directory
          hashname = Digest::SHA1.hexdigest(filename + Time.now.to_s)
          outfile   = File.join(".", "uploads", "%s%s" % [hashname, extension])
          FileUtils.mv tmpfile, outfile
          #note = "'%s' uploaded successfully." % afile[:filename]
          #erb :upload, :locals => { :note => note }
          json_return.push({:name => afile[:filename], :size => File.size(outfile)})
        end
      end
    end
  
    content_type :json
    json_return.to_json
    
  else
    afile = params[:files][0]
    unless afile && (tmpfile = afile[:tempfile]) && (name = afile[:filename])
      @error = "No file selected"
      erb :upload, :locals => { :error_string => @error }
    else
      tmpfile   = afile[:tempfile].path
      filename  = afile[:filename]
      extension = File.extname filename
  
      # rudimentary test for the correct filetype
      # should probably use the content-type: audio/xxx instead
      unless filetypes.include? extension.downcase
        @error = "Bad filetype, please only upload files of the following types: %s" % filetypes.join(", ")
        erb :upload, :locals => { :error_string => @error }
      else
        # move the file into app directory
        hashname = Digest::SHA1.hexdigest(filename + Time.now.to_s)
        outfile   = File.join(".", "uploads", "%s%s" % [hashname, extension])
        FileUtils.mv tmpfile, outfile
        note = "'%s' uploaded successfully." % afile[:filename]
        erb :upload, :locals => { :note => note }
      end
    end
    
  end
  
end



# Play a file
get '/audio/:needle' do |needle|
    srcpath = File.join(".", "uploads", "%s" % needle)
    # Check if file exists
    if (File.exists? srcpath) then
      send_file srcpath
    else
      erb :index, :locals => { :error_string => "File not found." }
    end
end



get '/archive' do
  output = archive_files
  archives = []
  Dir.glob("archive/*").each do |entry|
    archives.push entry if File.directory? entry
  end
  archives
end



get '/replay/:day_string' do |day_string|
  # replay a full day
end







def delete_old_files
  Dir.chdir File.dirname(__FILE__)
  two_weeks_ago = DateTime.now - 14
  n = 0
  Dir.glob("uploads/*.zip").each do |f|
    if (DateTime.parse(File.mtime(f).to_s)<two_weeks_ago) then
      File.delete(f)
      n += 1
    end
  end
  n
end




def archive_files
  now = Time.now
  midnight = Time.mktime(now.year, now.month, now.day)
  Dir.foreach(File.join(File.dirname(__FILE__), "uploads")) do |f|
    path = File.join(File.dirname(__FILE__),"uploads",f)
    if (File.file? path) then
      file_time = File.ctime(path)
    	if (file_time.to_i < midnight.to_i) then
        day_string = "%i-%02i-%02i" % [file_time.year, file_time.month, file_time.day]
        archive_path = File.join(File.dirname(__FILE__), "archive", day_string)
        unless File.directory? archive_path then
          Dir.mkdir archive_path
        end
        FileUtils.mv path, File.join(archive_path, f)
    	end
    end
  end
end
  





class Numeric
  def to_human
    units = %w{B KB MB GB TB}
    e = (Math.log(self)/Math.log(1024)).floor
    s = "%.1f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end
