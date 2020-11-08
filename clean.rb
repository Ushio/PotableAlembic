require 'shellwords'
require 'fileutils'
require 'open-uri'
require 'rubygems/package'
require 'zlib'

FileUtils.rm_rf('alembic') unless !Dir.exist?('alembic')
FileUtils.rm_rf('openexr') unless !Dir.exist?('openexr')
FileUtils.rm_rf('ilmbase-2.2.0') unless !Dir.exist?('ilmbase-2.2.0')
FileUtils.rm_rf('src') unless !Dir.exist?('src')
FileUtils.rm_rf('src_openexr') unless !Dir.exist?('src_openexr')
FileUtils.rm_rf('src_zlib') unless !Dir.exist?('src_zlib')
FileUtils.rm('ilmbase-2.2.0.tar.gz') unless !File.exist?('ilmbase-2.2.0.tar.gz')
FileUtils.rm('zlib-1.2.11.tar.gz') unless !File.exist?('zlib-1.2.11.tar.gz')
