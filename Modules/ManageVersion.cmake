# - Modules for manipulate version and ChangeLog
#
# Includes:
#   ManageVariable
#   DateTimeFormat
#
# Included by:
#   PackSource
#
# Defines following functions:
#   MANAGE_CHANGELOG_SPLIT(changeLogItemVar prevVar changeLogFile ver)
#   - Split the changeLog into two parts:
#     1. changeLogItemVar: Current version, that is,
#        ChangeLog under the version specified by "ver".
#     2. prev: Previous version.
#        Note that version info are returned.
#     Arguments:
#     + changeLogItemVar: Variable hold th
#
#   RELEASE_NOTES_READ_FILE([releaseFile])
#   - Load release file information.
#     Arguments:
#     + releaseFile: (Optional) release file to be read.
#       This file should contain following definition:
#       - PRJ_VER: Release version.
#       - SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#       - Section [Changes]:
#         Changes of this release list below the section tag.
#       Default:RELEASE-NOTES.txt
#     This macro outputs following files:
#     + ChangeLog: Log of changes.
#       Depends on ChangeLog.prev and releaseFile.
#     This macro sets following variables:
#     + PRJ_VER: Release version.
#     + CHANGE_SUMMARY: Summary of changes.
#     + CHANGELOG_ITEMS: Lines below the [Changes] tag.
#     + RELEASE_NOTES_FILE: The loaded release file.
#     + PRJ_DOC_DIR: Documentation for the project.
#       Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}
#

IF(NOT DEFINED _MANAGE_VERSION_CMAKE_)
    SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageVariable)

    SET(CHANGELOG_FILE "${CMAKE_SOURCE_DIR}/ChangeLog" CACHE FILEPATH
	"ChangeLog")
    SET(CHANGELOG_PREV_FILE "${CMAKE_SOURCE_DIR}/ChangeLog.prev" CACHE FILEPATH
	"ChangeLog.prev")

    ADD_CUSTOM_TARGET(changelog_prev_update
	COMMAND ${CMAKE_COMMAND} -E copy ${CHANGELOG_FILE} ${CHANGELOG_PREV_FILE}
	DEPENDS ${CHANGELOG_FILE}
	COMMENT "${CHANGELOG_FILE} are saving as ${CHANGELOG_PREV_FILE}"
	)

    FUNCTION(MANAGE_CHANGELOG_SPLIT changeLogItemVar prevVar changeLogFile ver)
	SET(_changeLogFileBuf "")
	SET(_this "")
	SET(_prev "")
	IF(EXISTS "${changeLogFile}")
	    SET(_isThis 0)
	    SET(_isPrev 0)
	    # Use this instead of FILE(READ is to avoid error when reading '\'
	    # character.
	    EXECUTE_PROCESS(COMMAND cat "${changeLogFile}"
		OUTPUT_VARIABLE _changeLogFileBuf
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	    #MESSAGE("# _changeLogFileBuf=|${_changeLogFileBuf}|")
	    STRING_SPLIT(_lines "\n" "${_changeLogFileBuf}" ALLOW_EMPTY)
	    #MESSAGE("# _lines=|${_lines}|")

	    LIST(LENGTH _lines _lineCount)
	    MATH(EXPR _lineCount ${_lineCount}-1)
	    FOREACH(_i RANGE ${_lineCount})
		LIST(GET _lines ${_i} _line)
		#MESSAGE("# _i=${_i} _line=${_line}")
		STRING(REGEX MATCH "^\\* [A-Za-z]+ [A-Za-z]+ [0-9]+ [0-9]+ .+ <.+> - (.*)$" _match  "${_line}")
		IF("${_match}" STREQUAL "")
		    # Not a version line
		    IF(_isThis)
			STRING_APPEND(_this "${_line}" "\n")
		    ELSEIF(_isPrev)
			STRING_APPEND(_prev "${_line}" "\n")
		    ELSE(_isThis)
			M_MSG(${M_ERROR} "ChangeLog: Cannot distinguish version for line :${_line}")
		    ENDIF(_isThis)
		ELSE("${_match}" STREQUAL "")
		    # Is a version line
		    SET(_cV "${CMAKE_MATCH_1}")
		    IF("${_cV}" STREQUAL "${ver}")
			SET(_isThis 1)
			SET(_isPrev 0)
		    ELSE("${_cV}" STREQUAL "${ver}")
			SET(_isThis 0)
			SET(_isPrev 1)
			STRING_APPEND(_prev "${_line}" "\n")
		    ENDIF("${_cV}" STREQUAL "${ver}")
		ENDIF("${_match}" STREQUAL "")
	    ENDFOREACH(_i RANGE _lineCount)
	ENDIF(EXISTS "${changeLogFile}")
	SET(${changeLogItemVar} "${_this}" PARENT_SCOPE)
	SET(${prevVar} "${_prev}" PARENT_SCOPE)
    ENDFUNCTION(MANAGE_CHANGELOG_SPLIT changeLogItemVar prevVar changeLogFile ver)

    FUNCTION(MANAGE_CHANGELOG_UPDATE changeLogFile ver newChangeStr)
	SET(CHANGELOG_ITEM_FILE "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.Item"
	    CACHE INTERNAL "ChangeLog Item file")
	MANAGE_CHANGELOG_SPLIT(changeLogItemVar prevVar "${changeLogFile}" "${ver}")

	INCLUDE(DateTimeFormat)

	FILE(WRITE ${CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}\n")
	IF (newChangeStr)
	    FILE(WRITE ${CHANGELOG_ITEM_FILE} "${newChangeStr}")
	    FILE(APPEND ${CHANGELOG_FILE} "${newChangeStr}\n\n")
	ELSE(newChangeStr)
	    FILE(WRITE ${CHANGELOG_ITEM_FILE} "${changeLogItemVar}")
	    FILE(APPEND ${CHANGELOG_FILE} "${changeLogItemVar}\n\n")
	ENDIF(newChangeStr)
	FILE(APPEND ${CHANGELOG_FILE} "${prevVar}")
    ENDFUNCTION(MANAGE_CHANGELOG_UPDATE changeLogFile ver newChangeStr)

    FUNCTION(RELEASE_NOTES_READ_FILE)
	INCLUDE(ManageString)
	SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
	FOREACH(_arg ${ARGN})
	    IF(EXISTS ${_arg})
		SET(RELEASE_NOTES_FILE ${_arg} CACHE FILEPATH "Release File")
	    ENDIF(EXISTS ${_arg})
	ENDFOREACH(_arg ${ARGN})

	IF(NOT RELEASE_NOTES_FILE)
	    SET(RELEASE_NOTES_FILE "RELEASE-NOTES.txt" CACHE FILEPATH "Release Notes")
	ENDIF(NOT RELEASE_NOTES_FILE)

	FILE(STRINGS "${RELEASE_NOTES_FILE}" _release_lines)

	SET(_changeItemSection 0)
	SET(CHANGELOG_ITEMS "")
	## Parse release file
	FOREACH(_line ${_release_lines})
	    IF(_changeItemSection)
		### Append lines in change section
		STRING_APPEND(CHANGELOG_ITEMS "${_line}" "\n")
	    ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
		### Start the change section
		SET(_changeItemSection 1)
	    ELSE(_changeItemSection)
		### Variable Setting section
		SETTING_STRING_GET_VARIABLE(var value "${_line}")
		#MESSAGE("var=${var} value=${value}")
		IF(NOT var MATCHES "#")
		    IF(var STREQUAL "PRJ_VER")
			SET_COMPILE_ENV(${var} "${value}" CACHE STRING "Project Version" FORCE)
		    ELSEIF(var STREQUAL "SUMMARY")
			SET(CHANGE_SUMMARY "${value}" CACHE STRING "Change Summary" FORCE)
		    ELSE(var STREQUAL "PRJ_VER")
			SET(${var} "${value}" CACHE STRING "${var}" FORCE)
		    ENDIF(var STREQUAL "PRJ_VER")
		ENDIF(NOT var MATCHES "#")
	    ENDIF(_changeItemSection)
	ENDFOREACH(_line ${_release_line})


	SET_COMPILE_ENV(PRJ_DOC_DIR "${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}"
	    CACHE PATH "Project docdir prefix" FORCE
	    )

	MANAGE_CHANGELOG_UPDATE(${CHANGELOG_FILE} ${PRJ_VER} "${CHANGELOG_ITEMS}")

	ADD_CUSTOM_COMMAND(OUTPUT ${CHANGELOG_ITEM_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${RELEASE_NOTE_FILE}
	    VERBATIM
	    )
	    
	ADD_CUSTOM_COMMAND(OUTPUT ${CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${RELEASE_NOTES_FILE}
	    COMMENT "Building ${CHANGELOG_FILE}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(changelog ALL
	    DEPENDS ${CHANGELOG_FILE}
	    VERBATIM
	    )

    ENDFUNCTION(RELEASE_NOTES_READ_FILE)
ENDIF(NOT DEFINED _MANAGE_VERSION_CMAKE_)

