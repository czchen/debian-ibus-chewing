# - cmake-fedora environment common setting.
#
# This module defines the common settings of both normal and script mode.
# Normally this module should be the first to call.
#
# Set cache for following variables:
#   - CMAKE_INSTALL_PREFIX:
#     Default: "/usr"
#   - BIN_DIR: Binary dir
#     Default: "${CMAKE_INSTALL_PREFIX}/bin"
#   - DATA_DIR: Data dir
#     Default: "${CMAKE_INSTALL_PREFIX}/share"
#   - DOC_DIR: Documentation dir
#     Default: "${DATA_DIR}/doc"
#   - SYSCONF_DIR: System configuration dir
#     Default: "/etc"
#   - LIB_DIR: System wide library path.
#     Default: ${CMAKE_INSTALL_PREFIX}/lib for 32 bit,
#              ${CMAKE_INSTALL_PREFIX}/lib64 for 64 bit.
#   - LIBEXEC_DIR: Directory for executables that should not called by 
#       end-user directly
#     Default: "${CMAKE_INSTALL_PREFIX}/libexec"
#   - CMAKE_FEDORA_SCRIPT_PATH_HINTS: PATH hints to find cmake-fedora scripts
#   - CMAKE_FEDORA_TMP_DIR: Director that stores cmake-fedora
#       temporary items.
#     Default: ${CMAKE_BINARY_DIR}/NO_PACK
#   - MANAGE_MESSAGE_LEVEL: Message (Verbose) Level
#     Default: 5
#
#
#
IF(DEFINED _MANAGE_ENVIRONMENT_COMMON_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_ENVIRONMENT_COMMON_CMAKE_)
SET(_MANAGE_ENVIRONMENT_COMMON_CMAKE_ "DEFINED")
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)

# Default CMAKE_INSTALL_PREFIX should be set before PROJECT()
SET(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install dir prefix")

SET(BIN_DIR     "${CMAKE_INSTALL_PREFIX}/bin"     CACHE PATH "Binary dir")
SET(DATA_DIR    "${CMAKE_INSTALL_PREFIX}/share"   CACHE PATH "Data dir")
SET(DOC_DIR     "${DATA_DIR}/doc"                 CACHE PATH "Doc dir")
SET(LIBEXEC_DIR "${CMAKE_INSTALL_PREFIX}/libexec" CACHE PATH "Libexec dir")
SET(SYSCONF_DIR "/etc"                            CACHE PATH 
    "System configuration dir"
    )


## CMAKE_SYSTEM_PROCESSOR does not see to be defined yet
EXECUTE_PROCESS(COMMAND uname -p
    OUTPUT_VARIABLE UNAME_P
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
IF("${UNAME_P}" MATCHES "64")
    SET(IS_64 "64" CACHE STRING "IS_64")
ENDIF()
SET(LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib${IS_64}"
    CACHE PATH "Library dir"
    )

SET(CMAKE_FEDORA_SCRIPT_PATH_HINTS 
    ${CMAKE_SOURCE_DIR}/scripts ${CMAKE_SOURCE_DIR}/cmake-fedora/scripts
    ${CMAKE_SOURCE_DIR}/../scripts ${CMAKE_SOURCE_DIR}/../cmake-fedora/scripts
    ${CMAKE_SOURCE_DIR}/../../scripts ${CMAKE_SOURCE_DIR}/../../cmake-fedora/scripts
    CACHE INTERNAL "CMAKE_FEDORA_SCRIPT_PATH_HINTS"
    )

## CMAKE_FEDORA_TMP_DIR: Directory stores temporary files.
SET(CMAKE_FEDORA_TMP_DIR "${CMAKE_BINARY_DIR}/NO_PACK" 
    CACHE PATH "cmake-fedora tmp dir")

# Message level INFO1 (5)
SET(MANAGE_MESSAGE_LEVEL 5 CACHE STRING "Message (Verbose) Level")


