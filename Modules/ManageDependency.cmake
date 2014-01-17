# - Dependency Management Module
# This module handle dependencies by using pkg-config and/or
# search the executable.
# 
# Includes:
#   ManageFile
#   ManageVersion
#
# Defines following macro:
#   MANAGE_DEPENDENCY(listVar var [VER ver [EXACT]] [REQUIRED] 
#     [PROGRAM_NAMES name1 ...] [PKG_CONFIG pkgConfigName]
#     [FEDORA_NAME fedoraPkgName] [DEVEL]
#     )
#     - Add a new dependency.
#       Arguments:
#       + listVar: List variable that hold all dependency of the same kind.
#       + var: Main variable. It recommend to use uppercase name,
#              such as GETTEXT
#       + VER ver [EXACT]: Minimum version.
#         Specify the exact version by providing "EXACT".
#       + REQUIRED: Specify that this dependency is required.
#       + PROGRAM_NAMES name1 ...: Executable to be found.
#         If found, ${var}_EXECUTABLE is defined as the full path 
#         to the executable; if not found; the whole dependency is
#         deemed as not found.
#       + PKG_CONFIG pkgConfigName: Name of the pkg-config file
#         exclude the directory and .pc. e.g. "gtk+-2.0"
#       + FEDORA_NAME fedoraPkgName: Package name in Fedora. 
#         If not specified, use the lower case of ${var}.
#         Note that '-devel' should be omitted here.
#       + DEVEL: devel package is used. It will append '-devel'
#         to fedoraPkgName
#
IF(NOT DEFINED _MANAGE_DEPENDENCY_CMAKE_)
    SET (_MANAGE_DEPENDENCY_CMAKE_ "DEFINED")
    INCLUDE(ManageFile)
    INCLUDE(ManageVariable)

    MACRO(MANAGE_DEPENDENCY listVar var)
	SET(_validOptions "VER" "EXACT" "REQUIRED" 
	    "PROGRAM_NAMES" "PKG_CONFIG" "FEDORA_NAME" "DEVEL")
	VARIABLE_PARSE_ARGN(${var} _validOptions ${ARGN})
	UNSET(_ver)
	UNSET(_rel)
	IF(DEFINED ${var}_REQUIRED)
	    SET(_verbose "${M_ERROR}")
	    SET(_required "REQUIRED")
	ELSE(DEFINED ${var}_REQUIRED)
	    SET(_verbose "${M_OFF}")
	    SET(_required "")
	ENDIF(DEFINED ${var}_REQUIRED)
	IF(${var}_VER)
	    SET(_ver "${${var}_VER}")
	    IF(DEFINED ${var}_EXACT)
		SET(_rel "=")
		SET(_exact "EXACT")
	    ELSE(DEFINED ${var}_EXACT)
		SET(_rel ">=")
		SET(_exact "")
	    ENDIF(DEFINED ${var}_EXACT)
	ENDIF(${var}_VER)

	IF(${var}_PROGRAM_NAMES)
	    MESSAGE(STATUS "checking for program '${${var}_PROGRAM_NAMES}'")
	    FIND_PROGRAM(${var}_EXECUTABLE NAMES "${${var}_PROGRAM_NAMES}"
		DOC "${var} executable"
		)
	    IF(${var}_EXECUTABLE-NOTFOUND)
		M_MSG("${_verbose}" "Cannot found ${${var}_PROGRAM_NAMES} in path.")
	    ELSE(${var}_EXECUTABLE-NOTFOUND)
		MESSAGE(STATUS "   found ${${var}_EXECUTABLE}")
	    ENDIF(${var}_EXECUTABLE-NOTFOUND)
	    FIND_PROGRAM_ERROR_HANDLING(${var}_EXECUTABLE
		VERBOSE_LEVEL "${_verbose}"
		"${${var}_PROGRAM_NAMES}"
		)
	    MARK_AS_ADVANCED(${var}_EXECUTABLE)
	ENDIF(${var}_PROGRAM_NAMES)

	IF(${var}_PKG_CONFIG)
	    IF(NOT PKG_CONFIG_VERSION)
		FIND_PACKAGE(PkgConfig REQUIRED)
		## Auto-add pkgconfig as dependency
		LIST(APPEND ${listVar} "pkgconfig")
	    ENDIF(NOT PKG_CONFIG_VERSION)
	    PKG_CHECK_MODULES(${var} ${_required}
		"${${var}_PKG_CONFIG}${_rel}${_ver}")
	    EXECUTE_PROCESS(COMMAND ${PKG_CONFIG_EXECUTABLE}
		--print-variables "${${var}_PKG_CONFIG}"
		OUTPUT_VARIABLE _variables
		OUTPUT_STRIP_TRAILING_WHITESPACE
		RESULT_VARIABLE _ret
		)
	    IF(NOT _ret)
		STRING_SPLIT(${var}_VARIABLES "\n" "${_variables}")
		FOREACH(_v ${${var}_VARIABLES})
		    STRING(TOUPPER "${_v}" _u)
		    EXECUTE_PROCESS(COMMAND ${PKG_CONFIG_EXECUTABLE}
			--variable "${_v}" "${${var}_PKG_CONFIG}"
			OUTPUT_VARIABLE ${var}_${_u}
			OUTPUT_STRIP_TRAILING_WHITESPACE
			)
		    MARK_AS_ADVANCED(${var}_${_u})
		    M_MSG(${M_INFO1} "${var}_${_u}=${${var}_${_u}}")
		ENDFOREACH(_v ${var}_VARIABLES)
	    ENDIF(NOT _ret)
	ENDIF(${var}_PKG_CONFIG)

	IF(${var}_FEDORA_NAME)
	    SET(_name "${${var}_FEDORA_NAME}")
	ELSE(${var}_FEDORA_NAME)
	    STRING(TOLOWER "${var}" _name)
	ENDIF(${var}_FEDORA_NAME)

	IF(DEFINED ${var}_DEVEL)
	    SET(_name "${_name}-devel")
	ENDIF(DEFINED ${var}_DEVEL)
	IF("${_ver}" STREQUAL "")
	    SET(_newDep  "${_name}")
	ELSE("${_ver}" STREQUAL "")
	    SET(_newDep  "${_name} ${_rel} ${_ver}")
	ENDIF("${_ver}" STREQUAL "")

	## Insert when it's not duplicated
	LIST(FIND ${listVar} "${_newDep}" _index)
	IF(_index EQUAL -1)
	    LIST(APPEND ${listVar} "${_newDep}")
	    SET(${listVar} "${${listVar}}" CACHE INTERNAL "${listVar}")
	ENDIF(_index EQUAL -1)
    ENDMACRO(MANAGE_DEPENDENCY listVar var)

ENDIF(NOT DEFINED _MANAGE_DEPENDENCY_CMAKE_)
