require 'shellwords'
require 'fileutils'
require 'open-uri'
require 'rubygems/package'
require 'zlib'

# --alembic--
system("git clone https://github.com/alembic/alembic") unless Dir.exist?('alembic')

# checkout 1.7.13
Dir.chdir('alembic')
system("git checkout cfe114639ef7ad084d61e71ab86a17e708d838ae")
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

# OpenExr
system("git clone https://github.com/AcademySoftwareFoundation/openexr") unless Dir.exist?('openexr')
# checkout 2.5.3
Dir.chdir('openexr')
system("git checkout c32f82c5f1833d959321fc5f615ca52836c7ba65")
Dir.chdir('..')
ilmbase_src = 'openexr/IlmBase' 

# Move to src
to_dir = 'src'
src_list = ['Half','Iex','IexMath','IlmThread', 'Imath']
src_list.each{ |name|
    src_dir = File.join(ilmbase_src, name)
    Dir.glob(File.join(src_dir, "*.h")) do |header|
        FileUtils.copy(header, File.join(to_dir, File.basename(header)))
    end
    Dir.glob(File.join(src_dir, "*.cpp")) do |cpp|
        if File.basename(cpp).start_with?("eLut") then
            next
        end
        if File.basename(cpp).start_with?("toFloat") then
            next
        end

        name = File.basename(cpp, '.*')
        new_name = File.basename(cpp, ".*") + "_" + name + File.extname(cpp)
        FileUtils.copy(cpp, File.join(to_dir, new_name))
    end
} 

config_win = File.read('IlmBaseConfig_win.h');
File.write('src/IlmBaseConfig.h', config_win)

config_internal_win = File.read('IlmBaseConfigInternal_win.h');
File.write('src/IlmBaseConfigInternal.h', config_internal_win)

# OpenExr
Dir.mkdir('src_openexr') unless Dir.exist?('src_openexr')

to_dir = 'src_openexr'
src_list = ['IlmImf', 'IlmImfUtil']
src_list.each{ |name|
    src_dir = File.join('openexr/OpenEXR', name)
    Dir.glob(File.join(src_dir, "*.h")) do |header|
        FileUtils.copy(header, File.join(to_dir, File.basename(header)))
    end
    Dir.glob(File.join(src_dir, "*.cpp")) do |cpp|
        if File.basename(cpp).start_with?("Imf") then
            new_name = File.basename(cpp, ".*") + "_" + name + File.extname(cpp)
            FileUtils.copy(cpp, File.join(to_dir, new_name))
        end
    end
}
config_win = File.read('OpenEXRConfig_win.h');
File.write('src_openexr/OpenEXRConfig.h', config_win)

config_internal_win = File.read('OpenEXRConfigInternal_win.h');
File.write('src_openexr/OpenEXRConfigInternal.h', config_internal_win)

# zlib
zlib_url = "https://zlib.net/zlib-1.2.11.tar.gz"
zip_data = File.basename(zlib_url)
if !File.exist?(zip_data) then
    URI.open(zip_data, 'wb') do |file|
        URI.open(zlib_url) do |data|
            file.write(data.read)
        end
    end
end

Dir.mkdir('src_zlib') unless Dir.exist?('src_zlib')

if !Dir.exist?(zip_data) then
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(zip_data))
    tar_extract.rewind # The extract has to be rewinded after every iteration
    tar_extract.each do |entry|
        name = entry.full_name.gsub!("zlib-1.2.11/","")
        if /^[^\/]+\.[ch]$/.match?(name) || name == 'zlib.3.pdf' then
            URI.open(File.join('src_zlib', name), 'wb') do |file|
                file.write(entry.read)
            end
        end
    end
    tar_extract.close
end

# Copy
FileUtils.copy(File.join(ilmbase_src, '../README.md'), 'src/LICENSE-openexr2.5.3');
FileUtils.copy('alembic/NEWS.txt', 'src/NEWS-alembic.txt');
FileUtils.copy('alembic/LICENSE.txt', 'src/LICENSE-alembic.txt');

puts 'Done.'
