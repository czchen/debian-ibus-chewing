# Manage Gettext scripts 
MACRO(MANAGE_GETTEXT_SCRIPT_PRINT_USAGE)
    MESSAGE(
	"Manage gettext script: This script is not recommend for end users

cmake -D cmd=pot_make
	-D pot=<path/project.pot>
	-D \"exec:STRING=<cmd;--opt1;--opt2;value; ...>\"
	[\"-D<var>=<value>\"]
	[\"-D <var:TYPE>=<value>\"]
	-P <CmakeModulePath>/ManageGettextScript.cmake
    Update or create a POT file.
    Options:
	pot: Path to pot file
	exec:STRING: Command and options to create the POT file.
	    Note that \"STRING\" is needed, as its quite likely to pass the options 
	    like: \"--keyword=C_:1c,2;--keyword=NC_:1c,2\" which make cmake failed to
	    set the exec variable.

cmake -D cmd=po_make
      -D pot=<path/project.pot>
      [-D \"options:STRING=<--opt1;--opt2;value; ...>\"]
      [\"-Dlocales=<locale1;locale2...>\"  | -Dsystem_locales]
      [-Dpo_dir=<dir>]
      [\"-D<var>=<value>\"]
      [\"-D <var:TYPE>=<value>\"]
      -P <CmakeModulePath>/ManageGettextScript.cmake
    Update existing or create new PO files.
    Specifiy the PO of locales to be managed by either 
    locales or system_locales.
    If both are not specified, it will find the existing PO files. 
    Options:
	pot: Path to pot file
	options: Options to pass to msgmerge
	    Note that \"STRING\" is needed, as its quite likely to pass the options 
	    like: \"--keyword=C_:1c,2;--keyword=NC_:1c,2\" which make cmake failed to
	    set the exec variable.
	locales: Locale to be created
	system_locales: All locales in system would be created.
	po_dir: Directory to put po, otherwise it would use the path to pot.

cmake -D cmd=mo_make
      -D po_dir=<dir>
      [-D mo_dir=<dir>]
      [-D \"options=<--opt1;--opt2=value; ...>\"
      [-D \"locales=<locale1;locale2...>\"  | -Dsystem_locales]
      [-D \"<var>=<value>\"]
      -P <CmakeModulePath>/ManageGettextScript.cmake
    Update or create MO files.
    Options:
	prj_info: Path to prj_info.cmake
	po_dir: Directory that contains po.
	mo_dir: Directory to output mo.
	options:STRING: Options to pass to msgmerge
	    Note that \"STRING\" is needed, as its quite likely to pass the options 
	    like: \"--keyword=C_:1c,2;--keyword=NC_:1c,2\" which make cmake failed to
	    set the exec variable.
	locales: Locale to be created
	system_locales: All locales in system would be created.
    "
    )
ENDMACRO(MANAGE_GETTEXT_SCRIPT_PRINT_USAGE)

FUNCTION(CMD_TO_LIST listVar cmd)
    SET(_listNew "")
    FOREACH(_l ${cmd})
	IF( "${_l}" MATCHES "^-.+=.+")
	    SETTING_STRING_GET_VARIABLE(_k _v "${_l}")
	    LIST(APPEND _listNew "${_k}" "${_v}")
	ELSE()
	    LIST(APPEND _listNew "${_l}")
	ENDIF()
    ENDFOREACH(_l)
    SET(${listVar} "${_listNew}" PARENT_SCOPE)
ENDFUNCTION(CMD_TO_LIST)

MACRO(POT_MAKE)
    EXECUTE_PROCESS(COMMAND ${exec}
	RESULT_VARIABLE _res
	OUTPUT_VARIABLE _out
	ERROR_VARIABLE _err
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    IF(NOT _res EQUAL 0)
	M_MSG(${M_FATAL} "Failed ${exec}: ${_out} | ${_err}")
    ENDIF()
ENDMACRO(POT_MAKE)

MACRO(POT_MAKE_VARIABLE_CHECK)
    IF("${pot}" STREQUAL "")
	M_MSG(${M_FATAL} "Requires \"-Dpot=<path/project.pot>\"")
    ENDIF()
    IF("${exec}" STREQUAL "")
	M_MSG(${M_FATAL} "Requires \"-Dexec=<cmd;--opt1;...>\"")
    ENDIF()
    POT_MAKE()
ENDMACRO(POT_MAKE_VARIABLE_CHECK)

MACRO(PO_MAKE)
    SET(_gettext_locale_opts "")
    IF(DEFINED system_locales)
	LIST(APPEND _gettext_locale_opts "SYSTEM_LOCALES")
    ELSEIF(NOT "${locales}" STREQUAL "")
	LIST(APPEND _gettext_locale_opts "LOCALES" ${locales})
    ENDIF()
    IF("${po_dir}" STREQUAL "")
	GET_FILENAME_COMPONENT(po_dir "${pot}" PATH)
    ENDIF()
    MANAGE_GETTEXT_LOCALES(localeListVar "${po_dir}" ${_gettext_locale_opts})
    FOREACH(_l ${localeListVar})
	SET(_poFile "${po_dir}/${_l}.po")
	IF(EXISTS ${_poFile})
	    SET(exec "msgmerge" "--lang=${_l}" ${options} ${pot} ${_poFile})
	ELSE()
	    ## Po file does not exist, run msginit
	    SET(exec "msginit" "--locale=${_l}.utf8" 
		"--input=${pot}" "--output-file=${_poFile}"
		"--no-translator"
		)
	ENDIF()
	EXECUTE_PROCESS(COMMAND ${exec}
	    RESULT_VARIABLE _res
	    OUTPUT_VARIABLE _out
	    ERROR_VARIABLE _err
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	IF(NOT _res EQUAL 0)
	    M_MSG(${M_FATAL} "Failed ${exec}: ${_out} | ${_err}")
	ENDIF()
    ENDFOREACH(_l)
ENDMACRO(PO_MAKE)

MACRO(PO_MAKE_VARIABLE_CHECK)
    IF("${pot}" STREQUAL "")
	M_MSG(${M_FATAL} "Requires -D \"pot=<path/project.pot>\"")
    ENDIF()
    IF(NOT EXISTS ${pot})
	M_MSG(${M_FATAL} "Failed to find ${pot}")
    ENDIF()
    PO_MAKE()
ENDMACRO(PO_MAKE_VARIABLE_CHECK)

MACRO(MO_MAKE)
    SET(_gettext_locale_opts "")
    IF(DEFINED system_locales)
	LIST(APPEND _gettext_locale_opts "SYSTEM_LOCALES")
    ELSEIF(NOT "${locales}" STREQUAL "")
	LIST(APPEND _gettext_locale_opts "LOCALES" ${locales})
    ENDIF()
    IF("${mo_dir}" STREQUAL "")
	SET(mo_dir "${po_dir}")
    ENDIF()
    MANAGE_GETTEXT_LOCALES(localeListVar ${_gettext_locale_opts})
    FOREACH(_l ${localeListVar})
	SET(exec "msgfmt" "--locale=${_l}" ${options} -o ${mo_dir}/${_l}.gmo ${po_dir}/${_l}.po)
	EXECUTE_PROCESS(COMMAND ${exec}
	    RESULT_VARIABLE _res
	    OUTPUT_VARIABLE _out
	    ERROR_VARIABLE _err
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	IF(NOT _res EQUAL 0)
	    M_MSG(${M_FATAL} "Failed ${exec}: ${_out} | ${_err}")
	ENDIF()
    ENDFOREACH(_l)
ENDMACRO(MO_MAKE)

MACRO(MO_MAKE_VARIABLE_CHECK)
    IF("${po_dir}" STREQUAL "")
	M_MSG(${M_FATAL} "Requires -D \"po_dir=<dir>\"")
    ENDIF()
    IF(NOT EXISTS ${po_dir})
	M_MSG(${M_FATAL} "Failed to find ${po_dir}")
    ENDIF()
    MO_MAKE()
ENDMACRO(MO_MAKE_VARIABLE_CHECK)

SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
#######################################
# Determine CMAKE_FEDORA_MODULE_DIR
#

## It is possible that current dir is in NO_PACK/FedPkg/<prj>
LIST(INSERT CMAKE_MODULE_PATH 0
    ${CMAKE_SOURCE_DIR}/Modules ${CMAKE_SOURCE_DIR}/cmake-fedora/Modules 
    ${CMAKE_SOURCE_DIR}/../../../Modules
    ${CMAKE_SOURCE_DIR}/../../../cmake-fedora/Modules
    ${CMAKE_SOURCE_DIR}
    )

IF(CMAKE_SCRIPT_MODE_FILE)
    GET_FILENAME_COMPONENT(CMAKE_FEDORA_SCRIPT_DIR ${CMAKE_SCRIPT_MODE_FILE}
	PATH)
    LIST(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_FEDORA_SCRIPT_DIR}")
ENDIF()

IF(cmake_fedora_module_dir)
    LIST(INSERT CMAKE_MODULE_PATH 0 "${cmake_fedora_module_dir}")
ENDIF()

INCLUDE(ManageMessage RESULT_VARIABLE MANAGE_MODULE_PATH)
IF(NOT MANAGE_MODULE_PATH)
    MESSAGE(FATAL_ERROR "ManageMessage.cmake cannot be found in ${CMAKE_MODULE_PATH}")
ENDIF()
GET_FILENAME_COMPONENT(CMAKE_FEDORA_MODULE_DIR 
    "${MANAGE_MODULE_PATH}" PATH
    )

INCLUDE(ManageEnvironmentCommon)
INCLUDE(ManageString)
INCLUDE(ManageVariable)
INCLUDE(ManageFile)
INCLUDE(ManageTranslation)

IF(NOT DEFINED cmd)
    MANAGE_GETTEXT_SCRIPT_PRINT_USAGE()
ELSE()
    IF("${cmd}" STREQUAL "pot_make")
	#POT_MAKE_VARIABLE_CHECK()
    ELSEIF("${cmd}" STREQUAL "po_make")
	PO_MAKE_VARIABLE_CHECK()
    ELSEIF("${cmd}" STREQUAL "mo_make")
	MO_MAKE_VARIABLE_CHECK()
    ELSE()
	MANAGE_GETTEXT_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
    ENDIF()
ENDIF()



