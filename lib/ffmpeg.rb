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
  #    video_duration   "01:10:00"
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

    # copy audio (avoids errors when bitrate set too high)
    FFMpegCommand << "-c:a copy"

    build_output_file_name(from_file, opts[:to]) do |file_name|
      FFMpegCommand << file_name
    end

    # run the command
    execute_command("#{ffmpeg_path} -y #{FFMpegCommand.command}", opts[:verbose])

    # return the metadata in json format
    return get_metadata(opts[:to])
  end

  # set the target correctly (for low-framerate videos)
  def set_target(from_file)
    framerate = exif_attribute(from_file, 'VideoFrameRate')
    # if framerate is below 20, set target differently
    return (framerate && framerate.to_i < 20) ? '-target ntsc-vcd' : ''
  end

  # ffmpeg command to get the bitrate line
  def bitrate_line(from_file)
    `#{ffmpeg_path} -i #{from_file} 2>&1 | grep bitrate`
  end

  # Get the video bitrate
  def get_video_bitrate(from_file)
    # line will look like: Duration: 00:00:46.54, start: 0.000000, bitrate: 3342 kb/s
    line = bitrate_line(from_file)

    # if line.index('bitrate') is nil, then error gets thrown: "no implicit conversion from nil to integer"
    # just wait 5 seconds and try again, since file may be done by then
    if line.index('bitrate').nil?
      sleep 5
      # try again
      line = bitrate_line(from_file)
    end

    bitrate = line.match(/\d+/, line.index('bitrate'))[0] if line.index('bitrate')
    return bitrate ? "#{bitrate}k" : nil
  end

  # Add a thumbnail for the video
  def add_thumbnail(from_file, to_file, width=480, height=360, frame=1)
    execute_command("#{ffmpeg_path} -i #{from_file} -an -f rawvideo -s #{width}x#{height} -vframes #{frame} -vcodec png #{to_file}", false)
  end

  # get all the metadata
  def get_metadata(file)
    return `exiftool -n -j #{file}`
  end

  # gets a specific attribute using exiftool
  def exif_attribute(file, attribute)
    return JSON.parse(get_metadata(file))[0][attribute]
  end

  # creates a random file name with the specified extension
  def random_file_name(extension)
    # use a large random number to avoid collisions
    return "#{rand(999999999999999).to_s}.#{extension}"
  end

  # Execute the actual video merge
  # input_files should be an array of files with the path and filename
  # Creates a new video called video.mp4 in output_dir
  def execute_merge(input_files, output_dir, bitrate, width=640, height=480)
    threads = []
    # create array of temporary mpg_files by using random names to prevent collisions
    mpg_files = []
    input_files.each do |input_file|
      dir = input_file.rindex('/') ? input_file[0...input_file.rindex('/')] : ''
      mpg_files << "#{dir}#{random_file_name('mpg')}"
    end

    input_files.each_with_index do |input_file, index|
      target = set_target(input_file)

      # put this command in a separate thread
      # set up the mpg temporary video; example: ffmpeg -i 1.mp4 -b:v 3342k 1.mpg
      threads << Thread.new do
        execute_command("#{ffmpeg_path} -i #{input_file} -b:v #{bitrate} -s #{width}x#{height} #{target} -y #{mpg_files[index]}")
      end
    end

    # wait for all threads to finish
    threads.each { |thread| thread.join }

    # set up the cat command
    cat_command = "cat"
    mpg_files.each { |mpg_file| cat_command += " #{mpg_file}" }

    # do the merge; example: cat 1.mpg 2.mpg | ffmpeg -f mpeg -i - -strict experimental new.mp4
    execute_command("#{cat_command} | #{ffmpeg_path} -f mpeg -i - -s #{width}x#{height} -strict experimental -y #{output_dir}video.mp4")

    # clean up temporary files; example: rm 1.mpg
    mpg_files.each { |mpg_file| `rm #{mpg_file}` }

    # return the metadata in json format
    return get_metadata("#{output_dir}video.mp4")
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

