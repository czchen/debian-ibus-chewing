# - Manage release by provides release related targets.
#
# Included Modules:
#   - ManageMessage
#   - ManageVariable
#
#  Defines following functions:
#  MANAGE_RELEASE([<releaseTarget ...>] [DEPENDS <dependFile ...>])
#    - Run release targets.
#      This macro skips the missing targets so distro package maintainers
#      do not have to get the irrelevant dependencies.
#      For the "hard" dependency, use cmake command "ADD_DEPENDENCIES".
#      * Parameters:
#        + releaseTarget ...: Targets to be executed before a release.
#          Note that sequence of the targets does not guarantee the
#          sequence of execution.
#        + DEPENDS dependFile ...: Files that target "release" depends on.
#      * Defines following targets:
#        + release: Perform everything required for a release.
#

IF(DEFINED _MANAGE_RELEASE_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_RELEASE_CMAKE_)
SET(_MANAGE_RELEASE_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageVariable)

FUNCTION(MANAGE_RELEASE)
    SET(_validOptions "DEPENDS")
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})
    SET(_releaseDependOptList "")

    IF(NOT "${_o_DEPENDS}" STREQUAL "")
	SET(_releaseDependOptList DEPENDS ${_o_DEPENDS})
    ENDIF(NOT "${_o_DEPENDS}" STREQUAL "")

    ## Target: release
    ADD_CUSTOM_TARGET(release
	${_releaseDependOptList}
	COMMENT "release: ${PROJECT_NAME}-${PRJ_VER}"
	)

    ## Add dependent targets that actually exists
    SET(_releaseTargets "")
    FOREACH(_target ${_o})
	IF(TARGET ${_target})
	    LIST(APPEND _releaseTargets "${_target}")
	    ## Release targets should be build after target tag
	    ADD_DEPENDENCIES(${_target} tag)
	    ADD_DEPENDENCIES(release ${_target})
	ELSE(TARGET ${_target})
	    M_MSG(${M_OFF} "MANAGE_RELEASE: Target ${_target} does not exist, skipped.")
	ENDIF(TARGET ${_target})
    ENDFOREACH(_target)
ENDFUNCTION(MANAGE_RELEASE)

