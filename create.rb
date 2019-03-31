require 'shellwords'
require 'fileutils'
require 'open-uri'
require 'rubygems/package'
require 'zlib'

# --alembic--
system("git clone https://github.com/alembic/alembic") unless Dir.exist?('alembic')

## checkout 1.7.10
Dir.chdir('alembic')
system("git checkout 4b64fa413298d4aa4f6f013e8ffdd7bfc1a1a2bc")
Dir.chdir('..')

Dir.mkdir('src') unless Dir.exist?('src')
abc = 'src/Alembic'
Dir.mkdir(abc) unless Dir.exist?(abc)

Dir.glob('alembic/lib/Alembic/*') do |src_dir|
    if !File.directory?(src_dir) then
        next
    end

    name = File.basename(src_dir)

    ## I don't support HDF5
    if name == 'AbcCoreHDF5' then
        next
    end

    to_dir = File.join(abc, File.basename(src_dir))
    Dir.mkdir(to_dir) unless Dir.exist?(to_dir)

    Dir.glob(File.join(src_dir, "*.h")) do |header|
        FileUtils.copy(header, File.join(to_dir, File.basename(header)))
    end

    Dir.glob(File.join(src_dir, "*.cpp")) do |cpp|
        new_name = File.basename(cpp, ".*") + "_" + name + File.extname(cpp)
        FileUtils.copy(cpp, File.join(to_dir, new_name))
    end
end

# Version for config.h
cmakelists = File.read('alembic/CMakeLists.txt')
major = cmakelists.match(/SET\(PROJECT_VERSION_MAJOR \"(\d+)\"\)/)[1]
minor = cmakelists.match(/SET\(PROJECT_VERSION_MINOR \"(\d+)\"\)/)[1]
patch = cmakelists.match(/SET\(PROJECT_VERSION_PATCH \"(\d+)\"\)/)[1]

puts "alembic #{major}.#{minor}.#{patch}"

config = File.read('alembic/lib/Alembic/Util/Config.h.in')
config = config.sub(/\${PROJECT_VERSION_MAJOR}/, major)
config = config.sub(/\${PROJECT_VERSION_MINOR}/, minor)
config = config.sub(/\${PROJECT_VERSION_PATCH}/, patch)

config = config.gsub(/#cmakedefine/, '// #cmakedefine')

File.write(File.join(abc, "Util/Config.h"), config)

# fix windows "W, A" problem

istream_ogawa_path = 'src/Alembic/Ogawa/IStreams_Ogawa.cpp'
istream_ogawa = File.read(istream_ogawa_path)
istream_ogawa = istream_ogawa.gsub(/CreateFile\(/, 'CreateFileA(')
File.write(istream_ogawa_path, istream_ogawa)

# --ilmbase--
ilmbase_url = "http://download.savannah.nongnu.org/releases/openexr/ilmbase-2.2.0.tar.gz"
zip_data = File.basename(ilmbase_url)
ilmbase_src = 'ilmbase-2.2.0'
if !File.exist?(zip_data) then
    open(zip_data, 'wb') do |file|
        open(ilmbase_url) do |data|
            file.write(data.read)
        end
    end
end

if !Dir.exist?(ilmbase_src) then
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(zip_data))
    tar_extract.rewind # The extract has to be rewinded after every iteration
    tar_extract.each do |entry|
      if entry.directory? then
        Dir.mkdir(entry.full_name) unless Dir.exist?(entry.full_name)
      else
        # File.write(entry.full_name, entry.read)
        open(entry.full_name, 'wb') do |file|
            file.write(entry.read)
        end
      end
    end
    tar_extract.close
end


to_dir = 'src'
src_list = ['Half','Iex','IexMath','IlmThread', 'Imath']
src_list.each{ |name|
    src_dir = File.join(ilmbase_src, name)

    Dir.glob(File.join(src_dir, "*.h")) do |header|
        FileUtils.copy(header, File.join(to_dir, File.basename(header)))
    end

    Dir.glob(File.join(src_dir, "*.cpp")) do |cpp|
        name = File.basename(cpp, '.*')
        if name == 'toFloat' then
            next
        end
        if name == 'eLut' then
            next
        end

        new_name = File.basename(cpp, ".*") + "_" + name + File.extname(cpp)
        FileUtils.copy(cpp, File.join(to_dir, new_name))
    end
} 

FileUtils.copy(File.join(ilmbase_src, 'config.windows/IlmBaseConfig.h'), 'src/IlmBaseConfig.h')
FileUtils.copy('toFloat.h', 'src/toFloat.h')
FileUtils.copy('eLut.h', 'src/eLut.h')

puts 'Done. you can use "src" folder.'
