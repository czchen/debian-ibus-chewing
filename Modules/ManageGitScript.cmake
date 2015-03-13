# - Manage Git Script
# Scripts to be invoked in command line
#

MACRO(MANAGE_GIT_SCRIPT_PRINT_USAGE)
    MESSAGE("cmake-fedora utility scripts

cmake -D cmd=make_tag_file 
    -D ver=<ver> -D output_file=<output_file>
    [-D \"msg=<message>\"]
    [-D cmake_fedora_module_dir=<dir>]
    [\"-D <VAR>=<VAULE>\"]
    -P <CmakeModulePath>/ManageGitScript.cmake
  Make a tag file, which indicates the build process is passed and 
  the branch is tagged with <ver>.

  Options:
     ver: project version
     outputFile: Tag file
     msg: message associate with tag
     cmake_fedora_module_dir: 
        Specify this if cmake and cmake-fedora failed to find 
        the location of CMake Fedora modules. 

    ")
ENDMACRO(MANAGE_GIT_SCRIPT_PRINT_USAGE)

FUNCTION(MAKE_TAG_FILE)
    EXECUTE_PROCESS(
	COMMAND git tag -l ${ver}
	OUTPUT_VARIABLE tagLine
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    IF("${msg}" STREQUAL "")
	SET(msg "${ver}")
    ENDIF()

    IF("${tagLine}" STREQUAL "")
	## No tag
	EXECUTE_PROCESS(
	    COMMAND make VERBOSE=1 tag_pre
	    RESULT_VARIABLE tagResult
	    )
	IF(NOT tagResult EQUAL 0)
	    M_MSG(${M_FATAL} "Failed to build before tagging")
	ENDIF()
	EXECUTE_PROCESS(COMMAND git tag -a -m "${msg}" "${ver}" HEAD)
    ENDIF()
    FILE(WRITE "${output_file}" "${msg}")

ENDFUNCTION(MAKE_TAG_FILE)

SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)

#######################################
# Determine CMAKE_FEDORA_MODULE_DIR
#

## It is possible that current dir is in NO_PACK/FedPkg/<prj>
LIST(INSERT CMAKE_MODULE_PATH 0
    ${CMAKE_SOURCE_DIR}/Modules ${CMAKE_SOURCE_DIR}/cmake-fedora/Modules 
    ${CMAKE_SOURCE_DIR}/../../../Modules
    ${CMAKE_SOURCE_DIR}/../../../cmake-fedora/Modules
    ${CMAKE_SOURCE_DIR}
    )

IF(CMAKE_SCRIPT_MODE_FILE)
    GET_FILENAME_COMPONENT(CMAKE_FEDORA_SCRIPT_DIR ${CMAKE_SCRIPT_MODE_FILE}
	PATH)
    LIST(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_FEDORA_SCRIPT_DIR}")
ENDIF()

IF(cmake_fedora_module_dir)
    LIST(INSERT CMAKE_MODULE_PATH 0 "${cmake_fedora_module_dir}")
ENDIF()

INCLUDE(ManageMessage RESULT_VARIABLE MANAGE_MODULE_PATH)
IF(NOT MANAGE_MODULE_PATH)
    MESSAGE(FATAL_ERROR "ManageMessage.cmake cannot be found in ${CMAKE_MODULE_PATH}")
ENDIF()
INCLUDE(ManageFile)

IF(NOT DEFINED cmd)
    MANAGE_GIT_SCRIPT_PRINT_USAGE()
ELSEIF(cmd STREQUAL "make_tag_file")
    IF(NOT ver)
	MANAGE_GIT_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -D ver=<ver>")
    ENDIF()
    IF(NOT output_file)
	MANAGE_GIT_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -D output_file=<output_file>")
    ENDIF()
    MAKE_TAG_FILE()
ELSE()
    MANAGE_GIT_SCRIPT_PRINT_USAGE()
    M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
ENDIF()

