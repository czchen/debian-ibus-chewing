# - Module for File Handling Function
#
# Includes:
#   ManageMessage
#
# Defines following variables:
#
# Defines following functions:
#   FIND_FILE_ERROR_HANDLING(<VAR>
#     [ERROR_MSG errorMessage]
#     [ERROR_VAR errorVar]
#     [VERBOSE_LEVEL verboseLevel]
#     [FIND_FILE_ARGS ...]
#   )
#     - Find a file, with proper error handling.
#       It is essentially a wrapper of FIND_FILE
#       * Parameter:
#         + VAR: The variable that stores the path of the found program.
#         + name: The filename of the command.
#         + verboseLevel: See ManageMessage for semantic of 
#           each verbose level.
#         + ERROR_MSG errorMessage: Error message to be append.
#         + ERROR_VAR errorVar: Variable to be set as 1 when not found.
#         + FIND_FILE_ARGS: A list of arguments to be passed 
#           to FIND_FILE
#
#   FIND_PROGRAM_ERROR_HANDLING(<VAR>
#     [ERROR_MSG errorMessage]
#     [ERROR_VAR errorVar]
#     [VERBOSE_LEVEL verboseLevel]
#     [FIND_PROGRAM_ARGS ...]
#   )
#     - Find an executable program, with proper error handling.
#       It is essentially a wrapper of FIND_PROGRAM
#       * Parameter:
#         + VAR: The variable that stores the path of the found program.
#         + name: The filename of the command.
#         + verboseLevel: See ManageMessage for semantic of 
#           each verbose level.
#         + ERROR_MSG errorMessage: Error message to be append.
#         + ERROR_VAR errorVar: Variable to be set as 1 when not found.
#         + FIND_PROGRAM_ARGS: A list of arguments to be passed 
#           to FIND_PROGRAM
#
# Defines following macros:
#   MANAGE_FILE_INSTALL(fileType
#     [files | FILES files] [DEST_SUBDIR subDir] [RENAME newName] [ARGS args]
#   )
#     - Manage file installation.
#       * Parameter:
#         + fileType: Type of files. Valid values:
#           BIN, PRJ_DOC, DATA, PRJ_DATA, 
#           SYSCONF, SYSCONF_NO_REPLACE, 
#           LIB, LIBEXEC, TARGETS
#         + DEST_SUBDIR subDir: Subdir of Destination dir
#         + files: Files to be installed.
#         + RENAME newName: Destination filename.
#         + args: Arguments for INSTALL.
#
#   GIT_GLOB_TO_CMAKE_REGEX(var glob)
#     - Convert git glob to cmake file regex
#       This macro covert git glob used in gitignore to
#       cmake file regex used in CPACK_SOURCE_IGNORE_FILES
#       * Parameter:
#         + var: Variable that hold the result.
#         + glob: Glob to be converted
#

IF(NOT DEFINED _MANAGE_FILE_CMAKE_)
    SET(_MANAGE_FILE_CMAKE_ "DEFINED")
    SET(FILE_INSTALL_LIST_TYPES 
	"BIN" "PRJ_DOC" "DATA" "PRJ_DATA" "SYSCONF" "SYSCONF_NO_REPLACE"
       	"LIB" "LIBEXEC"
	)

    MACRO(_MANAGE_FILE_SET_FILE_INSTALL_LIST fileType)
	SET(FILE_INSTALL_${fileType}_LIST "${FILE_INSTALL_${fileType}_LIST}"
	    CACHE INTERNAL "List of files install as ${fileType}" FORCE
	    )
    ENDMACRO(_MANAGE_FILE_SET_FILE_INSTALL_LIST fileType)

    FOREACH(_fLT ${FILE_INSTALL_LIST_TYPES})
	SET(FILE_INSTALL_${_fLT}_LIST "")
	_MANAGE_FILE_SET_FILE_INSTALL_LIST(${_fLT})
    ENDFOREACH(_fLT ${FILE_INSTALL_LIST_TYPES})

    MACRO(_MANAGE_FILE_INSTALL_FILE_OR_DIR fileType)
	IF(_opt_RENAME)
	    SET(_install_options "RENAME" "${_opt_RENAME}")
	ELSE(_opt_RENAME)
	    SET(_install_options "")
	ENDIF (_opt_RENAME)
	FOREACH(_f ${_fileList})
	    GET_FILENAME_COMPONENT(_a "${_f}" ABSOLUTE)
	    SET(_absolute "")
	    STRING(REGEX MATCH "^/" _absolute "${_f}")
	    IF(IS_DIRECTORY "${_a}") 
		SET(_install_type "DIRECTORY")
	    ELSE(IS_DIRECTORY "${_a}")
		IF("${fileType}" STREQUAL "BIN")
		    SET(_install_type "PROGRAMS")
		ELSE("${fileType}" STREQUAL "BIN")
		    SET(_install_type "FILES")
		ENDIF("${fileType}" STREQUAL "BIN")
	    ENDIF(IS_DIRECTORY "${_a}")
	    INSTALL(${_install_type} ${_f} DESTINATION "${_destDir}"
		${_install_options} ${ARGN})
	    IF(_opt_RENAME)
		SET(_n "${_opt_RENAME}")
	    ELSEIF(_absolute)
		GET_FILENAME_COMPONENT(_n "${_f}" NAME)
	    ELSE(_opt_RENAME)
		SET(_n "${_f}")
	    ENDIF(_opt_RENAME)

	    IF(_opt_DEST_SUBDIR)
		LIST(APPEND FILE_INSTALL_${fileType}_LIST
		    "${_opt_DEST_SUBDIR}/${_n}")
	    ELSE(_opt_DEST_SUBDIR)
		LIST(APPEND FILE_INSTALL_${fileType}_LIST
		    "${_n}")
	    ENDIF(_opt_DEST_SUBDIR)
	ENDFOREACH(_f ${_fileList})
	_MANAGE_FILE_SET_FILE_INSTALL_LIST("${fileType}")

    ENDMACRO(_MANAGE_FILE_INSTALL_FILE_OR_DIR fileType)

    MACRO(_MANAGE_FILE_INSTALL_TARGET)
	SET(_installValidOptions "RUNTIME" "LIBEXEC" "LIBRARY" "ARCHIVE")
	VARIABLE_PARSE_ARGN(_oT _installValidOptions ${ARGN})
	SET(_installOptions "")
	FOREACH(_f ${_fileList})
	    GET_TARGET_PROPERTY(_tP "${_f}" TYPE)
	    IF(_tP STREQUAL "EXECUTABLE")
		LIST(APPEND _installOptions RUNTIME)
		IF(_oT_RUNTIME)
		    LIST(APPEND FILE_INSTALL_BIN_LIST ${_f})
		    _MANAGE_FILE_SET_FILE_INSTALL_LIST("BIN")
		    LIST(APPEND _installOptions "${_oT_RUNTIME}")
		ELSEIF(_oT_LIBEXEC)
		    LIST(APPEND FILE_INSTALL_LIBEXEC_LIST ${_f})
		    _MANAGE_FILE_SET_FILE_INSTALL_LIST("LIBEXEC")
		    LIST(APPEND _installOptions "${_oT_LIBEXEC}")
		ELSE(_oT_RUNTIME)
		    M_MSG(${M_ERROR} 
			"MANAGE_FILE_INSTALL_TARGETS: Type ${_tP} is not yet implemented.")
		ENDIF(_oT_RUNTIME)
	    ELSEIF(_tP STREQUAL "SHARED_LIBRARY")
		LIST(APPEND FILE_INSTALL_LIB_LIST ${_f})
		_MANAGE_FILE_SET_FILE_INSTALL_LIST("LIB")
		LIST(APPEND _installOptions "LIBRARY" "${_oT_LIBRARY}")
	    ELSEIF(_tP STREQUAL "STATIC_LIBRARY")
		M_MSG(${M_OFF} 
		    "MANAGE_FILE_INSTALL_TARGETS: Fedora does not recommend type ${_tP}, excluded from rpm")
		LIST(APPEND _installOptions "ARCHIVE" "${_oT_ARCHIVE}")
	    ELSE(_tP STREQUAL "EXECUTABLE")
		M_MSG(${M_ERROR} 
		    "MANAGE_FILE_INSTALL_TARGETS: Type ${_tP} is not yet implemented.")
	    ENDIF(_tP STREQUAL "EXECUTABLE")
	ENDFOREACH(_f ${_fileList})
	INSTALL(TARGETS ${_fileList} ${_installOptions})
    ENDMACRO(_MANAGE_FILE_INSTALL_TARGET)

    MACRO(MANAGE_FILE_INSTALL fileType)
	SET(_validOptions "DEST_SUBDIR" "FILES" "ARGS" "RENAME")
	VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
	SET(_fileList "")
	LIST(APPEND _fileList ${_opt} ${_opt_FILES})

	IF("${fileType}" STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${SYSCONF_DIR}/${_opt_DEST_SUBDIR}")
	    _MANAGE_FILE_INSTALL_FILE_OR_DIR("${fileType}")
	ELSEIF("${fileType}" STREQUAL "TARGETS")
	    _MANAGE_FILE_INSTALL_TARGET(${_opt_ARGS})
	ELSE("${fileType}" STREQUAL "SYSCONF_NO_REPLACE")
	    SET(_destDir "${${fileType}_DIR}/${_opt_DEST_SUBDIR}")
	    _MANAGE_FILE_INSTALL_FILE_OR_DIR("${fileType}")
	ENDIF("${fileType}" STREQUAL "SYSCONF_NO_REPLACE")
    ENDMACRO(MANAGE_FILE_INSTALL fileType)

    FUNCTION(FIND_FILE_ERROR_HANDLING VAR)
	SET(_verboseLevel ${M_ERROR})
	SET(_errorMsg "")
	SET(_errorVar "")
	SET(_findFileArgList "")
	SET(_state "")
	FOREACH(_arg ${ARGN})
	    IF(_state STREQUAL "ERROR_MSG")
		SET(_errorMsg "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "ERROR_VAR")
		SET(_errorVar "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "VERBOSE_LEVEL")
		SET(_verboseLevel "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "FIND_FILE_ARGS")
		LIST(APPEND _findFileArgList "${_arg}")
	    ELSE(_state STREQUAL "ERROR_MSG")
		IF(_arg STREQUAL "ERROR_MSG")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "ERROR_VAR")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "VERBOSE_LEVEL")
		    SET(_state "${_arg}")
		ELSE(_arg STREQUAL "ERROR_MSG")
		    SET(_state "FIND_FILE_ARGS")
		    LIST(APPEND _findFileArgList "${_arg}")
		ENDIF(_arg STREQUAL "ERROR_MSG")
	    ENDIF(_state STREQUAL "ERROR_MSG")
	ENDFOREACH(_arg ${ARGN})

	FIND_FILE(${VAR} ${_findFileArgList})
	IF(${VAR} STREQUAL "${VAR}-NOTFOUND")
	    M_MSG(${_verboseLevel} "File ${_findFileArgList} is not found!${_errorMsg}")
	    IF (NOT _errorVar STREQUAL "")
		SET(${_errorVar} 1)
	    ENDIF(NOT _errorVar STREQUAL "")
	ENDIF(${VAR} STREQUAL "${VAR}-NOTFOUND")
    ENDFUNCTION(FIND_FILE_ERROR_HANDLING VAR)

    FUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR)
	SET(_verboseLevel ${M_ERROR})
	SET(_errorMsg "")
	SET(_errorVar "")
	SET(_findProgramArgList "")
	SET(_state "")
	FOREACH(_arg ${ARGN})
	    IF(_state STREQUAL "ERROR_MSG")
		SET(_errorMsg "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "ERROR_VAR")
		SET(_errorVar "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "VERBOSE_LEVEL")
		SET(_verboseLevel "${_arg}")
		SET(_state "")
	    ELSEIF(_state STREQUAL "FIND_PROGRAM_ARGS")
		LIST(APPEND _findProgramArgList "${_arg}")
	    ELSE(_state STREQUAL "ERROR_MSG")
		IF(_arg STREQUAL "ERROR_MSG")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "ERROR_VAR")
		    SET(_state "${_arg}")
		ELSEIF(_arg STREQUAL "VERBOSE_LEVEL")
		    SET(_state "${_arg}")
		ELSE(_arg STREQUAL "ERROR_MSG")
		    SET(_state "FIND_PROGRAM_ARGS")
		    LIST(APPEND _findProgramArgList "${_arg}")
		ENDIF(_arg STREQUAL "ERROR_MSG")
	    ENDIF(_state STREQUAL "ERROR_MSG")
	ENDFOREACH(_arg ${ARGN})

	FIND_PROGRAM(${VAR} ${_findProgramArgList})
	IF(${VAR} STREQUAL "${VAR}-NOTFOUND")
	    M_MSG(${_verboseLevel} "Program ${_findProgramArgList} is not found!${_errorMsg}")
	    IF (NOT _errorVar STREQUAL "")
		SET(${_errorVar} 1)
	    ENDIF(NOT _errorVar STREQUAL "")
	ENDIF(${VAR} STREQUAL "${VAR}-NOTFOUND")
    ENDFUNCTION(FIND_PROGRAM_ERROR_HANDLING VAR)

    MACRO(GIT_GLOB_TO_CMAKE_REGEX var glob)
	SET(_s "${glob}")
	STRING(REGEX REPLACE "!" "!e" _s "${_s}")
	STRING(REGEX REPLACE "[*]{2}" "!d" _s "${_s}")
	STRING(REGEX REPLACE "[*]" "!s" _s "${_s}")
	STRING(REGEX REPLACE "[?]" "!q" _s "${_s}")
	STRING(REGEX REPLACE "[.]" "\\\\\\\\." _s "${_s}")
	STRING(REGEX REPLACE "!d" ".*" _s "${_s}")
	STRING(REGEX REPLACE "!s" "[^/]*" _s "${_s}")
	STRING(REGEX REPLACE "!q" "[^/]" _s "${_s}")
	STRING(REGEX REPLACE "!e" "!" _s "${_s}")
	STRING(LENGTH "${_s}" _len)
	MATH(EXPR _l ${_len}-1)
	STRING(SUBSTRING "${_s}" ${_l} 1 _t)
	IF( _t STREQUAL "/")
	    SET(_s "/${_s}")
	ELSE( _t STREQUAL "/")
	    SET(_s "${_s}\$")
	ENDIF( _t STREQUAL "/")
	SET(${var} "${_s}")
    ENDMACRO(GIT_GLOB_TO_CMAKE_REGEX var glob)
    
ENDIF(NOT DEFINED _MANAGE_FILE_CMAKE_)

