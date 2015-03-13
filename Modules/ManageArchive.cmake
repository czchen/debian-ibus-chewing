# - Manage Source Archive and track its content.
# This module manages source archive by:
#  - Handle the ChangeLog
#  - Build the source archive
#  - Exclude unwanted files, either from ignore files of source version
#    control, or add them to SOURCE_ARCHIVE_IGNORE_FILES
#  - Track the contents in source archive, when it updates, the source 
#    Archive should be updated.
#
# This module provide a convenient wrapper of CPack. 
# CPack itself, by default, pack everything under the source directory,
# this is usually undesirable. 
# We avoid this by using the sane default ignore list.
#
# Included Modules:
#   - ManageFile
#   - ManageTarget
#   - ManageVersion
#   - CPack
#
# Targets:
#   - pack_src_pre: Target that depends on other targets that need to be made
#       before pack_src.
#
# Defines following functions:
#   SOURCE_ARCHIVE_CONTENTS_ADD(<filename>)
#   - Add a file to source archive if the file is not in the archive.
#     * Parameters:
#       - filename: Filename to be added.
#
#   SOURCE_ARCHIVE_CONTENTS_ADD_NO_CHECK(<filename>)
#   - Add a file to source archive without check.
#     * Parameters:
#       - filename: Filename to be added.
#
# Defines following macros:
#   PACK_SOURCE_ARCHIVE([<outputDir> | OUTPUT_FILE <file>] 
#     [GENERATOR <cpackGenerator>] 
#     [GITIGNORE <gitignoreFile>] [INCLUDE <file ...>])
#     )
#     - Pack source archive..
#       * Parameters:
#         + outputDir: Directory to write source archive.
#         + OUTPUT_FILE file: Output file with path.
#           Default: SOURCES/<projectName>-<PRJ_VER>-Source.<packFormat>
#         + GENERATOR cpackGenerator: The CPack generator
#           Default: TGZ (.tar.gz) 
#         + GITIGNORE gitignoreFile: Specify path to .gitignore for using .gitignore
#             to exclude the unwanted files.
#         + INCLUDE file ...: Add back those files to source archive.
#             You can add back the files that would otherwise be excluded,
#             e.g. .pot files.
#             otherwise those will be excluded.
#       * Variables to be cached:
#         + SOURCE_ARCHIVE_CONTENTS: List of files to be packed.
#         + SOURCE_ARCHIVE_FILE: Path of source archive (with path).
#         + SOURCE_ARCHIVE_FILE_EXTENSION: File extension of 
#             the source package
#         + SOURCE_ARCHIVE_IGNORE_FILES: List of files to be 
#             ignored to archive.
#         + SOURCE_ARCHIVE_NAME: Name of source archive (without path).
#       * Targets:
#         + pack_src: Pack source files like package_source.
#         + clean_pack_src: Remove all source archives.
#         + clean_old_pack_src: Remove all old source package.
#
#
IF(DEFINED _MANAGE_ARCHIVE_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_ARCHIVE_CMAKE_)
SET (_MANAGE_ARCHIVE_CMAKE_ "DEFINED")

SET(SOURCE_ARCHIVE_IGNORE_FILES_COMMON
    "/\\\\.svn/"  "/CVS/" "/\\\\.git/" "/\\\\.hg/" "NO_PACK")

SET(SOURCE_ARCHIVE_IGNORE_FILES_CMAKE 
    "/CMakeFiles/" "_CPack_Packages/" "/Testing/"
    "\\\\.directory$" "CMakeCache\\\\.txt$"
    "/install_manifest.txt$"
    "/cmake_install\\\\.cmake$" "/cmake_uninstall\\\\.cmake$"
    "/CPack.*\\\\.cmake$" "/CTestTestfile\\\\.cmake$"
    "Makefile$" "/${PROJECT_NAME}-${PRJ_VER}-SOURCE/"
    )
SET(SOURCE_ARCHIVE_IGNORE_FILES 
    ${SOURCE_ARCHIVE_IGNORE_FILES_CMAKE}
    ${SOURCE_ARCHIVE_IGNORE_FILES_COMMON}
    )

INCLUDE(ManageVersion)
INCLUDE(ManageFile)

ADD_CUSTOM_TARGET(pack_src_pre
    COMMENT "pack_src_pre: Before pack_src"
    )

FUNCTION(SOURCE_ARCHIVE_CONTENTS_SET value)
    SET(SOURCE_ARCHIVE_CONTENTS "${value}" CACHE INTERNAL "Source archive file list")
ENDFUNCTION(SOURCE_ARCHIVE_CONTENTS_SET)
SOURCE_ARCHIVE_CONTENTS_SET("")

## Add whatever it's told
FUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD_FAST value)
    LIST(APPEND SOURCE_ARCHIVE_CONTENTS "${value}")
    SOURCE_ARCHIVE_CONTENTS_SET("${SOURCE_ARCHIVE_CONTENTS}")
ENDFUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD_FAST)

FUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD)
    FOREACH(filename ${ARGN})
	GET_FILENAME_COMPONENT(_file "${filename}" ABSOLUTE)
	FILE(RELATIVE_PATH _f ${CMAKE_SOURCE_DIR} "${_file}")
	LIST(FIND SOURCE_ARCHIVE_CONTENTS "${_f}" _index)
	IF(_index LESS 0)
	    SOURCE_ARCHIVE_CONTENTS_ADD_FAST("${_f}")
	ENDIF(_index LESS 0)
    ENDFOREACH(filename)
ENDFUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD)

FUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD_NO_CHECK)
    FOREACH(filename ${ARGN})
	GET_FILENAME_COMPONENT(_file "${filename}" ABSOLUTE)
	FILE(RELATIVE_PATH _f ${CMAKE_SOURCE_DIR} "${_file}")
	SOURCE_ARCHIVE_CONTENTS_ADD_FAST("${_f}")
    ENDFOREACH(filename)
ENDFUNCTION(SOURCE_ARCHIVE_CONTENTS_ADD_NO_CHECK)

# Internal:  SOURCE_ARCHIVE_GET_CONTENTS()
#   - Return all source file to be packed.
#     This is called by SOURCE_ARCHIVE(),
#     So no need to call it again.
FUNCTION(SOURCE_ARCHIVE_GET_CONTENTS )
    SET(_fileList "")
    FILE(GLOB_RECURSE _ls FOLLOW_SYMLINKS "*" )
    STRING(REPLACE "\\\\" "\\" _ignore_files
        "${SOURCE_ARCHIVE_IGNORE_FILES}")

    FOREACH(_file ${_ls})
	SET(_matched 0)
	FOREACH(filePattern ${_ignore_files})
	    M_MSG(${M_INFO3} "_file=${_file} filePattern=${filePattern}")

	    IF(_file MATCHES "${filePattern}")
		SET(_matched 1)
		BREAK()
	    ENDIF(_file MATCHES "${filePattern}")
	ENDFOREACH(filePattern ${_ignore_files})
	IF(NOT _matched)
	    SOURCE_ARCHIVE_CONTENTS_ADD_NO_CHECK("${_file}")
	ENDIF(NOT _matched)
    ENDFOREACH(_file ${_ls})
    M_MSG(${M_INFO2} "SOURCE_ARCHIVE_CONTENTS=${SOURCE_ARCHIVE_CONTENTS}")
ENDFUNCTION(SOURCE_ARCHIVE_GET_CONTENTS)

MACRO(CMAKE_REGEX_TO_REGEX var cmrgx)
    STRING(REPLACE "\\\\" "\\" ${var} "${cmrgx}")
ENDMACRO(CMAKE_REGEX_TO_REGEX var cmrgx)

MACRO(SOURCE_ARCHIVE_GET_IGNORE_LIST _ignoreListVar _includeListVar)
    IF(${_ignoreListVar})
	FILE(STRINGS "${${_ignoreListVar}}" _content REGEX "^[^#]")
	FOREACH(_s ${_content})
	    STRING(STRIP "${_s}" _s)
	    STRING(LENGTH "${_s}" _l)
	    IF(_l GREATER 0)
		## Covert the string from glob to cmake regex
		GIT_GLOB_TO_CMAKE_REGEX(_cmrgx ${_s})
		LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES "${_cmrgx}")
	    ENDIF(_l GREATER 0)
	ENDFOREACH(_s ${_content})
    ENDIF(${_ignoreListVar})

    ## regex match one of include files
    ## then remove that line
    FOREACH(_ignore_pattern ${SOURCE_ARCHIVE_IGNORE_FILES})
	CMAKE_REGEX_TO_REGEX(_ip "${_ignore_pattern}")
	FOREACH(_i ${${_includeListVar}})
	    STRING(REGEX MATCH "${_ip}" _ret "${_i}")
	    IF(_ret)
		LIST(REMOVE_ITEM SOURCE_ARCHIVE_IGNORE_FILES "${_ignore_pattern}")
	    ENDIF(_ret)
	ENDFOREACH(_i ${${_includeListVar}})
    ENDFOREACH(_ignore_pattern ${SOURCE_ARCHIVE_IGNORE_FILES})
ENDMACRO(SOURCE_ARCHIVE_GET_IGNORE_LIST _ignoreListVar _includeListVar)

MACRO(PACK_SOURCE_CPACK var)
    SET(_valid_options "GENERATOR" "INCLUDE" "GITIGNORE")
    VARIABLE_PARSE_ARGN(_opt _valid_options ${ARGN})
    IF(NOT _opt_GENERATOR)
	SET(_opt_GENERATOR "TGZ")
    ENDIF(NOT _opt_GENERATOR)
    SET(CPACK_GENERATOR "${_opt_GENERATOR}")
    SET(CPACK_SOURCE_GENERATOR ${CPACK_GENERATOR})
    IF(${CPACK_GENERATOR} STREQUAL "TGZ")
	SET(SOURCE_ARCHIVE_FILE_EXTENSION "tar.gz")
    ELSEIF(${CPACK_GENERATOR} STREQUAL "TBZ2")
	SET(SOURCE_ARCHIVE_FILE_EXTENSION "tar.bz2")
    ELSEIF(${CPACK_GENERATOR} STREQUAL "ZIP")
	SET(SOURCE_ARCHIVE_FILE_EXTENSION "zip")
    ENDIF(${CPACK_GENERATOR} STREQUAL "TGZ")
    SET(CPACK_PACKAGE_VERSION ${PRJ_VER})
    IF(PRJ_SUMMARY)
	SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PRJ_SUMMARY}")
    ENDIF(PRJ_SUMMARY)
    IF(EXISTS ${CMAKE_SOURCE_DIR}/COPYING)
	SET(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/COPYING)
    ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/COPYING)

    IF(EXISTS ${CMAKE_SOURCE_DIR}/README)
	SET(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_SOURCE_DIR}/README)
    ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/README)
    SET(CPACK_PACKAGE_VENDOR "${VENDOR}")

    SET(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PRJ_VER}-Source")
    LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES "${PROJECT_NAME}-[^/]*-Source")
    SET(SOURCE_ARCHIVE_NAME 
	"${CPACK_SOURCE_PACKAGE_FILE_NAME}.${SOURCE_ARCHIVE_FILE_EXTENSION}" 
	CACHE STRING "Source archive name" FORCE
	)
    SET(${var} "${SOURCE_ARCHIVE_NAME}")

    SOURCE_ARCHIVE_GET_IGNORE_LIST(_opt_GITIGNORE _opt_INCLUDE)
    LIST(APPEND CPACK_SOURCE_IGNORE_FILES ${SOURCE_ARCHIVE_IGNORE_FILES})
    INCLUDE(CPack)
ENDMACRO(PACK_SOURCE_CPACK var)

MACRO(PACK_SOURCE_ARCHIVE)
    SET(_valid_options "OUTPUT_FILE" "GENERATOR" "INCLUDE" "GITIGNORE")
    VARIABLE_PARSE_ARGN(_opt _valid_options ${ARGN})
    IF(PRJ_VER STREQUAL "")
	M_MSG(${M_FATAL} "PRJ_VER not defined")
    ENDIF(PRJ_VER STREQUAL "")

    ## PACK_SOURCE_CPACK to pack with default output file
    VARIABLE_TO_ARGN(_cpack_source_pack_opts _opt _valid_options)
    PACK_SOURCE_CPACK(_source_archive_file
	${_cpack_source_pack_opts})

    ## Does user want his own output file or directory
    SET(_own 0)
    SET(_own_dir 0)
    SET(_own_file 0)
    IF(_opt)
	SET(_outputDir "${_opt}")
    ENDIF(_opt)
    IF(_opt_OUTPUT_FILE)
	GET_FILENAME_COMPONENT(_outputDir ${_opt_OUTPUT_FILE} PATH)
	GET_FILENAME_COMPONENT(_outputFile ${_opt_OUTPUT_FILE} NAME)
    ENDIF(_opt_OUTPUT_FILE)

    GET_FILENAME_COMPONENT(_currentDir_real "${CMAKE_CURRENT_BINARY_DIR}" REALPATH)
    IF(_outputDir)
	GET_FILENAME_COMPONENT(_outputDir_real ${_outputDir} REALPATH)
    ELSE(_outputDir)
	SET(_outputDir_real ${_currentDir_real})
    ENDIF(_outputDir)

    IF(NOT _outputFile)
	SET(_outputFile "${_source_archive_file}")
    ENDIF(NOT _outputFile)

    IF(NOT _outputDir_real STREQUAL "${_currentDir_real}")
	SET(_own_dir 1)
	SET(_own 1)
    ENDIF(NOT _outputDir_real STREQUAL "${_currentDir_real}")
    IF(NOT _outputFile STREQUAL "${_source_archive_file}")
	SET(_own_file 1)
	SET(_own 1)
    ENDIF(NOT _outputFile STREQUAL "${_source_archive_file}")
    GET_FILENAME_COMPONENT(SOURCE_ARCHIVE_FILE 
	"${_outputDir_real}/${_outputFile}" ABSOLUTE)
    SET(SOURCE_ARCHIVE_FILE ${SOURCE_ARCHIVE_FILE}
	CACHE FILEPATH "Source archive file" FORCE)
    SET(SOURCE_ARCHIVE_NAME "${_outputFile}" 
	CACHE FILEPATH "Source archive name" FORCE)

    SET(SOURCE_ARCHIVE_CONTENTS_ABSOLUTE "")
    FOREACH(_file ${SOURCE_ARCHIVE_CONTENTS})
	LIST(APPEND SOURCE_ARCHIVE_CONTENTS_ABSOLUTE
	    "${CMAKE_HOME_DIRECTORY}/${_file}"
	    )
    ENDFOREACH(_file ${SOURCE_ARCHIVE_CONTENTS})

    SET(_dep_list "${SOURCE_ARCHIVE_CONTENTS_ABSOLUTE}")
    ## If own directory,
    IF(_own_dir)
	### Need to create it
	ADD_CUSTOM_COMMAND(OUTPUT ${_outputDir_real}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_outputDir_real}
	    COMMENT "Create dir for source archive output."
	    )
	LIST(APPEND _dep_list ${_outputDir_real})
    ENDIF(_own_dir)

    ADD_DEPENDENCIES(pack_src_pre changelog)
    ## If own, need to move to it
    SET(moveCommands "")

    IF(_own)
	SET(moveCommands 
	    COMMAND ${CMAKE_COMMAND} -E copy "${_source_archive_file}" "${SOURCE_ARCHIVE_FILE}"
	    COMMAND ${CMAKE_COMMAND} -E remove "${_source_archive_file}"
	    )
    ENDIF(_own)

    INCLUDE(ManageTarget)
    ADD_CUSTOM_TARGET_COMMAND(pack_src
	NO_FORCE
	OUTPUT ${SOURCE_ARCHIVE_FILE}
	COMMAND make pack_src_pre
	COMMAND make package_source
	${moveCommands}
	DEPENDS  ${_dep_list}
	COMMENT "Packing the source as: ${SOURCE_ARCHIVE_FILE}"
	VERBATIM
	)

    ADD_CUSTOM_TARGET(dist
	DEPENDS ${SOURCE_ARCHIVE_FILE}
	COMMENT "dist: ${SOURCE_ARCHIVE_FILE}"
	)

    ADD_CUSTOM_TARGET(clean_old_pack_src
	COMMAND find .
	-name '${PROJECT_NAME}*.${SOURCE_ARCHIVE_FILE_EXTENSION}' ! -name '${PROJECT_NAME}-${PRJ_VER}-*.${SOURCE_ARCHIVE_FILE_EXTENSION}'
	-print -delete
	COMMENT "Cleaning old source archives"
	)

    ADD_DEPENDENCIES(clean_old_pack_src changelog )

    ADD_CUSTOM_TARGET(clean_pack_src
	COMMAND find .
	-name '${PROJECT_NAME}*.${SOURCE_ARCHIVE_FILE_EXTENSION}'
	-print -delete
	COMMENT "Cleaning all source archives"
	)
ENDMACRO(PACK_SOURCE_ARCHIVE)

