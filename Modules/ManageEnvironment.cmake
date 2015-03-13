# - Manage environment in build mode after project information is defined.
#
# This module manages build mode environment, including variables, compiler 
# flags and CMake policies.
#
# The main difference between this module and ManageEnvironmentCommon are:
#   - ManageEnvironmentCommon is called by both script and build mode;
#       while this module is called by only build mode.
#   - ManageEnvironmentCommon should be invoked before project definition;
#       this module should be invoked after project defintion.
#   - ManageEnvironmentCommon caches only variables; 
#       this module not only caches variables, but also set the compiler flags.
#
# Included Modules:
#   - ManageMessage
#
# Reads following variables:
#   - CMAKE_INSTALL_PREFIX: Install directory used by install.
#   - PROJECT_NAME: Project name.
#
# Set cache for following variables:
#   - PRJ_DATA_DIR: Project data dir
#     Default: ${DATA_DIR}/${PROJECT_NAME}
#   - PRJ_DOC_DIR: Project doc dir
#     Default: ${DOC_DIR}/${PROJECT_NAME}
#
# Defines following compile flags: (which use variables with same names)
#   - CMAKE_INSTALL_PREFIX
#   - PROJECT_NAME
#   - BIN_DIR
#   - DATA_DIR
#   - DOC_DIR
#   - SYSCONF_DIR
#   - LIB_DIR
#   - LIBEXEC_DIR
#   - PRJ_DATA_DIR
#   - PRJ_DOC_DIR
#
# Note: compile flag PRJ_VER is defined in ManageVersion.
#
# Defines following functions:
#   SET_COMPILE_ENV(<var> [<defaultValue>] [ENV_NAME <envName>]
#       [CACHE <type> <docstring> [FORCE]]
#     )
#     - Ensure a variable is set to nonempty value, then set the value
#       to the compile flags with same name.
#
#       The value is determined by first non-empty value:
#       1. Value of <var>.
#       2. Value of environment variable <var>, 
#          or if ENV_NAME is specified, value of <envName>.
#       3. <defaultValue>
#       * Parameters:
#         + var: Variable to be set
#         + defaultValue: Default value of the var
#         + envName: (Optional)The name of environment variable.
#           Only need if different from var.
#         + CACHE type docstring [FORCE]:
#           Same with "SET" command.
#

IF(DEFINED _MANAGE_ENVIRONMENT_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_ENVIRONMENT_CMAKE_)
SET(_MANAGE_ENVIRONMENT_CMAKE_ "DEFINED")

FUNCTION(SET_COMPILE_ENV var)
    SET(_stage "")
    SET(_env "${var}")
    SET(_setOpts "")
    SET(_force 0)
    SET(_defaultValue "")
    FOREACH(_arg ${ARGN})
	IF("${_arg}" STREQUAL "ENV_NAME")
	    SET(_stage "ENV_NAME")
	ELSEIF("${_arg}" STREQUAL "CACHE")
	    SET(_stage "_CACHE")
	ELSE()
	    IF("${_stage}" STREQUAL "ENV_NAME")
		SET(_env "${_arg}")
	    ELSEIF("${_stage}" STREQUAL "_CACHE")
		LIST(APPEND _setOpts "${_arg}")
		IF("${_arg}" STREQUAL "FORCE")
		    SET(_force 1)
		ENDIF()
	    ELSE()
		SET(_defaultValue "${_arg}")
	    ENDIF()
	ENDIF()
    ENDFOREACH(_arg ${ARGN})

    IF("${_setOpts}" STREQUAL "")
	SET(_setOpts "PARENT_SCOPE")
    ELSE()
	LIST(INSERT _setOpts 0 "CACHE")
    ENDIF()

    # Set the variable
    IF(NOT "${${var}}" STREQUAL "")
	SET(${var} "${${var}}" ${_setOpts})
    ELSEIF(NOT "$ENV{${_env}}" STREQUAL "")
	SET(${var} "$ENV{${_env}}" ${_setOpts})
    ELSE()
	## Use default value
	SET(${var} "${_defaultValue}" ${_setOpts})
    ENDIF()

    # Enforce CMP0005 to new, yet pop after ADD_DEFINITION
    CMAKE_POLICY(PUSH)
    CMAKE_POLICY(SET CMP0005 NEW)
    ADD_DEFINITIONS(-D${_env}=${${var}})
    CMAKE_POLICY(POP)
    M_MSG(${M_INFO2} "SET_COMPILE_ENV: ${var}=${${var}}")
ENDFUNCTION(SET_COMPILE_ENV)

MACRO(MANAGE_CMAKE_POLICY policyName defaultValue)
    IF(POLICY ${policyName})
	CMAKE_POLICY(GET "${policyName}" _cmake_policy_value)
	IF(_cmake_policy_value STREQUAL "")
	    # Policy not defined yet
	    CMAKE_POLICY(SET "${policyName}" "${defaultValue}")
	ENDIF(_cmake_policy_value STREQUAL "")
    ENDIF(POLICY ${policyName})
ENDMACRO(MANAGE_CMAKE_POLICY policyName defaultValue)

####################################################################
# Variables settings
# 

## CMAKE_FEODRA_MODULE_DIR: Directory contains cmake-fedora modules
INCLUDE(ManageMessage RESULT_VARIABLE MANAGE_ENVIRONMENT_PATH)
GET_FILENAME_COMPONENT(CMAKE_FEDORA_MODULE_DIR 
    "${MANAGE_ENVIRONMENT_PATH}" PATH CACHE
    )

FILE(MAKE_DIRECTORY "${CMAKE_FEDORA_TMP_DIR}")

## Print CMake system information
M_MSG(${M_INFO1} "CMAKE_HOST_SYSTEM=${CMAKE_HOST_SYSTEM}")
M_MSG(${M_INFO1} "CMAKE_HOST_SYSTEM_PROCESSOR=${CMAKE_HOST_SYSTEM_PROCESSOR}")
M_MSG(${M_INFO1} "CMAKE_SYSTEM=${CMAKE_SYSTEM}")
M_MSG(${M_INFO1} "CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}")

## Set compile flags
SET_COMPILE_ENV(BIN_DIR)
SET_COMPILE_ENV(DATA_DIR)
SET_COMPILE_ENV(DOC_DIR)
SET_COMPILE_ENV(SYSCONF_DIR)
SET_COMPILE_ENV(LIB_DIR)
SET_COMPILE_ENV(LIBEXEC_DIR)

IF(CMAKE_SYSTEM_PROCESSOR MATCHES "64")
    SET_COMPILE_ENV(IS_64)
ENDIF(CMAKE_SYSTEM_PROCESSOR MATCHES "64")

SET_COMPILE_ENV(PRJ_DATA_DIR "${DATA_DIR}/${PROJECT_NAME}"
    CACHE PATH "Project data dir"
    )
SET_COMPILE_ENV(PRJ_DOC_DIR "${DOC_DIR}/${PROJECT_NAME}"
    CACHE PATH "Project doc dir"
    )

SET_COMPILE_ENV(PROJECT_NAME)

