# - Cmake Fedora Script
# Scripts to be invoked in command line
#

MACRO(CMAKE_FEDORA_SCRIPT_PRINT_USAGE)
    MESSAGE("cmake-fedora utility scripts

cmake -D cmd=configure_file 
      -D inputFile=<inputFile> -D outputFile=<outputFile>
      [-D atOnly=1]
      [-D cmake_fedora_module_dir=<dir>]
      [-D escape_quotes=1]
      [\"-D <VAR>=<VAULE>\"]
    -P <CmakeModulePath>/CmakeFedoraScript.cmake
  Copy a file to another location and modify its contents.
  This is a wrapper of CONFIGURE_FILE command in cmake.

  Note: Please pass the necessary variables via -Dvar=VALUE,
    e.g. -DPROJECT_NAME=cmake-fedora
  Options:
    inputFile: input file
    outPutFile: output file
    atOnly: Replace only the variables surround by '@', like @VAR@.
      Same as passing '@ONLY' to CONFIGURE_FILE.
    cmake_fedora_module_dir:
      Specify this if cmake and cmake-fedora failed to find 
      the location of CMake Fedora modules. 
    escape_quotes: Substituted quotes will be C-style escape.
      Same as passing 'ESCAPE_QUOTES' to CONFIGURE_FILE.
    
cmake -D cmd=find_file|find_program -D \"names=<name1;name2>\"
      [-D cmake_fedora_module_dir=<dir>]
      [-D paths=\"<path1>;<path2>\"]
      [-D error_msg=<msg>]
      [-D verbose_level=<verboseLevel>]
      [-D no_default_path=1]
    -P <CmakeModulePath>/CmakeFedoraScript.cmake
  Find a file or program with name1 or name2, 
    with proper error handling.
  Options:
    cmake_fedora_module_dir:
      Specify this if cmake and cmake-fedora failed to find 
      the location of CMake Fedora modules. 
    paths: Paths that files might be located.
    error_msg: Error message to be shown if not-found.
    verbose_level: Verbose level for not-found message.
      1: Critical (The 'not found' message is shown as critical)
      2: Error (The 'not found' message is shown as error)
      3: Warning (The 'not found' message is shown as warning)
      4: Off (The 'not found' message is shown as off, 
         that is, turn off certain functionality).
      5: Info1
      6: Info2
      7: Info3
      Default: 3 (Warning)
    no_default_path: CMake default paths will not be search.
      Useful if you only want to search the file list in -Dpaths.
	   
cmake -D cmd=manage_file_cache -D \"run=<command arg1 ...>\"
      -D cache_file=<cacheFileWithoutDirectory>
      [-D cmake_fedora_module_dir=<dir>]
      [-D expiry_seconds=seconds]
      [-D cache_dir=dir]
    -P <CmakeModulePath>/CmakeFedoraScript.cmake
  Output from either cache file or run command.
  Command is run when 1) cache expired or 2) no cache.
  Cache will be update after run command.
  Options:
    run=<command arg1 ...>: The command that provide output.
    cache_file=<file>: The path to cache file.
    cmake_fedora_module_dir=<dir>:
      Specify this if cmake and cmake-fedora failed to find 
      the location of CMake Fedora modules. 
    expiry_seconds=<seconds>: After <seconds> the cache should expired.
    cache_dir=<dir>: The directory to put cache.


cmake -D cmd=get_variable -Dvar=<varName>
      [-D noescape_semicolon=1]
    -P <CmakeModulePath>/CmakeFedoraScript.cmake
  Get variable value from cmake-fedora.conf.
  Options:
    noescape_semicolon=1: Do not escape semicolon, 
    so ';' split strings can be interpreted as list.

")
ENDMACRO(CMAKE_FEDORA_SCRIPT_PRINT_USAGE)

FUNCTION(CONFIGURE_FILE_SCRIPT)
    IF(NOT inputFile)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -DinputFile=<file>")
    ENDIF()
    IF(NOT EXISTS "${inputFile}")
	M_MSG(${M_FATAL} "Input file not exists: ${inputFile}")
    ENDIF()
    IF(NOT outputFile)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -DoutputFile=<file>")
    ENDIF()
    SET(_opts)
    IF(escape_quotes)
	LIST(APPEND _opts "ESCAPE_QUOTES")
    ENDIF()
    IF(at_only)
	LIST(APPEND _opts "@ONLY")
    ENDIF()

    CONFIGURE_FILE("${inputFile}" "${outputFile}" ${_opts})
ENDFUNCTION(CONFIGURE_FILE_SCRIPT)

MACRO(FIND_FILE_OR_PROGRAM)
    SET(_args "")
    IF(error_msg)
	LIST(APPEND _args "ERROR_MSG" "${error_msg}")
    ENDIF()

    SET(_verboseLevel "${M_WARN}")
    IF(DEFINED verbose_level)
	SET(_verboseLevel "${verbose_level}")
    ENDIF()
    LIST(APPEND _args "VERBOSE_LEVEL" "${_verboseLevel}")

    IF(DEFINED no_default_path)
	LIST(APPEND _args "NO_DEFAULT_PATH")
    ENDIF()

    LIST(APPEND _args "FIND_ARGS" "NAMES" "${names}")

    IF(paths)
	LIST(APPEND _args "PATHS" "${paths}")
    ENDIF()

    IF(cmd STREQUAL "find_file")
	FIND_FILE_ERROR_HANDLING(_var ${_args})
    ELSEIF(cmd STREQUAL "find_program")
	FIND_PROGRAM_ERROR_HANDLING(_var ${_args})
    ENDIF()
    IF(_var STREQUAL "_var-NOTFOUND")
	M_MSG(${_verboseLevel} "${cmd}: '${names}' not found!")
    ELSE()
	M_OUT("${_var}")
    ENDIF()
    UNSET(_verboseLevel CACHE)
ENDMACRO(FIND_FILE_OR_PROGRAM)

FUNCTION(MANAGE_FILE_CACHE_SCRIPT)
    IF(NOT run)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Drun=<executable>")
    ENDIF()
    IF(NOT cache_file)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dcache_file=<filenameWithoutDir>")
    ENDIF()

    SET(_opts "")
    IF(expiry_seconds)
	LIST(APPEND _opts EXPIRY_SECONDS "${expiry_seconds}")
    ENDIF()

    IF(cache_dir) 
	LIST(APPEND _opts CACHE_DIR "${cache_dir}")
    ENDIF() 

    MANAGE_FILE_CACHE(v ${cache_file} ${_opts} COMMAND sh -c "${run}")
    M_OUT("${v}")
ENDFUNCTION(MANAGE_FILE_CACHE_SCRIPT)

FUNCTION(CMAKE_FEDORA_GET_VARIABLE_SCRIPT)
    IF(NOT var)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dvar=<variable>")
    ENDIF(NOT var)
    SET(opts)
    IF(noescape_semicolon)
	LIST(APPEND opts "NOESCAPE_SEMICOLON")
    ENDIF()
    CMAKE_FEDORA_CONF_GET_ALL_VARIABLES(${opts})
    M_OUT("${${var}}")
ENDFUNCTION(CMAKE_FEDORA_GET_VARIABLE_SCRIPT)

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
    CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
ELSEIF(cmd STREQUAL "find_file" OR cmd STREQUAL "find_program")
    IF(NOT names)
	CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dnames=\"<name1;name2>\"")
    ENDIF(NOT names)
    FIND_FILE_OR_PROGRAM()
ELSEIF(cmd STREQUAL "configure_file")
    CONFIGURE_FILE_SCRIPT()
ELSEIF(cmd STREQUAL "manage_file_cache")
    MANAGE_FILE_CACHE_SCRIPT()
ELSEIF(cmd STREQUAL "get_variable")
    CMAKE_FEDORA_GET_VARIABLE_SCRIPT()
ELSE()
    CMAKE_FEDORA_SCRIPT_PRINT_USAGE()
    M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
ENDIF()

