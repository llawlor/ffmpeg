require 'rubygems'
require 'rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ffmpeg'
include FFMpeg

RSpec.configure do |config|
end
