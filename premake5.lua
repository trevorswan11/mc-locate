workspace "mclocate"
    architecture "x86_64"
    configurations { "Debug", "Release" }
    startproject "mclocate"

    flags { "MultiProcessorCompile" }

outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"

project "mclocate"
    location "build"
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++17"

    targetdir ("%{wks.location}/bin/" .. outputdir .. "/%{prj.name}")
    objdir ("%{wks.location}/bin-int/" .. outputdir .. "/%{prj.name}")

    files {
        "src/**.cpp",
        "src/**.hpp",
        "include/**.cpp",
        "include/**.hpp"
    }

    includedirs {
        "include"
    }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "MCL_DEBUG" }
        runtime "Debug"
        symbols "On"

    filter "configurations:Release"
        defines { "MCL_RELEASE" }
        runtime "Release"
        optimize "On"

    filter {}

    filter "system:windows"
    postbuildcommands {
        'if not exist "%{cfg.targetdir}\\assets" mkdir "%{cfg.targetdir}\\assets"',
        'xcopy /E /Q /Y /I "..\\assets" "%{cfg.targetdir}\\assets" > nul'
    }

    filter "system:linux or system:macosx"
        postbuildcommands {
            'mkdir -p %{cfg.targetdir}/assets',
            'cp -r ../assets/* %{cfg.targetdir}/assets'
        }

    filter {}
    