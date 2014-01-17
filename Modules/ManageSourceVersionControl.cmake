# - Module for manipulate source version control systems.
# This module provides an universal interface for supported
# source version control systems, namely:
# Git, Mercurial and SVN.
#
# Following targets are defined for each source version control (in Git terminology):
#   - tag: Tag the working tree with PRJ_VER and CHANGE_SUMMARY.
#     This target also does:
#     1. Ensure there is nothing uncommitted.
#     2. Push the commits and tags to server
#   - tag_pre: Targets that 'tag' depends on.
#     So you can push some check before the tag.
#
# Following variables are defined for each source version control:
#   - MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE:
#     The file that would be touched after target tag is completed.
#
#

IF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
    INCLUDE(ManageTarget)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)
	ADD_CUSTOM_TARGET(tag_pre
	    COMMENT "Pre-tagging check"
	    )

    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_COMMON)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_SOURCE_DIR}/.git/refs/tags/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File" FORCE)


	ADD_CUSTOM_TARGET(commit_clean
	    COMMAND git diff --exit-code
	    COMMENT "Is git commit clean?"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(tag
	    DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    )

	ADD_CUSTOM_TARGET(tag_push
	    COMMAND git push
	    COMMAND git push --tags
	    DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    COMMENT "Push to git"
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMAND make commit_clean
	    COMMAND make tag_pre
	    COMMAND git tag -a -m "${CHANGE_SUMMARY}" "${PRJ_VER}" HEAD
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )
	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_GIT)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_HG)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_FEDORA_TEMP_DIR}/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File" FORCE)

	ADD_CUSTOM_TARGET(tag
	    DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    )

	ADD_CUSTOM_COMMAND(OUTPUT "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    COMMAND make tag_pre
	    COMMAND hg tag -m "${CHANGE_SUMMARY}" "${PRJ_VER}"
	    COMMAND ${CMAKE_COMMAND} -E touch "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )
	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_HG)

    MACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)
	SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	    ${CMAKE_FEDORA_TEMP_DIR}/${PRJ_VER}
	    CACHE PATH "Source Version Control Tag File" FORCE)

	ADD_CUSTOM_TARGET(tag
	    DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    )

	ADD_CUSTOM_TARGET(OUTPUT "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	    COMMAND make tag_pre
	    COMMAND svn copy "${SOURCE_BASE_URL}/trunk" "${SOURCE_BASE_URL}/tags/${PRJ_VER}" -m "${CHANGE_SUMMARY}"
	    COMMAND cmake -E touch ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	    COMMENT "Tagging the source as ver ${PRJ_VER}"
	    VERBATIM
	    )

	MANAGE_SOURCE_VERSION_CONTROL_COMMON()
    ENDMACRO(MANAGE_SOURCE_VERSION_CONTROL_SVN)

ENDIF(NOT DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)

