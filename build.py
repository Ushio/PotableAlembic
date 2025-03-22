import os
import shutil
import subprocess
from pathlib import Path
import re

def run_command(command):
    subprocess.run(command, shell=True, check=True)

# --alembic--
if not os.path.exists('alembic'):
    run_command("git clone https://github.com/alembic/alembic")

# checkout 1.8.8
os.chdir('alembic')
run_command("git checkout 43a1489a0f5e15420e4be7225df86e819884b6fa")
os.chdir('..')

if not os.path.exists('src_alembic'):
    os.makedirs('src_alembic')
abc = 'src_alembic/Alembic'
os.makedirs(abc, exist_ok=True)

for src_dir in os.listdir('alembic/lib/Alembic'):
    src_path = os.path.join('alembic/lib/Alembic', src_dir)
    if not os.path.isdir(src_path):
        continue

    name = os.path.basename(src_path)
    if name == 'AbcCoreHDF5':
        continue

    to_dir = os.path.join(abc, name)
    os.makedirs(to_dir, exist_ok=True)
        
    for header in os.listdir(src_path):
        if header.endswith('.h'):
            shutil.copy(os.path.join(src_path, header), os.path.join(to_dir, header))

    for cpp in os.listdir(src_path):
        if cpp.endswith('.cpp'):
            new_name = f"{Path(cpp).stem}_{name}.cpp"
            shutil.copy(os.path.join(src_path, cpp), os.path.join(to_dir, new_name))

# Version for config.h
with open('alembic/CMakeLists.txt') as cmakelists:
    cmake_data = cmakelists.read()
    var = re.search(r'PROJECT\(Alembic VERSION (\d+)\.(\d+)\.(\d+)\)', cmake_data)
    major = var.group(1)
    minor = var.group(2)
    patch = var.group(3)

print(f"alembic {major}.{minor}.{patch}")

with open('alembic/lib/Alembic/Util/Config.h.in') as config_file:
    config = config_file.read()

config = config.replace('${PROJECT_VERSION_MAJOR}', major)
config = config.replace('${PROJECT_VERSION_MINOR}', minor)
config = config.replace('${PROJECT_VERSION_PATCH}', patch)
config = config.replace('#cmakedefine', '// #cmakedefine')

with open(os.path.join(abc, "Util/Config.h"), 'w') as config_out:
    config_out.write(config)

# # fix windows "W, A" problem
# istream_ogawa_path = 'src_alembic/Alembic/Ogawa/IStreams_Ogawa.cpp'
# with open(istream_ogawa_path, 'r') as istream_file:
#     istream_ogawa = istream_file.read()

# istream_ogawa = istream_ogawa.replace('CreateFile(', 'CreateFileA(')

# with open(istream_ogawa_path, 'w') as istream_file:
#     istream_file.write(istream_ogawa)

# OpenExr
if not os.path.exists('openexr'):
    run_command("git clone https://github.com/AcademySoftwareFoundation/openexr")

# checkout 2.5.5
os.chdir('openexr')
run_command("git checkout b6eeef0de09e80d4858fa6ee4a699eef2c9613b5")
if os.path.exists("build"):
    shutil.rmtree("build")
os.makedirs("build")
os.chdir('build')
run_command("cmake -DZLIB_LIBRARY=../../zlib/zlib-1.2.11 -DZLIB_INCLUDE_DIR=../../zlib/zlib-1.2.11 ..")
os.chdir('../../')

# # Move to src
to_dir = 'src_Imath'
os.makedirs(to_dir, exist_ok=True)

shutil.copy("openexr/build/IlmBase/config/IlmBaseConfig.h", "src_Imath/IlmBaseConfig.h")
shutil.copy("openexr/build/IlmBase/config/IlmBaseConfigInternal.h", "src_Imath/IlmBaseConfigInternal.h")

for name in ['Half', 'Iex', 'IexMath', 'IlmThread', 'Imath']:
    src_dir = os.path.join('openexr/IlmBase', name)
    for header in os.listdir(src_dir):
        if header.endswith('.h'):
            shutil.copy(os.path.join(src_dir, header), os.path.join(to_dir, header))

    for cpp in os.listdir(src_dir):
        if cpp.endswith('.cpp') and not (cpp.startswith("eLut") or cpp.startswith("toFloat")):
            new_name = f"{Path(cpp).stem}_{name}.cpp"
            shutil.copy(os.path.join(src_dir, cpp), os.path.join(to_dir, new_name))

# OpenExr
os.makedirs('src_openexr', exist_ok=True)
os.makedirs('src_openexr/OpenEXR', exist_ok=True)

shutil.copy("openexr/build/OpenEXR/config/OpenEXRConfig.h", "src_openexr/OpenExr/OpenEXRConfig.h")
shutil.copy("openexr/build/OpenEXR/config/OpenEXRConfigInternal.h", "src_openexr/OpenExr/OpenEXRConfigInternal.h")

to_dir = 'src_openexr/OpenEXR'

for name in ['IlmImf', 'IlmImfUtil']:
    src_dir = os.path.join('openexr/OpenEXR', name)
    for header in os.listdir(src_dir):
        if header.endswith('.h'):
            shutil.copy(os.path.join(src_dir, header), os.path.join(to_dir, header))

    for cpp in os.listdir(src_dir):
        if cpp.endswith('.cpp') and cpp.startswith("Imf"):
            new_name = f"{Path(cpp).stem}_{name}.cpp"
            shutil.copy(os.path.join(src_dir, cpp), os.path.join(to_dir, new_name))

# zlib
to_dir = 'src_zlib'
os.makedirs(to_dir, exist_ok=True)

for src in os.listdir('zlib/zlib-1.2.11'):
    if src.endswith('.c') or src.endswith('.h'):
        shutil.copy(os.path.join('zlib/zlib-1.2.11', src), os.path.join(to_dir, src))

# Copy licenses and readme
shutil.copy('openexr/LICENSE.md', 'src_openexr/LICENSE-openexr2.5.5.txt')
shutil.copy('alembic/NEWS.txt', 'src_alembic/NEWS-alembic.txt')
shutil.copy('alembic/LICENSE.txt', 'src_alembic/LICENSE-alembic.txt')
shutil.copy('zlib/zlib-1.2.11/README', 'src_zlib/README-zlib.txt')

print('Done.')
