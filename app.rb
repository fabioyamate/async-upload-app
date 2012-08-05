require 'sinatra'
require 'carrierwave'

DUMMY_GIF = (
  "GIF89a\x01\x00\x01\x00\x80\xFF\x00" <<
  "\xFF\xFF\xFF" << # color
  "\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;"
).freeze

# stub with string IO to not write in file system
class DummyFile < StringIO
  attr_reader :filepath

  def initialize(*args)
    super(*args[1..-1])
    @filepath = args[0]
  end

  def original_filename
    File.basename(filepath)
  end
end

module MyApp
  def self.root
    @_root ||= File.expand_path(File.dirname(__FILE__))
  end
end

CarrierWave.root = File.join(MyApp.root, "public")

class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def fake_cache!(file)
    dummy = DummyFile.new(file[:filename], DUMMY_GIF)
    cache!(dummy)
  end

  def cache_dir
    "#{MyApp.root}/tmp/uploads"
  end
end

get '/' do
  File.read("public/index.html")
end

get '/:file' do
  File.read(params[:file])
end

# temporary upload path
post '/upload' do
  content_type :html

  uploader = FileUploader.new
  uploader.fake_cache!(params["Filedata"])

  erb :upload, :locals => { :cache_name => uploader.cache_name }
end

# store temporary cache file
post '/store' do
  uploader = FileUploader.new
  uploader.retrieve_from_cache!(params["Filedata_cache"])

  uploader.store!

  "<a href='#{uploader.url}'>#{uploader.url}</a>"
end
