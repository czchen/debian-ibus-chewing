# - Module for manipulate source version control systems.
# This module provides an universal interface for supported
# source version control systems, namely:
# Git, Mercurial and SVN.
#
# Following targets are defined for each source version control 
#   (in Git terminology):
#   - tag: Tag the working tree with ${PRJ_VER} and ${CHANGE_SUMMARY}.
#      This target also ensure there is nothing uncommitted.
#   - tag_pre: Target that will be executed before target "tag".
#      So use ADD_DEPENDENCIES(tag_pre <target> ...) for the targets
#      that need to be done before target <tag>.
#   - tag_post: Target that will be executed after target "tag".
#      This target will push the tagged commit to server.
#      This target depends (directly or indirectly) on target "tag".
#      So use ADD_DEPENDENCIES(tag_post <target> ...) for the targets
#      that need to be done after target <tag>.
#
#
# Included Modoule:
#   - ManageTarget
#   - ManageVariable
#
# Define following functions:
#   MANAGE_SOURCE_VERSION_CONTROL_GIT(
#       [PRE_TARGETS <target> ...] [POST_TARGETS <target> ...]
#     )
#     - Use Git as source version control.
#       * Parameters:
#         + PRE_TARGETS target ...: Targets before target "tag".
#         + POST_TARGETS target ... : Target after target "tag".
#       * Targets:
#         + tag: Tag the commit with ${PRJ_VER}
#         + tag_pre: Target hook for action before target "tag".
#         + tag_post: Target hook for action after target "tag".
#         + commit_clean: Whether the commit is clean.
#         + tag_push: Push tag and commit to server
#
#   MANAGE_SOURCE_VERSION_CONTROL_HG(
#       [PRE_TARGETS <target> ...] [POST_TARGETS <target> ...]
#     )
#     - (Experimental) Use Mercurial (HG)  as source version control.
#       * Parameters:
#         + PRE_TARGETS target ...: Targets before target "tag".
#         + POST_TARGETS target ... : Target after target "tag".
#       * Targets:
#         + tag: Tag the commit with ${PRJ_VER}
#         + tag_pre: Target hook for action before target "tag".
#         + tag_post: Target hook for action after target "tag".
#         + commit_clean: Whether the commit is clean.
#         + tag_push: Push tag and commit to server
#
#   MANAGE_SOURCE_VERSION_CONTROL_SVN(
#       SVN_URL <svnUrl>
#       [PRE_TARGETS <target> ...] [POST_TARGETS <target> ...]
#     ) 
#     - (Experimental) Use Subversion (SVN)  as source version control.
#       * Parameters:
#         + SVN_URL url: URL to svn repostory.
#             (e.g. http://server.com/repo/project)
#         + PRE_TARGETS target ...: Targets before target "tag".
#         + POST_TARGETS target ... : Target after target "tag".
#       * Targets:
#         + tag: Tag the commit with ${PRJ_VER}
#         + tag_pre: Target hook for action before target "tag".
#         + tag_post: Target hook for action after target "tag".
#         + tag_not_exist: Whether tag exists or not.
#

IF(DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_SOURCE_VERSION_CONTROL_CMAKE_)
SET(_MANAGE_SOURCE_VERSION_CONTROL_CMAKE_ "DEFINED")
INCLUDE(ManageTarget)
INCLUDE(ManageVariable)

FUNCTION(MANAGE_SOURCE_VERSION_CONTROL_COMMON)
    SET(_valid_options "PRE_TARGETS" "POST_TARGETS")
    VARIABLE_PARSE_ARGN(_o _valid_options ${ARGN})

    ADD_CUSTOM_TARGET(tag_pre
	COMMENT "tag_pre: ${_o} Pre-tagging check "
	)

    ADD_CUSTOM_TARGET(tag_post
	COMMENT "tag_pre: ${_o} Post-tagging actions "
	)

    ## Set the pre and post targets from argn
    IF(NOT "${_o_PRE_TARGETS}" STREQUAL "")
	ADD_DEPENDENCIES(tag_pre ${_o_PRE_TARGETS})
    ENDIF(NOT "${_o_PRE_TARGETS}" STREQUAL "")
    IF(NOT "${_o_POST_TARGETS}" STREQUAL "")
	ADD_DEPENDENCIES(tag_pre ${_o_POST_TARGETS})
    ENDIF(NOT "${_o_POST_TARGETS}" STREQUAL "")
ENDFUNCTION(MANAGE_SOURCE_VERSION_CONTROL_COMMON)

FUNCTION(MANAGE_SOURCE_VERSION_CONTROL_GIT)
    MANAGE_SOURCE_VERSION_CONTROL_COMMON(git ${ARGN})
    SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	${CMAKE_FEDORA_TMP_DIR}/target-tag-${PRJ_VER}
	CACHE PATH "Source Version Control Tag File" FORCE)

    ADD_CUSTOM_TARGET(tag
	DEPENDS ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	COMMENT "tag: tag ${PRJ_VER} in Git"
	VERBATIM
	)

    ADD_CUSTOM_COMMAND(OUTPUT ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	COMMAND cmake -D "cmd=make_tag_file" -D "ver=${PRJ_VER}" 
	-D "output_file=${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}" 
	-P ${CMAKE_FEDORA_MODULE_DIR}/ManageGitScript.cmake
	COMMENT "Tagging the source as ver ${PRJ_VER}"
	VERBATIM
	)

    ## Pre tags
    ADD_CUSTOM_TARGET(commit_clean
	COMMAND git diff --exit-code
	COMMENT "Is git commit clean?"
	VERBATIM
	)
    ADD_DEPENDENCIES(tag_pre commit_clean)

    ## Post tags
    ADD_CUSTOM_TARGET(tag_push
	COMMAND git push
	COMMAND git push --tags
	DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	COMMENT "Push to git"
	)
    ADD_DEPENDENCIES(tag_push tag)
    ADD_DEPENDENCIES(tag_post tag_push)
ENDFUNCTION(MANAGE_SOURCE_VERSION_CONTROL_GIT)

FUNCTION(MANAGE_SOURCE_VERSION_CONTROL_HG)
    MANAGE_SOURCE_VERSION_CONTROL_COMMON(Hg ${ARGN})

    ADD_CUSTOM_TARGET(tag
	COMMAND make tag_pre
	COMMAND hg tag -m "${CHANGE_SUMMARY}" "${PRJ_VER}"
	COMMENT "tag: Hg tagging ${PRJ_VER} "
	VERBATIM
	)

    ## Pre tags
    ADD_CUSTOM_TARGET(commit_clean
	COMMAND eval "hg sum | grep -qs -e '^commit: (clean)'"
	COMMENT "Is hg commit clean?"
	VERBATIM
	)
    ADD_DEPENDENCIES(tag_pre commit_clean)

    ## Post tags
    ADD_CUSTOM_TARGET(tag_push
	COMMAND hg push
	COMMENT "Push to hg"
	)
    ADD_DEPENDENCIES(tag_push tag)
    ADD_DEPENDENCIES(tag_post tag_push)
ENDFUNCTION(MANAGE_SOURCE_VERSION_CONTROL_HG)

FUNCTION(MANAGE_SOURCE_VERSION_CONTROL_SVN)
    MANAGE_SOURCE_VERSION_CONTROL_COMMON(SVN ${ARGN})
    SET(_valid_options "PRE_TARGETS" "POST_TARGETS" "SVN_URL")
    VARIABLE_PARSE_ARGN(_o _valid_options ${ARGN})

    SET(MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE
	${CMAKE_FEDORA_TMP_DIR}/SVN/${PRJ_VER}
	CACHE PATH "Source Version Control Tag File" FORCE)

    ADD_CUSTOM_TARGET(tag
	DEPENDS "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}"
	COMMENT "tag: SVN tagging ${PRJ_VER} "
	)

    ADD_CUSTOM_COMMAND(OUTPUT ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	COMMAND make tag_not_exist
	COMMAND make tag_pre
	COMMAND svn copy "${SOURCE_BASE_URL}/trunk" "${SOURCE_BASE_URL}/tags/${PRJ_VER}" -m "${CHANGE_SUMMARY}"
	COMMAND cmake -E touch ${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}
	COMMENT "Tagging the source as ver ${PRJ_VER}"
	VERBATIM
	)

    ## Pre tags
    ADD_CUSTOM_TARGET(tag_not_exist
	COMMAND if svn ls ${_o_SVN_URL}/${PRJ_VER} --depth empty &>/dev/null; then return 1;else return 0; fi
	)

    ## Post tags
    ADD_DEPENDENCIES(tag_post tag)
ENDFUNCTION(MANAGE_SOURCE_VERSION_CONTROL_SVN)

