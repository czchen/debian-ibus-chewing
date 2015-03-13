# - Manage Fedora and EPEL releases.
#
# This module provides convenient targets and functions for Fedora and 
# EPEL releases with fedpkg, koji, and bodhi.
# 
# In cmake-fedora, this release steps are:
#  1. Create SRPM and RPMs
#  2. Whether SRPM and RPMs pass rpmlint
#  3. Whether SRPM can be build with koji scratch build
#  4. Tag the release with PRJ_VER
#  5. Build SRPM with FedPkg
#  6. Release to Bodhi
#
# Consequently, function RELEASE_FEDORA() should be run after 
# PACK_RPM() and source version control functions like
# MANAGE_SOURCE_VERSION_CONTROL_GIT().
#
# If CMAKE_FEDORA_ENABLE_FEDORA=1, this module will proceed;
# otherwise, this module is skipped.
#
# This module check following files for dependencies:
#   - ~/.fedora-upload-ca.cert : Ensure it has certificate file to
#     submit to Fedora.
#   - fedpkg : Required to submit to fedora.
#   - koji : Required to submit to fedora.
#   - bodhi : Required to submit to fedora.
# If any of above files are missing, this module will be skipped.
#
# This module read the supported release information from 
# cmake-fedora.conf, it finds cmake-fedora.conf in following order:
#  1. Current directory
#  2. Path as defined CMAKE_SOURCE_DIR
#  3. /etc/cmake-fedora.conf
#
# Included Modules:
#   - ManageFile
#   - ManageMessage
#   - ManageTarget
#   - ManageRPM
#   - ManageVariable
#
# Reads following variables:
#   - CMAKE_FEDORA_TMP_DIR
#   - PRJ_SRPM_FILE: Project 
#
# Defines following variables:
#   - CMAKE_FEDORA_CONF: Path to cmake_fedora.conf
#   - FEDPKG_EXECUTABLE: Path to fedpkg
#   - KOJI_EXECUTABLE: Path to koji
#   - GIT_EXECUTABLE: Path to git
#   - BODHI_EXECUTABLE: Path to bodhi
#   - KOJI_BUILD_SCRATCH_EXECUTABLE: Path to koji-build-scratch
#   - FEDPKG_DIR: Dir for FedPkg checkout. 
#       It will use environment variable FEDPKG_DIR, then use
#       ${CMAKE_FEDORA_TMP_DIR}/FedPkg.
#   - FEDORA_KAMA: Fedora Karma. Default:3
#   - FEDORA_UNSTABLE_KARMA: Fedora unstable Karma. Default:3
#
# Defines following functions:
#   RELEASE_FEDORA([<scope> ...] 
#       [DEPENDS <dependFile> ...]
#       [TARGETS <target> ...]
#     )
#     - Release this project to specified Fedora and EPEL releases.
#       * Parameters:
#         + scope ...: List of Fedora and EPEL release to be build.
#           Valid values:
#           - rawhide: Build rawhide.
#           - fedora: Build actives fedora releases, including Rawhide.
#           - fedora_1: Build the latest supported fedora releases.
#             This is one release eariler than rawhide.
#           - fedora_2: Build the second latest supported fedora releases.
#             This is two releases eariler than rawhide.
#           - f22 f21 ...: Build the specified fedora releases.
#           - epel: Build the currently supported EPEL releases.
#           - epel_1: Build the latest supported EPEL releases.
#           - epel_2: Build the second latest supported EPEL releases.
#           - el7 el6 ... : The EPEL releases to be built.
#           If not specified, "fedora epel" will be used.
#         + DEPENDS dependFile ...: Files that target "release-fedora"
#             depends on.
#         + TARGETS target ...: Targets that target "release-fedora"
#             depends on. 
#             Note that if a target does not exist, a M_ERROR message 
#             will be shown.
#
#       * Reads following variables:
#         + PRJ_SRPM_FILE: Project SRPM
#         + FEDPKG_DIR: Directory for fedpkg checkout.
#       * Defines following targets:
#         + fedpkg_build: Build with fedpkg and push to bodhi.
#            This depends on the tag file from source control
#            (i.e. MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE)
#         + koji_build_scratch: Scratch build using koji.
#            This depends on target "rpmlint".
#            Target "tag_pre" should be dependent on this target.
#            A M_ERROR message will shown if target "tag_pre" does not
#            exist.
#         + release_fedora: Releases on fedora and/or EPEL.
#            This depends on target "fedpkg_build".
#            After this target is built, release on Fedora should be
#            completed.
#

IF(NOT CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
    RETURN()
ENDIF(NOT CMAKE_FEDORA_ENABLE_FEDORA_BUILD)
IF(DEFINED _MANAGE_RELEASE_FEDORA_)
    RETURN()
ENDIF(DEFINED _MANAGE_RELEASE_FEDORA_)
SET(_MANAGE_RELEASE_FEDORA_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageTarget)
INCLUDE(ManageRPM)
INCLUDE(ManageVariable)
SET(_manage_release_fedora_dependencies_missing 0)

MANAGE_CMAKE_FEDORA_CONF(CMAKE_FEDORA_CONF
    ERROR_MSG "cmake-fedora.conf not found. Fedora release support disabled."
    ERROR_VAR _manage_release_fedora_dependencies_missing
    VERBOSE_LEVEL ${M_OFF}
    )

MACRO(RELEASE_FEDORA_FIND_FILE_DEPENDENCY var name)
    FIND_FILE_ERROR_HANDLING(${var}
	ERROR_MSG "${name} not found, Fedora release support disabled."
	ERROR_VAR _manage_release_fedora_dependencies_missing
	VERBOSE_LEVEL ${M_OFF}
	FIND_ARGS NAMES ${name} ${ARGN}
	)
ENDMACRO(RELEASE_FEDORA_FIND_FILE_DEPENDENCY)

MACRO(RELEASE_FEDORA_FIND_DEPENDENCY var name)
    FIND_PROGRAM_ERROR_HANDLING(${var}
	ERROR_MSG "${name} not found, Fedora release support disabled."
	ERROR_VAR _manage_release_fedora_dependencies_missing
	VERBOSE_LEVEL ${M_OFF}
	FIND_ARGS NAMES ${name} ${ARGN}
	)
ENDMACRO(RELEASE_FEDORA_FIND_DEPENDENCY var)

RELEASE_FEDORA_FIND_FILE_DEPENDENCY(FEDORA_UPLOAD_CA_CERT 
    ".fedora-upload-ca.cert" PATHS $ENV{HOME})
RELEASE_FEDORA_FIND_DEPENDENCY(FEDPKG_EXECUTABLE fedpkg)
RELEASE_FEDORA_FIND_DEPENDENCY(KOJI_EXECUTABLE koji)
RELEASE_FEDORA_FIND_DEPENDENCY(GIT_EXECUTABLE git)
## Workaround for Bug 1115136 otherwise el7 won't work
RELEASE_FEDORA_FIND_DEPENDENCY(BODHI-CLIENT_EXECUTABLE bodhi client.py 
    PATHS "/usr/bin/bodhi")
RELEASE_FEDORA_FIND_DEPENDENCY(CMAKE_FEDORA_KOJI_EXECUTABLE "cmake-fedora-koji"
    HINTS ${CMAKE_FEDORA_SCRIPT_PATH_HINTS})
RELEASE_FEDORA_FIND_DEPENDENCY(CMAKE_FEDORA_FEDPKG_EXECUTABLE "cmake-fedora-fedpkg"
    HINTS ${CMAKE_FEDORA_SCRIPT_PATH_HINTS})
RELEASE_FEDORA_FIND_DEPENDENCY(KOJI_BUILD_SCRATCH_EXECUTABLE "koji-build-scratch"
    HINTS ${CMAKE_FEDORA_SCRIPT_PATH_HINTS})

## Set variables
IF(_manage_release_fedora_dependencies_missing)
    RETURN()
ENDIF(_manage_release_fedora_dependencies_missing)
# Set release tags according to CMAKE_FEDORA_CONF
SETTING_FILE_GET_ALL_VARIABLES(${CMAKE_FEDORA_CONF})

SET(BODHI_TEMPLATE_FILE "${CMAKE_FEDORA_TMP_DIR}/bodhi.template"
    CACHE FILEPATH "Bodhi template file"
    )

GET_ENV(FEDPKG_DIR "${CMAKE_FEDORA_TMP_DIR}/FedPkg" CACHE PATH "FedPkg dir")

## Fedora package variables
SET(FEDORA_KARMA "3" CACHE STRING "Fedora Karma")
SET(FEDORA_UNSTABLE_KARMA "-3" CACHE STRING "Fedora unstable Karma")

FUNCTION(RELEASE_FEDORA_KOJI_BUILD_SCRATCH)
    IF(_manage_release_fedora_dependencies_missing)
	RETURN()
    ENDIF(_manage_release_fedora_dependencies_missing)
    ADD_CUSTOM_TARGET(koji_build_scratch
	COMMAND ${KOJI_BUILD_SCRATCH_EXECUTABLE} ${PRJ_SRPM_FILE} ${ARGN}
	DEPENDS "${PRJ_SRPM_FILE}"
	COMMENT "koji_build_scratch: SRPM=${PRJ_SRPM_FILE}"
	VERBATIM
	)
    ADD_DEPENDENCIES(koji_build_scratch rpmlint)
    IF(TARGET tag_pre)
	ADD_DEPENDENCIES(tag_pre koji_build_scratch)
    ELSE(TARGET tag_pre)
	M_MSG(${M_ERROR} 
	    "RELEASE_FEDORA: Target tag_pre does not exist.")
    ENDIF(TARGET tag_pre)
ENDFUNCTION(RELEASE_FEDORA_KOJI_BUILD_SCRATCH)

FUNCTION(RELEASE_FEDORA_FEDPKG)
    IF(_manage_release_fedora_dependencies_missing)
	RETURN()
    ENDIF(_manage_release_fedora_dependencies_missing)
    SET(_cmdOpts "")
    IF ("${CHANGE_SUMMARY}" STREQUAL "")
	SET(CHANGE_SUMMARY "Release ${PROJECT_NAME}-${PRJ_VER}")
    ENDIF("${CHANGE_SUMMARY}" STREQUAL "")

    IF (NOT "${REDHAT_BUGZILLA}" STREQUAL "")
	LIST(APPEND _cmdOpts "-b" "${REDHAT_BUGZILLA}")
    ENDIF(NOT "${REDHAT_BUGZILLA}" STREQUAL "")

    ADD_CUSTOM_TARGET(fedpkg_build
	COMMAND ${CMAKE_FEDORA_FEDPKG_EXECUTABLE} -d "${FEDPKG_DIR}"
	-m "${CHANGE_SUMMARY}"
	${_cmdOpts} "${PRJ_SRPM_FILE}" ${ARGN}
	VERBATIM
	)
    ADD_DEPENDENCIES(fedpkg_build tag_post)
ENDFUNCTION(RELEASE_FEDORA_FEDPKG)

FUNCTION(RELEASE_FEDORA)
    IF(_manage_release_fedora_dependencies_missing)
	RETURN()
    ENDIF(_manage_release_fedora_dependencies_missing)

    ## Parse tags
    SET(_validOptions "DEPENDS" "TARGETS")
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})
    SET(_releaseDependOptList "")

    IF(NOT "${_o_DEPENDS}" STREQUAL "")
	SET(_releaseDependOptList DEPENDS ${_o_DEPENDS})
    ENDIF(NOT "${_o_DEPENDS}" STREQUAL "")

    SET(_scopeList ${_o})
    RELEASE_FEDORA_KOJI_BUILD_SCRATCH(${_scopeList})
    RELEASE_FEDORA_FEDPKG(${_scopeList})
    ADD_CUSTOM_TARGET(release_fedora
	${_releaseDependOptList}
	COMMENT "release_fedora: ${_scopeList}"
	)
    ADD_DEPENDENCIES(release_fedora fedpkg_build)

    ## Add dependent targets that actually exists
    SET(_releaseTargets "")
    FOREACH(_target ${_o_TARGETS})
	IF(TARGET ${_target})
	    LIST(APPEND _releaseTargets "${_target}")
	    ## Release targets should be build after target tag
	    ADD_DEPENDENCIES(${_target} tag)
	    ADD_DEPENDENCIES(release_fedora ${_target})
	ELSE(TARGET ${_target})
	    M_MSG(${M_ERROR} 
		"RELEASE_FEDORA: Target ${_target} does not exist.")
	ENDIF(TARGET ${_target})
    ENDFOREACH(_target)
ENDFUNCTION(RELEASE_FEDORA)

