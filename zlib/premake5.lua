workspace "zlib"
    location "build"
    configurations { "Debug", "Release" }

architecture "x86_64"

project "zlib"
    kind "SharedLib"
    language "C++"
    targetdir "bin/"
    systemversion "latest"
    flags { "MultiProcessorCompile", "NoPCH" }

    defines {"ZLIB_DLL"}

    files { "zlib-1.2.11/*.c", "zlib-1.2.11/*.h" }
    includedirs { "zlib-1.2.11"}

    filter {"Debug"}
        runtime "Debug"
        targetname ("zlibd")
        optimize "Off"
        -- optimize "Full"
    filter {"Release"}
        runtime "Release"
        targetname ("zlib")
        optimize "Full"
    filter{}

