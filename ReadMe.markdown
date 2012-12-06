Jukebox
=======

Highly simplified jukebox webapp. It allows anybody with the link to upload audio files to /approot/ and play all files, in the order of uploads from /approot/play

It uses the file creation times to identify the next audio file.

The streaming is handled by a combination of ezstream and icecast, requireing ffmpeg for m4a playback, and madplay for mp3 playback.


Planned
=======

After an upload indicate the number of audio tracks in front of you (ie in the queue).
