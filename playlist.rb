#!/usr/bin/ruby
require 'date'
require 'fileutils'


# open up the file containing the last played file
# the file contains a single line with the path to the currently playing track
currently_playing = File.join(File.dirname(__FILE__), "currently_playing.path")
current_timestamp = 0
if (File.exists? currently_playing) then
	# Fetch the file and get the uplaod time
	track_path = File.open(currently_playing, 'r').gets
  current_timestamp = File.ctime(track_path) if File.exists? track_path
  
  # move to archive
  if (File.exists?(track_path)) then
    file_time = File.ctime(track_path)
    day_string = "%i-%02i-%02i" % [file_time.year, file_time.month, file_time.day]
    archive_path = File.join(File.dirname(__FILE__), "archive", day_string)
    unless File.directory? archive_path then
      Dir.mkdir archive_path
    end
    FileUtils.mv(track_path, File.join(archive_path, File.basename(track_path)))
    
  end
end

if (current_timestamp==0) then
	# If there is no file currently playing,
	# start playing from midnight on
	today = Date.today
	current_timestamp = Time.mktime(today.year, today.month, today.day)
end

next_track = ""

# look through the upload directory and find the next file
audio_files = Dir[File.join(File.dirname(__FILE__), "uploads", "*")].sort_by{ |f| File.ctime(f) }
audio_files.each do |f|
	if (File.ctime(f).to_i >= current_timestamp.to_i) then
		next_track = f
		File.open(currently_playing, 'w') { |f| f.write next_track }
		break
	end
end

if next_track=="" then
	# pick one of the filler sounds
	audio_files = Dir[File.join(File.dirname(__FILE__), "sounds", "*")]
	next_track = audio_files[rand(audio_files.length)]
end

puts next_track
