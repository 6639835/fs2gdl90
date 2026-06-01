cmake_minimum_required(VERSION 3.16)
project(fs2gdl90 VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(FS2GDL90_BUILD_XPLANE "Build the X-Plane plugin frontend" ON)
option(FS2GDL90_BUILD_MSFS "Build the MSFS 2020/2024 SimConnect frontend on Windows" OFF)
option(FS2GDL90_BUILD_TESTS "Build FS2GDL90 tests" OFF)
option(FS2GDL90_ENABLE_COVERAGE "Enable coverage instrumentation (tests only)" OFF)
option(FS2GDL90_ENABLE_SOCKET_OPS_TESTS "Expose socket ops helpers for tests" ON)

function(fs2gdl90_enable_coverage target_name)
    if(NOT FS2GDL90_ENABLE_COVERAGE)
        return()
    endif()

    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        target_compile_options(${target_name} PRIVATE
            -O0 -g -fprofile-instr-generate -fcoverage-mapping
        )
        get_target_property(_target_type ${target_name} TYPE)
        if(NOT _target_type STREQUAL "STATIC_LIBRARY")
            target_link_options(${target_name} PRIVATE -fprofile-instr-generate)
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${target_name} PRIVATE -O0 -g --coverage)
        get_target_property(_target_type ${target_name} TYPE)
        if(NOT _target_type STREQUAL "STATIC_LIBRARY")
            target_link_options(${target_name} PRIVATE --coverage)
        endif()
    else()
        message(WARNING "Coverage requested but compiler '${CMAKE_CXX_COMPILER_ID}' is not supported.")
    endif()
endfunction()

if(MSVC)
    function(fs2gdl90_set_msvc_runtime target_name)
        set_property(TARGET ${target_name} PROPERTY
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
        )
    endfunction()
endif()

if(APPLE AND (NOT DEFINED CMAKE_OSX_ARCHITECTURES OR CMAKE_OSX_ARCHITECTURES STREQUAL ""))
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
endif()

set(FS2GDL90_SDK_PATH "${CMAKE_SOURCE_DIR}/SDK")
set(FS2GDL90_IMGUI_DIR "${CMAKE_SOURCE_DIR}/third_party/imgui")

set(FS2GDL90_CORE_SOURCES
    src/core/encoder_support.cpp
    src/core/foreflight_encoder.cpp
    src/core/foreflight_protocol.cpp
    src/core/gdl90_encoder.cpp
    src/msfs/support.cpp
    src/core/protocol_utils.cpp
    src/core/settings.cpp
    src/core/settings_ui.cpp
    src/core/simple_json.cpp
    src/core/udp_broadcaster.cpp
    src/core/udp_receiver.cpp
)

set(FS2GDL90_PUBLIC_HEADERS
    include/fs2gdl90/foreflight_encoder.h
    include/fs2gdl90/foreflight_protocol.h
    include/fs2gdl90/gdl90_encoder.h
    include/fs2gdl90/msfs_support.h
    include/fs2gdl90/protocol_utils.h
    include/fs2gdl90/settings.h
    include/fs2gdl90/settings_ui.h
    include/fs2gdl90/simple_json.h
    include/fs2gdl90/simconnect_compat.h
    include/fs2gdl90/udp_broadcaster.h
    include/fs2gdl90/udp_receiver.h
)

add_library(fs2gdl90_core STATIC
    ${FS2GDL90_CORE_SOURCES}
    ${FS2GDL90_PUBLIC_HEADERS}
)
target_include_directories(fs2gdl90_core PUBLIC "${CMAKE_SOURCE_DIR}/include")
fs2gdl90_enable_coverage(fs2gdl90_core)
if(MSVC)
    fs2gdl90_set_msvc_runtime(fs2gdl90_core)
endif()
if(APPLE)
    set_target_properties(fs2gdl90_core PROPERTIES
        OSX_ARCHITECTURES "${CMAKE_OSX_ARCHITECTURES}"
    )
endif()
if(FS2GDL90_ENABLE_SOCKET_OPS_TESTS)
    target_compile_definitions(fs2gdl90_core PRIVATE FS2GDL90_ENABLE_SOCKET_OPS_TESTS=1)
endif()

set(FS2GDL90_XPLANE_IMGUI_SOURCES
    ${FS2GDL90_IMGUI_DIR}/imgui.cpp
    ${FS2GDL90_IMGUI_DIR}/imgui_draw.cpp
    ${FS2GDL90_IMGUI_DIR}/imgui_tables.cpp
    ${FS2GDL90_IMGUI_DIR}/imgui_widgets.cpp
    ${FS2GDL90_IMGUI_DIR}/backends/imgui_impl_opengl2.cpp
)

if(FS2GDL90_BUILD_XPLANE)
    set(FS2GDL90_XPLANE_OUTPUT_NAME "")
    set(FS2GDL90_XPLANE_LINK_FLAGS "")

    if(APPLE)
        message(STATUS "Configuring X-Plane frontend for macOS...")
        set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
        set(FS2GDL90_XPLANE_OUTPUT_NAME "mac")
        set(FS2GDL90_XPLANE_PLATFORM_DEFINITIONS APL=1 IBM=0 LIN=0)
        set(FS2GDL90_XPLANE_PLATFORM_LIBS
            "-F${FS2GDL90_SDK_PATH}/Libraries/Mac"
            "-framework XPLM"
            "-framework CoreFoundation"
            "-framework OpenGL"
        )
        set(FS2GDL90_XPLANE_LINK_FLAGS
            "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/mac_exports.txt"
        )
    elseif(WIN32)
        message(STATUS "Configuring X-Plane frontend for Windows...")
        set(FS2GDL90_XPLANE_OUTPUT_NAME "win")
        set(FS2GDL90_XPLANE_PLATFORM_DEFINITIONS APL=0 IBM=1 LIN=0 _CRT_SECURE_NO_WARNINGS)
        set(FS2GDL90_XPLANE_PLATFORM_LIBS
            "${FS2GDL90_SDK_PATH}/Libraries/Win/XPLM_64.lib"
            ws2_32
            opengl32
        )
        set(FS2GDL90_XPLANE_LINK_FLAGS "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/win_exports.def")
    elseif(UNIX)
        message(STATUS "Configuring X-Plane frontend for Linux...")
        set(FS2GDL90_XPLANE_OUTPUT_NAME "lin")
        set(FS2GDL90_XPLANE_PLATFORM_DEFINITIONS APL=0 IBM=0 LIN=1)
        set(FS2GDL90_XPLANE_PLATFORM_LIBS
            "${FS2GDL90_SDK_PATH}/Libraries/Lin/XPLM_64.so"
            dl
            GL
        )
        set(FS2GDL90_XPLANE_LINK_FLAGS
            "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/linux_exports.txt"
        )
    else()
        message(FATAL_ERROR "The X-Plane frontend is not configured for this platform.")
    endif()

    add_library(fs2gdl90_xplane MODULE
        src/xplane/plugin.cpp
        ${FS2GDL90_XPLANE_IMGUI_SOURCES}
    )
    target_include_directories(fs2gdl90_xplane PRIVATE
        "${FS2GDL90_SDK_PATH}/CHeaders/XPLM"
        "${CMAKE_SOURCE_DIR}/include"
        "${FS2GDL90_IMGUI_DIR}"
        "${FS2GDL90_IMGUI_DIR}/backends"
    )
    target_compile_definitions(fs2gdl90_xplane PRIVATE
        ${FS2GDL90_XPLANE_PLATFORM_DEFINITIONS}
        XPLM200=1
        XPLM300=1
        XPLM301=1
        XPLM400=1
        XPLM410=1
        XPLM411=1
    )
    if(MSVC)
        target_compile_options(fs2gdl90_xplane PRIVATE /W4 /EHsc)
    else()
        target_compile_options(fs2gdl90_xplane PRIVATE
            -fPIC
            -fvisibility=hidden
            -Wall
            -Wextra
            -Wformat
            -Wformat-security
        )
    endif()
    target_link_libraries(fs2gdl90_xplane PRIVATE
        fs2gdl90_core
        ${FS2GDL90_XPLANE_PLATFORM_LIBS}
    )
    set_target_properties(fs2gdl90_xplane PROPERTIES
        OUTPUT_NAME "${FS2GDL90_XPLANE_OUTPUT_NAME}"
        PREFIX ""
        SUFFIX ".xpl"
        LINK_FLAGS "${FS2GDL90_XPLANE_LINK_FLAGS}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_BINARY_DIR}"
    )
    if(MSVC)
        fs2gdl90_set_msvc_runtime(fs2gdl90_xplane)
    endif()

    install(TARGETS fs2gdl90_xplane
        LIBRARY DESTINATION "${CMAKE_SOURCE_DIR}/build/fs2gdl90/xplane/fs2gdl90"
        RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}/build/fs2gdl90/xplane/fs2gdl90"
    )
endif()

if(FS2GDL90_BUILD_MSFS)
    if(NOT WIN32)
        message(FATAL_ERROR "FS2GDL90_BUILD_MSFS is only supported on Windows because SimConnect is Windows-only.")
    endif()

    set(MSFS_SDK_PATH "$ENV{MSFS_SDK}" CACHE PATH "Microsoft Flight Simulator SDK root path")
    if(NOT MSFS_SDK_PATH AND DEFINED ENV{MSFS2020_SDK})
        set(MSFS_SDK_PATH "$ENV{MSFS2020_SDK}" CACHE PATH "Microsoft Flight Simulator SDK root path" FORCE)
    endif()
    if(NOT MSFS_SDK_PATH AND DEFINED ENV{MSFS2024_SDK})
        set(MSFS_SDK_PATH "$ENV{MSFS2024_SDK}" CACHE PATH "Microsoft Flight Simulator SDK root path" FORCE)
    endif()

    find_path(SIMCONNECT_INCLUDE_DIR
        NAMES SimConnect.h
        PATHS
            "${MSFS_SDK_PATH}/SimConnect SDK/include"
            "${MSFS_SDK_PATH}/SimConnect SDK/Include"
            "${MSFS_SDK_PATH}/include"
            "${MSFS_SDK_PATH}/Include"
        NO_DEFAULT_PATH
    )
    find_library(SIMCONNECT_LIBRARY
        NAMES SimConnect
        PATHS
            "${MSFS_SDK_PATH}/SimConnect SDK/lib"
            "${MSFS_SDK_PATH}/SimConnect SDK/Lib"
            "${MSFS_SDK_PATH}/lib"
            "${MSFS_SDK_PATH}/Lib"
        NO_DEFAULT_PATH
    )
    find_file(SIMCONNECT_RUNTIME_DLL
        NAMES SimConnect.dll
        PATHS
            "${MSFS_SDK_PATH}/SimConnect SDK/lib"
            "${MSFS_SDK_PATH}/lib"
            "${MSFS_SDK_PATH}/Lib"
        NO_DEFAULT_PATH
    )

    if(NOT SIMCONNECT_INCLUDE_DIR OR NOT SIMCONNECT_LIBRARY OR NOT SIMCONNECT_RUNTIME_DLL)
        message(FATAL_ERROR
            "Could not find the MSFS SimConnect SDK. Set MSFS_SDK_PATH to the SDK root, "
            "or set SIMCONNECT_INCLUDE_DIR, SIMCONNECT_LIBRARY, and SIMCONNECT_RUNTIME_DLL explicitly."
        )
    endif()

    set(FS2GDL90_MSFS_IMGUI_SOURCES
        ${FS2GDL90_IMGUI_DIR}/imgui.cpp
        ${FS2GDL90_IMGUI_DIR}/imgui_draw.cpp
        ${FS2GDL90_IMGUI_DIR}/imgui_tables.cpp
        ${FS2GDL90_IMGUI_DIR}/imgui_widgets.cpp
        ${FS2GDL90_IMGUI_DIR}/backends/imgui_impl_win32.cpp
        ${FS2GDL90_IMGUI_DIR}/backends/imgui_impl_dx11.cpp
    )

    add_executable(fs2gdl90_msfs WIN32
        src/msfs/app.cpp
        ${FS2GDL90_MSFS_IMGUI_SOURCES}
    )
    target_include_directories(fs2gdl90_msfs PRIVATE
        "${CMAKE_SOURCE_DIR}/include"
        "${SIMCONNECT_INCLUDE_DIR}"
        "${FS2GDL90_IMGUI_DIR}"
        "${FS2GDL90_IMGUI_DIR}/backends"
    )
    target_link_libraries(fs2gdl90_msfs PRIVATE
        fs2gdl90_core
        ${SIMCONNECT_LIBRARY}
        ws2_32
        shlwapi
        user32
        d3d11
        dxgi
        d3dcompiler
    )
    target_compile_definitions(fs2gdl90_msfs PRIVATE _CRT_SECURE_NO_WARNINGS NOMINMAX)
    set_target_properties(fs2gdl90_msfs PROPERTIES OUTPUT_NAME "fs2gdl90-msfs")
    add_custom_command(TARGET fs2gdl90_msfs POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${SIMCONNECT_RUNTIME_DLL}"
            "$<TARGET_FILE_DIR:fs2gdl90_msfs>"
        COMMENT "Copying SimConnect runtime DLL"
    )
    if(MSVC)
        fs2gdl90_set_msvc_runtime(fs2gdl90_msfs)
        target_compile_options(fs2gdl90_msfs PRIVATE /W4 /EHsc)
        set_target_properties(fs2gdl90_msfs PROPERTIES
            LINK_FLAGS "/ENTRY:mainCRTStartup"
        )
    endif()

    install(TARGETS fs2gdl90_msfs
        RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}/build/fs2gdl90/msfs"
    )
endif()

if(FS2GDL90_BUILD_TESTS)
    enable_testing()
    add_executable(fs2gdl90_tests
        tests/test_foreflight_encoder.cpp
        tests/test_foreflight_protocol.cpp
        tests/test_gdl90_encoder.cpp
        tests/test_main.cpp
        tests/test_msfs_support.cpp
        tests/test_protocol_utils.cpp
        tests/test_settings.cpp
        tests/test_settings_ui.cpp
        tests/test_simple_json.cpp
        tests/test_udp_broadcaster.cpp
    )
    target_link_libraries(fs2gdl90_tests PRIVATE fs2gdl90_core)
    fs2gdl90_enable_coverage(fs2gdl90_tests)
    if(FS2GDL90_ENABLE_SOCKET_OPS_TESTS)
        target_compile_definitions(fs2gdl90_tests PRIVATE FS2GDL90_ENABLE_SOCKET_OPS_TESTS=1)
    endif()
    if(MSVC)
        fs2gdl90_set_msvc_runtime(fs2gdl90_tests)
    endif()
    add_test(NAME fs2gdl90_tests COMMAND fs2gdl90_tests)
endif()

message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "SDK Path: ${FS2GDL90_SDK_PATH}")
message(STATUS "Build X-Plane frontend: ${FS2GDL90_BUILD_XPLANE}")
message(STATUS "Build MSFS frontend: ${FS2GDL90_BUILD_MSFS}")
message(STATUS "Build tests: ${FS2GDL90_BUILD_TESTS}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
if(APPLE)
    message(STATUS "Target architectures: ${CMAKE_OSX_ARCHITECTURES}")
    message(STATUS "macOS deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()

set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_GENERATOR "ZIP")
include(CPack)
