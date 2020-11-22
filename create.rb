require 'shellwords'
require 'fileutils'
require 'open-uri'
require 'rubygems/package'
require 'zlib'

# --alembic--
system("git clone https://github.com/alembic/alembic") unless Dir.exist?('alembic')

# checkout 1.7.16
Dir.chdir('alembic')
system("git checkout 7e5cf9b896f4299117457f36a7bf47d962cd0ebf")
Dir.chdir('..')

Dir.mkdir('src_alembic') unless Dir.exist?('src_alembic')
abc = 'src_alembic/Alembic'
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
istream_ogawa_path = 'src_alembic/Alembic/Ogawa/IStreams_Ogawa.cpp'
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
to_dir = 'src_ilmbase'
src_list = ['Half','Iex','IexMath','IlmThread', 'Imath']

Dir.mkdir(to_dir) unless Dir.exist?(to_dir)

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
        new_name = File.basename(cpp, ".*") + File.extname(cpp)
        FileUtils.copy(cpp, File.join(to_dir, new_name))
        
        # name = File.basename(cpp, '.*')
        # new_name = File.basename(cpp, ".*") + "_" + name + File.extname(cpp)
        # FileUtils.copy(cpp, File.join(to_dir, new_name))
    end
}

# config is messy, so just copy from configured file
# cd openexr
# mkdir build
# cd build
# cmake .. -G "Visual Studio 16 2019" -DZLIB_INCLUDE_DIR=../../zlib/zlib-1.2.11 -DZLIB_LIBRARY=../../zlib/bin/

config_win = File.read('IlmBaseConfig_win.h');
File.write('src_ilmbase/IlmBaseConfig.h', config_win)

config_internal_win = File.read('IlmBaseConfigInternal_win.h');
File.write('src_ilmbase/IlmBaseConfigInternal.h', config_internal_win)

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
to_dir = 'src_zlib'
Dir.mkdir(to_dir) unless Dir.exist?(to_dir)
Dir.glob('zlib/zlib-1.2.11/*.[ch]') do |src|
    name = File.basename(src, '.*')
    new_name = File.basename(src, ".*") + File.extname(src)
    FileUtils.copy(src, File.join(to_dir, new_name))
end

# Copy
FileUtils.copy('openexr/LICENSE.md', 'src_openexr/LICENSE-openexr2.5.3.txt')
FileUtils.copy('alembic/NEWS.txt', 'src_alembic/NEWS-alembic.txt')
FileUtils.copy('alembic/LICENSE.txt', 'src_alembic/LICENSE-alembic.txt')
FileUtils.copy('zlib/zlib-1.2.11/README', 'src_zlib/README-zlib.txt')

puts 'Done.'
