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
  # Sets up an FFmpegCommand for converting files:
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
  end

  # Add a thumbnail for the video
  def add_thumbnail(from_file, to_file, width=480, height=360, frame=1)
    @@ffmpeg_path ||= locate_ffmpeg
    execute_command("#{@@ffmpeg_path} -i #{from_file} -an -f rawvideo -s #{width}x#{height} -vframes #{frame} -vcodec png #{to_file}", false)
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

  #
  # Runs ffmpeg
  #
  def run(verbose = false)
    @@ffmpeg_path ||= locate_ffmpeg
    execute_command("#{@@ffmpeg_path} #{FFMpegCommand.command}", verbose)
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

