require 'ffmpeg/class_methods'
require 'ffmpeg/main_options'
require 'ffmpeg/file_extensions'
require 'ffmpeg/video_options'
require 'ffmpeg/video_advanced_options'
require 'ffmpeg/audio_options'
require 'ffmpeg/ffmpeg_command'
require 'ffmpeg/helper_methods'
require 'ffmpeg/meta_data'
require 'ffmpeg/presets'

module FFMpeg
  include HelperMethods
  include MainOptions
  include VideoOptions
  include VideoAdvancedOptions
  include AudioOptions
  include MetaData

  #
  # When mixed into a class, extend
  # it with the ClassMethods module
  #
  def self.included(klass)
    klass.extend ClassMethods
  end

  #
  # Runs an FFmpegCommand for converting files:
  #
  #  convert "file1.ext", :to => "file2.ext" do
  #    seek       "00:03:00"
  #    duration   "01:10:00"
  #    resolution "800x600"
  #  end
  #
  def convert(from_file, opts = {})
    FFMpegCommand.clear
    FFMpegCommand << "-i #{from_file}"

    Presets[opts[:preset]][:block].call if opts[:preset]

    yield if block_given?

    if opts[:preset] && !opts[:to]
      opts[:to] = Presets[opts[:preset]][:extension]
    end

    build_output_file_name(from_file, opts[:to]) do |file_name|
      FFMpegCommand << file_name
    end

    # run the command
    execute_command("#{ffmpeg_path} #{FFMpegCommand.command}", opts[:verbose])

    # return the metadata in json format
    return `exiftool -n -j #{opts[:to]}`
  end

  # Get the video bitrate
  def get_video_bitrate(from_file)
    # line will look like: Duration: 00:00:46.54, start: 0.000000, bitrate: 3342 kb/s
    line = `#{ffmpeg_path} -i #{from_file} 2>&1 | grep bitrate`
    bitrate = line.match(/\d+/, line.index('bitrate'))[0]
    return "#{bitrate}k"
  end

  # Add a thumbnail for the video
  def add_thumbnail(from_file, to_file, width=480, height=360, frame=1)
    execute_command("#{ffmpeg_path} -i #{from_file} -an -f rawvideo -s #{width}x#{height} -vframes #{frame} -vcodec png #{to_file}", false)
  end

  # Set up the video merge for a single video with named pipes
  # Output_file should be an mpg file
  def setup_merge(input_file, output_file, bitrate)
    # create a temporary pipe; example: mkfifo 1.mpg
    `mkfifo #{output_file}`

    # put this command in a separate thread
    Thread.new do
      # set up the mpg temporary video; example: ffmpeg -i 1.mp4 -b:v 3342k 1.mpg < /dev/null &
      execute_command("#{ffmpeg_path} -i #{input_file} -b:v #{bitrate} -y #{output_file} < /dev/null")
    end
  end

  # Execute the actual video merge
  # video ids are the names of the videos in the output_dir
  # Creates a new video called video.mp4 in output_dir
  def execute_merge(output_dir, video_ids, bitrate)
    # set up the cat command
    cat_command = "cat"
    video_ids.each { |video_id| cat_command += " #{output_dir}#{video_id}.mpg" }

    # do the merge; example: cat 1.mpg 2.mpg | ffmpeg -f mpeg -i - -b:v 3342k -strict experimental new.mp4
    execute_command("#{cat_command} | #{ffmpeg_path} -f mpeg -i - -b:v #{bitrate} -strict experimental -y #{output_dir}video.mp4")

    # clean up temporary pipes; example: rm 1.mpg
    video_ids.each { |video_id| `rm #{output_dir}#{video_id}.mpg` }

    # return the metadata in json format
    return `exiftool -n -j #{output_dir}video.mp4`
  end

  #
  # Explicitly set ffmpeg path
  #
  def ffmpeg_path(path)
    @@ffmpeg_path = path
  end

  def ffmpeg_path
    @@ffmpeg_path ||= locate_ffmpeg
  end

  private

  def build_output_file_name(from_file, to_file)
    return if to_file.nil?
    if FileExtensions::EXT.include?(to_file.to_s)
      yield from_file.gsub(/#{File.extname(from_file)}$/, ".#{to_file}")
    else
      yield "#{to_file}"
    end
  end

  #
  # Tries to locate the FFmpeg executable
  #
  def locate_ffmpeg
    ffmpeg_executable = %x[which ffmpeg].strip
    unless ffmpeg_executable
      raise RuntimeError, "Couldn't locate ffmpeg. Please specify an explicit path with the ffmpeg_path=(path) method"
    end
    ffmpeg_executable
  end

  #
  # Executes FFmpeg with the specified command
  #
  def execute_command(cmd, verbose = true)
    puts "Executing: #{cmd}" if verbose
    cmd += " > /dev/null 2>&1" if verbose
    %x[#{cmd}]
    success = $?.success?
    puts success if verbose
    success
  end
end

