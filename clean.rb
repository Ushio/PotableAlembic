require 'shellwords'
require 'fileutils'
require 'open-uri'
require 'rubygems/package'
require 'zlib'

FileUtils.rm_rf('alembic') unless !Dir.exist?('alembic')
FileUtils.rm_rf('ilmbase-2.2.0') unless !Dir.exist?('ilmbase-2.2.0')
FileUtils.rm_rf('src') unless !Dir.exist?('src')
FileUtils.rm('ilmbase-2.2.0.tar.gz') unless !File.exist?('ilmbase-2.2.0.tar.gz')
