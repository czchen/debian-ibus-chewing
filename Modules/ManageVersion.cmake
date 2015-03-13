# - Manage Version, ChangeLog and project information (prj_info.cmake)
#
# Included Modules:
#   - DateTimeFormat
#   - ManageString
#   - ManageVariable
#
# Set cache for following variables:
#   - CHANGELOG_FILE: Location of ChangeLog.
#     Default: ${CMAKE_SOURCE_DIR}/ChangeLog
#   - PRJ_INFO_CMAKE_FILE: Path to prj_info.cmake
#     Default: ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake
#
# Defines following functions:
#   RELEASE_NOTES_READ_FILE([<release_file>])
#   - Load release file information.
#     * Parameters:
#       + release_file: (Optional) release file to be read.
#         This file should contain following definition:
#         - PRJ_VER: Release version.
#         - SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#         - Section [Changes]:
#           Changes of this release list below the section tag.
#         Default:${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt
#     * Values to cached:
#       + PRJ_VER: Version.
#       + CHANGE_SUMMARY: Summary of changes.
#       + RELEASE_NOTES_FILE: The loaded release file.
#     * Compile flags defined:
#       + PRJ_VER: Project version.
#
#   PRJ_INFO_CMAKE_WRITE()
#   - Write the project infomation to prj_info.cmake.
#
#   PRJ_INFO_CMAKE_APPEND(<var>)
#   - Append  var to prj_info.cmake.
#     * Parameters:
#       + var: Variable to be append to prj_info.cmake.
#
# Defines following macros:
#   PRJ_INFO_CMAKE_READ(<prj_info_file>)
#   - Read prj_info.cmake and get the info of projects.
#     This macro is meant to be run by ManageChangeLogScript script.
#     So normally no need to call it manually.
#     * Parameters:
#       + prj_info_file: File name to be appended to.
#         Default: ${PRJ_INFO_CMAKE_FILE}, otherwise ${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake.
#     * Targets:
#       + changelog: ChangeLog update.

IF(DEFINED _MANAGE_VERSION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_VERSION_CMAKE_)
SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageVariable)
INCLUDE(ManageFile)

SET(PRJ_INFO_VARIABLE_LIST 
    PROJECT_NAME PRJ_VER PRJ_SUMMARY SUMMARY_TRANSLATIONS
    PRJ_DESCRIPTION DESCRIPTION_TRANSLATIONS 
    LICENSE PRJ_GROUP MAINTAINER AUTHORS VENDER
    BUILD_ARCH RPM_SPEC_URL RPM_SPEC_SOURCES
    )

SET(CHANGELOG_FILE "${CMAKE_SOURCE_DIR}/ChangeLog" CACHE FILEPATH "ChangeLog")
SET(PRJ_INFO_CMAKE_FILE "${CMAKE_FEDORA_TMP_DIR}/prj_info.cmake" CACHE INTERNAL "prj_info.cmake")

FUNCTION(PRJ_INFO_CMAKE_APPEND var)
    IF(NOT "${${var}}" STREQUAL "")
	STRING_ESCAPE_BACKSLASH(_str "${${var}}")
	STRING_ESCAPE_DOLLAR(_str "${_str}")
	STRING_ESCAPE_QUOTE(_str "${_str}")
	FILE(APPEND ${PRJ_INFO_CMAKE_FILE} "SET(${var} \"${_str}\")\n")
    ENDIF(NOT "${${var}}" STREQUAL "")
ENDFUNCTION(PRJ_INFO_CMAKE_APPEND)

MACRO(PRJ_INFO_CMAKE_READ prj_info_file)
    IF("${prj_info_file}" STREQUAL "")
	M_MSG(${M_EROR} "Requires prj_info.cmake")
    ENDIF()
    INCLUDE(${prj_info_file} RESULT_VARIABLE prjInfoPath)
    IF("${prjInfoPath}" STREQUAL "NOTFOUND")
	M_MSG(${M_ERROR} "Failed to read ${prj_info_file}")
    ENDIF()
ENDMACRO(PRJ_INFO_CMAKE_READ)

FUNCTION(PRJ_INFO_CMAKE_WRITE)
    FILE(REMOVE "${PRJ_INFO_CMAKE_FILE}")
    FOREACH(_v ${PRJ_INFO_VARIABLE_LIST})
	PRJ_INFO_CMAKE_APPEND(${_v})
    ENDFOREACH(_v)
ENDFUNCTION(PRJ_INFO_CMAKE_WRITE prj_info_file)

## All variable should be specified eplicitly
FUNCTION(RELEASE_NOTES_FILE_EXTRACT_CHANGELOG_CURRENT var releaseNoteFile )
    FILE(STRINGS "${releaseNoteFile}" _releaseLines)
    SET(_changeItemSection 0)
    SET(_changeLogThis "")
    ## Parse release file
    INCLUDE(ManageString)
    FOREACH(_line ${_releaseLines})
	IF(_changeItemSection)
	    ### Append lines in change section
	    STRING_APPEND(_changeLogThis "${_line}" "\n")
	ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    SET(_changeItemSection 1)
	ENDIF()
    ENDFOREACH(_line ${_releaseLines})
    SET(${var} "${_changeLogThis}" PARENT_SCOPE)
ENDFUNCTION(RELEASE_NOTES_FILE_EXTRACT_CHANGELOG_CURRENT)

FUNCTION(RELEASE_NOTES_READ_FILES_VARIABLES releaseNoteFile )
    FILE(STRINGS "${RELEASE_NOTES_FILE}" _release_lines)

    SET(CHANGELOG_CURRENT_FILE "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.current" CACHE INTERNAL "ChangeLog.current")
    ## Parse release file
    FOREACH(_line ${_release_lines})
	IF("${_line}" MATCHES "^[[]Changes[]]")
	    ### Start the change section
	    BREAK()
	ELSEIF(NOT "${_line}" MATCHES "^\\s*#")
	    SETTING_STRING_GET_VARIABLE(var value "${_line}")
	    #MESSAGE("var=${var} value=${value}")
	    IF(var STREQUAL "PRJ_VER")
		SET_COMPILE_ENV(${var} "${value}" CACHE STRING "Project Version" FORCE)
	    ELSEIF(var STREQUAL "SUMMARY")
		SET(CHANGE_SUMMARY "${value}" CACHE STRING "Change Summary" FORCE)
	    ELSE(var STREQUAL "PRJ_VER")
		SET(${var} "${value}" CACHE STRING "${var}" FORCE)
	    ENDIF(var STREQUAL "PRJ_VER")
	ENDIF("${_line}" MATCHES "^[[]Changes[]]")
    ENDFOREACH(_line)
ENDFUNCTION(RELEASE_NOTES_READ_FILES_VARIABLES)

FUNCTION(RELEASE_NOTES_READ_FILE)
    FOREACH(_arg ${ARGN})
	IF(EXISTS ${_arg})
	    SET(RELEASE_NOTES_FILE ${_arg} CACHE FILEPATH "Release File")
	ENDIF(EXISTS ${_arg})
    ENDFOREACH(_arg ${ARGN})

    IF(NOT RELEASE_NOTES_FILE)
	SET(RELEASE_NOTES_FILE "${CMAKE_SOURCE_DIR}/RELEASE-NOTES.txt" CACHE FILEPATH "Release Notes")
    ENDIF(NOT RELEASE_NOTES_FILE)

    FILE(STRINGS "${RELEASE_NOTES_FILE}" _release_lines)

    SET(_changeItemSection 0)
    SET(CHANGELOG_CURRENT_FILE "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.current" CACHE INTERNAL "ChangeLog.current")

    ## Parse release file
    RELEASE_NOTES_READ_FILES_VARIABLES(${RELEASE_NOTES_FILE})

    PRJ_INFO_CMAKE_WRITE()

    ADD_CUSTOM_TARGET(changelog
	COMMAND ${CMAKE_COMMAND} -Dcmd=update 
	-Dchangelog=${CHANGELOG_FILE}
	-Drelease=${RELEASE_NOTES_FILE}
	-Dprj_info=${PRJ_INFO_CMAKE_FILE}
	-Dcmakecache=${CMAKE_BINARY_DIR}/CMakeCache.txt
	-Dcmake_source_dir=${CMAKE_SOURCE_DIR}
	-P ${CMAKE_FEDORA_MODULE_DIR}/ManageChangeLogScript.cmake
	DEPENDS ${RELEASE_NOTES_FILE}
	COMMENT "changelog: ${CHANGELOG_FILE}"
	)
ENDFUNCTION(RELEASE_NOTES_READ_FILE)

