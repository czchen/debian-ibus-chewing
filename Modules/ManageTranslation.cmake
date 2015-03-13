# - Manage Translation
# This module supports software translation by:
#   Creates gettext related targets.
#   Communicate to Zanata servers.
#
# By calling MANAGE_GETTEXT(), following variables are available in cache:
#   - MANAGE_TRANSLATION_LOCALES: Locales that would be processed.
#
# Included Modules:
#   - ManageArchive
#   - ManageDependency
#   - ManageFile
#   - ManageMessage
#   - ManageString
#   - ManageVariable
#
# Defines following targets:
#   + translations: Virtual target that make the translation files.
#     Once MANAGE_GETTEXT is used, this target invokes targets that
#     build translation.
#
# Defines following variables:
#   + XGETTEXT_OPTIONS_C: Default xgettext options for C programs.
# Defines or read from following variables:
#   + MANAGE_TRANSLATION_MSGFMT_OPTIONS: msgfmt options
#     Default: --check --check-compatibility --strict
#   + MANAGE_TRANSLATION_MSGMERGE_OPTIONS: msgmerge options
#     Default: --update --indent --backup=none
#   + MANAGE_TRANSLATION_XGETEXT_OPTIONS: xgettext options
#     Default: ${XGETTEXT_OPTIONS_C}
#
# Defines following functions:
#   MANAGE_POT_FILE(<potFile> 
#       [SRCS <src> ...]
#       [PO_DIR <dir>]
#       [MO_DIR <dir>]
#       [NO_MO]
#	[LOCALES <locale> ... | SYSTEM_LOCALES]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [MSGMERGE_OPTIONS <msgmergeOpt>]
#       [MSGFMT_OPTIONS <msgfmtOpt>]
#       [CLEAN]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Add a new pot file and source files that create the pot file.
#       It is mandatory if for multiple pot files.
#       By default, cmake-fedora will set the directory property
#       PROPERTIES CLEAN_NO_CUSTOM as "1" to prevent po files get cleaned
#       by "make clean". For this behavior to be effective, invoke this function
#       in the directory that contains generated PO file.
#       * Parameters:
#         + potFile: .pot file with path.
#         + SRCS src ... : Source files for xgettext to work on.
#         + PO_DIR dir: Directory of .po files.
#             This option is mandatory if .pot and associated .po files
#             are not in the same directory.
#           Default: Same directory of <potFile>.
#         + MO_DIR dir: Directory of .gmo files.
#           Default: Same with PO_DIR
#         + NO_MO: Skip the mo generation.
#             This is for documents that do not require MO.
#         + LOCALES locale ... : (Optional) Locale list to be generated.
#         + SYSTEM_LOCALES: (Optional) System locales from /usr/share/locale.
#         + XGETTEXT_OPTIONS opt ... : xgettext options.
#         + MSGMERGE_OPTIONS msgmergeOpt: (Optional) msgmerge options.
#           Default: ${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}, which is
#         + MSGFMT_OPTIONS msgfmtOpt: (Optional) msgfmt options.
#           Default: ${MANAGE_TRANSLATION_MSGFMT_OPTIONS}
#         + CLEAN: Clean the POT, PO, MO files when doing make clean
#             By default, cmake-fedora will set the directory property
#             PROPERTIES CLEAN_NO_CUSTOM as "1" to prevent po files get cleaned.
#             Specify "CLEAN" to override this behavior.
#         + COMMAND cmd ... : Non-xgettext command that create pot file.
#         + DEPENDS file ... : Files that pot file depends on.
#             SRCS files are already depended on, so no need to list here.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILES: List of pot files.
#         + MANAGE_TRANSLATION_GETTEXT_PO_FILES: List of all po files.
#         + MANAGE_TRANSLATION_GETTEXT_MO_FILES: List of all mo filess.
#         + MANAGE_TRANSLATION_LOCALES: List of locales.
#
#   MANAGE_GETTEXT([ALL] 
#       [POT_FILE <potFile>]
#       [SRCS <src> ...]
#       [PO_DIR <dir>]
#       [MO_DIR <dir>]
#       [NO_MO]
#	[LOCALES <locale> ... | SYSTEM_LOCALES]
#	[XGETTEXT_OPTIONS <opt> ...]
#       [MSGMERGE_OPTIONS <msgmergeOpt>]
#       [MSGFMT_OPTIONS <msgfmtOpt>]
#       [CLEAN]
#       [COMMAND <cmd> ...]
#       [DEPENDS <file> ...]
#     )
#     - Manage Gettext support.
#       If no POT files were added, it invokes MANAGE_POT_FILE and manage .pot, .po and .gmo files.
#       This command creates targets for making the translation files.
#       So naturally, this command should be invoke after the last MANAGE_POT_FILE command.
#       The parameters are similar to the ones at MANAGE_POT_FILE, except:
#       * Parameters:
#         + ALL: (Optional) make target "all" depends on gettext targets.
#         + POT_FILE potFile: (Optional) pot files with path.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#         Refer MANAGE_POT_FILE for rest of the parameters.
#       * Targets:
#         + pot_files: Generate pot files.
#         + update_po: Update po files according to pot files.
#         + gmo_files: Converts po files to mo files.
#         + translation: Complete all translation tasks.
#       * Variables to cache:
#         + MANAGE_TRANSLATION_GETTEXT_POT_FILES: List of pot files.
#         + MANAGE_TRANSLATION_GETTEXT_PO_FILES: List of all po files.
#         + MANAGE_TRANSLATION_GETTEXT_MO_FILES: Lis of all mo filess.
#         + MANAGE_TRANSLATION_LOCALES: List of locales. 
#       * Variables to cache:
#         + MSGINIT_EXECUTABLE: the full path to the msginit tool.
#         + MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#         + MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#         + XGETTEXT_EXECUTABLE: the full path to the xgettext.
#         + MANAGE_LOCALES: Locales to be processed.
#

IF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_TRANSLATION_CMAKE_)
SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageString)
INCLUDE(ManageVariable)

#######################################
# GETTEXT support
#

SET(XGETTEXT_OPTIONS_COMMON --from-code=UTF-8 --indent
    --sort-by-file
    )

SET(XGETTEXT_OPTIONS_C ${XGETTEXT_OPTIONS_COMMON} 
    --language=C     
    --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 
    --keyword=gettext --keyword=dgettext:2
    --keyword=dcgettext:2 --keyword=ngettext:1,2
    --keyword=dngettext:2,3 --keyword=dcngettext:2,3
    --keyword=gettext_noop --keyword=pgettext:1c,2
    --keyword=dpgettext:2c,3 --keyword=dcpgettext:2c,3
    --keyword=npgettext:1c,2,3 --keyword=dnpgettext:2c,3,4 
    --keyword=dcnpgettext:2c,3,4.
    )

SET(MANAGE_TRANSLATION_MSGFMT_OPTIONS 
    "--check" CACHE STRING "msgfmt options"
    )
SET(MANAGE_TRANSLATION_MSGMERGE_OPTIONS 
    "--indent" "--update" "--sort-by-file" "--backup=none" 
    CACHE STRING "msgmerge options"
    )
SET(MANAGE_TRANSLATION_XGETTEXT_OPTIONS 
    ${XGETTEXT_OPTIONS_C}
    CACHE STRING "xgettext options"
    )

FUNCTION(MANAGE_TRANSLATION_LOCALES_SET value)
    SET(MANAGE_TRANSLATION_LOCALES "${value}" CACHE INTERNAL "Translation Locales")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_POT_FILES_SET value)
    SET(MANAGE_TRANSLATION_GETTEXT_POT_FILES "${value}" CACHE INTERNAL "POT files")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_POT_FILES_ADD)
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_POT_FILES ${ARGN})
    MANAGE_TRANSLATION_GETTEXT_POT_FILES_SET("${MANAGE_TRANSLATION_GETTEXT_POT_FILES}")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_PO_FILES_SET value)
    SET(MANAGE_TRANSLATION_GETTEXT_PO_FILES "${value}" CACHE INTERNAL "PO files")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_PO_FILES_ADD)
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_PO_FILES ${ARGN})
    MANAGE_TRANSLATION_GETTEXT_PO_FILES_SET("${MANAGE_TRANSLATION_GETTEXT_PO_FILES}")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_MO_FILES_SET value)
    SET(MANAGE_TRANSLATION_GETTEXT_MO_FILES "${value}" CACHE INTERNAL "MO files")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_GETTEXT_MO_FILES_ADD)
    LIST(APPEND MANAGE_TRANSLATION_GETTEXT_MO_FILES ${ARGN})
    MANAGE_TRANSLATION_GETTEXT_MO_FILES_SET("${MANAGE_TRANSLATION_GETTEXT_MO_FILES}")
ENDFUNCTION()

FUNCTION(MANAGE_TRANSLATION_LOCALES_SET value)
    SET(MANAGE_TRANSLATION_LOCALES "${value}" CACHE INTERNAL "Translation Locales")
ENDFUNCTION()

FUNCTION(MANAGE_GETTEXT_INIT)
    IF(DEFINED MANAGE_GETTEXT_SUPPORT)
	RETURN()
    ENDIF()
    INCLUDE(ManageArchive)
    INCLUDE(ManageDependency)
    MANAGE_DEPENDENCY(BUILD_REQUIRES GETTEXT REQUIRED)
    MANAGE_DEPENDENCY(BUILD_REQUIRES FINDUTILS REQUIRED)
    MANAGE_DEPENDENCY(REQUIRES GETTEXT REQUIRED)

    FOREACH(_name "xgettext" "msgmerge" "msgfmt" "msginit")
	STRING(TOUPPER "${_name}" _cmd)
	FIND_PROGRAM_ERROR_HANDLING(${_cmd}_EXECUTABLE
	    ERROR_MSG " gettext support is disabled."
	    ERROR_VAR _gettext_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    "${_name}"
	    )
	M_MSG(${M_INFO1} "${_cmd}_EXECUTABLE=${${_cmd}_EXECUTABLE}")
    ENDFOREACH(_name "xgettext" "msgmerge" "msgfmt")

    IF(gettext_dependency_missing)
	SET(MANAGE_GETTEXT_SUPPORT "0" CACHE INTERNAL "Gettext support")
    ELSE()
	SET(MANAGE_GETTEXT_SUPPORT "1" CACHE INTERNAL "Gettext support")
	MANAGE_TRANSLATION_GETTEXT_POT_FILES_SET("")
	MANAGE_TRANSLATION_GETTEXT_PO_FILES_SET("")
	MANAGE_TRANSLATION_GETTEXT_MO_FILES_SET("")
	MANAGE_TRANSLATION_LOCALES_SET("")
    ENDIF()
ENDFUNCTION(MANAGE_GETTEXT_INIT)

SET(MANAGE_POT_FILE_VALID_OPTIONS "SRCS" "PO_DIR" "MO_DIR" "NO_MO" "LOCALES" "SYSTEM_LOCALES" 
    "XGETTEXT_OPTIONS" "MSGMERGE_OPTIONS" "MSGFMT_OPTIONS" "CLEAN" "COMMAND" "DEPENDS"
    )
## Internal
FUNCTION(MANAGE_POT_FILE_SET_VARS cmdListVar msgmergeOptsVar msgfmtOptsVar poDirVar moDirVar allCleanVar srcsVar dependsVar potFile)
    VARIABLE_PARSE_ARGN(_o MANAGE_POT_FILE_VALID_OPTIONS ${ARGN})
    SET(cmdList "")
    IF("${_o_COMMAND}" STREQUAL "")
	LIST(APPEND cmdList ${XGETTEXT_EXECUTABLE})
	IF(NOT _o_XGETTEXT_OPTIONS)
	    SET(_o_XGETTEXT_OPTIONS 
		"${MANAGE_TRANSLATION_XGETTEXT_OPTIONS}"
		)
	ENDIF()
	LIST(APPEND cmdList ${_o_XGETTEXT_OPTIONS})
	IF("${_o_SRCS}" STREQUAL "")
	    M_MSG(${M_WARN} 
		"MANAGE_POT_FILE: xgettext: No SRCS for ${potFile}"
		)
	ENDIF()
	LIST(APPEND cmdList -o ${potFile}
	    "--package-name=${PROJECT_NAME}"
	    "--package-version=${PRJ_VER}"
	    "--msgid-bugs-address=${MAINTAINER}"
	    ${_o_SRCS}
	    )
    ELSE()
	SET(cmdList "${_o_COMMAND}")
    ENDIF()
    SET(${cmdListVar} "${cmdList}" PARENT_SCOPE)
    SET(${srcsVar} "${_o_SRCS}" PARENT_SCOPE)
    SET(${dependsVar} "${_o_DEPENDS}" PARENT_SCOPE)

    GET_FILENAME_COMPONENT(_potDir "${potFile}" PATH)
    IF("${_o_PO_DIR}" STREQUAL "")
	SET(_o_PO_DIR "${_potDir}")
    ENDIF()
    SET(${poDirVar} "${_o_PO_DIR}" PARENT_SCOPE)

    IF(MANAGE_TRANSLATION_LOCALES STREQUAL "")
	MANAGE_GETTEXT_LOCALES(_locales "${_o_PO_DIR}" ${ARGN})
    ENDIF()

    IF("${_o_MSGMERGE_OPTIONS}" STREQUAL "")
	SET(_o_MSGMERGE_OPTIONS "${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}")
    ENDIF()
    SET(${msgmergeOptsVar} "${_o_MSGMERGE_OPTIONS}" PARENT_SCOPE)

    IF("${_o_MSGFMT_OPTIONS}" STREQUAL "")
	SET(_o_MSGFMT_OPTIONS "${MANAGE_TRANSLATION_MSGFMT_OPTIONS}")
    ENDIF()
    SET(${msgfmtOptsVar} "${_o_MSGFMT_OPTIONS}" PARENT_SCOPE)

    IF(DEFINED _o_NO_MO)
	SET(${moDirVar} "" PARENT_SCOPE)
    ELSEIF("${_o_MO_DIR}" STREQUAL "")
	SET(${moDirVar} "${_o_PO_DIR}" PARENT_SCOPE)
    ELSE()
	SET(${moDirVar} "${_o_MO_DIR}" PARENT_SCOPE)
    ENDIF()

    IF(NOT DEFINED _o_CLEAN)
	SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
	SET(${allCleanVar} 0 PARENT_SCOPE)
    ELSE()
	SET(${allCleanVar} 1 PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(MANAGE_POT_FILE_SET_VARS)

FUNCTION(MANAGE_POT_FILE_OBTAIN_TARGET_NAME var potFile)
    FILE(RELATIVE_PATH potFileRel ${CMAKE_SOURCE_DIR} ${potFile})
    STRING(REPLACE "/" "_" target "${potFileRel}")
    STRING_PREPEND(target "pot_file_")
    SET(${var} "${target}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_POT_FILE_OBTAIN_TARGET_NAME)

FUNCTION(MANAGE_POT_FILE potFile)
    IF(NOT DEFINED MANAGE_GETTEXT_SUPPORT)
	MANAGE_GETTEXT_INIT()
    ENDIF()
    IF(MANAGE_GETTEXT_SUPPORT EQUAL 0)
	RETURN()
    ENDIF()

    MANAGE_POT_FILE_SET_VARS(cmdList msgmergeOpts msgfmtOpts poDir moDir allClean srcs depends 
	"${potFile}" ${ARGN}
	)

    MANAGE_POT_FILE_OBTAIN_TARGET_NAME(targetName "${potFile}")

    ADD_CUSTOM_TARGET_COMMAND(${targetName}
	OUTPUT ${potFile}
	NO_FORCE
	COMMAND ${cmdList}
	DEPENDS ${srcs} ${depends}
	COMMENT "${potFile}: ${cmdList}"
	VERBATIM
	)
    MANAGE_TRANSLATION_GETTEXT_POT_FILES_ADD("${potFile}")
    SOURCE_ARCHIVE_CONTENTS_ADD("${potFile}" ${srcs} ${depends})
    SET(cleanList "${potFile}")

    ## Not only POT, but also PO and MO as well
    FOREACH(_l ${MANAGE_TRANSLATION_LOCALES})
	## PO file
	SET(_poFile "${poDir}/${_l}.po")
	ADD_CUSTOM_COMMAND(OUTPUT ${_poFile}
	    COMMAND ${CMAKE_BUILD_TOOL} ${targetName}_no_force
	    COMMAND ${CMAKE_COMMAND} 
	    -D cmd=po_make
	    -D "pot=${potFile}"
	    -D "locales=${_l}"
	    -D "options=${msgmergeOpts}"
	    -D "po_dir=${poDir}"
	    -P ${CMAKE_FEDORA_MODULE_DIR}/ManageGettextScript.cmake
	    COMMENT "Create ${_poFile} from ${potFile}"
	    VERBATIM
	    )
	MANAGE_TRANSLATION_GETTEXT_PO_FILES_ADD("${_poFile}")
	SOURCE_ARCHIVE_CONTENTS_ADD("${_poFile}")

	IF(NOT "${moDir}" STREQUAL "")
	    ## MO file
	    SET(_moDir  "${DATA_DIR}/locale/${_l}/LC_MESSAGES")
	    SET(_gmoFile "${moDir}/${_l}.gmo")
	    ADD_CUSTOM_COMMAND(OUTPUT ${_gmoFile}
		COMMAND ${MSGFMT_EXECUTABLE} 
		-o "${_gmoFile}"
		"${_poFile}"
		DEPENDS ${_poFile}
		)
	    MANAGE_TRANSLATION_GETTEXT_MO_FILES_ADD("${_gmoFile}")
	    GET_FILENAME_COMPONENT(_potName "${potFile}" NAME_WE)
	    INSTALL(FILES ${_gmoFile} DESTINATION "${_moDir}"
		RENAME "${_potName}.mo"
		)
	    LIST(APPEND cleanList "${_gmoFile}")
	ENDIF()
    ENDFOREACH(_l)
    IF(NOT allClean)
	SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${cleanList}")
    ENDIF()
ENDFUNCTION(MANAGE_POT_FILE)

SET(MANAGE_GETTEXT_LOCALES_VALID_OPTIONS "LOCALES" "SYSTEM_LOCALES")
## Internal
FUNCTION(MANAGE_GETTEXT_LOCALES localeListVar poDir)
    VARIABLE_PARSE_ARGN(_o MANAGE_GETTEXT_LOCALES_VALID_OPTIONS ${ARGN})
    IF(NOT "${_o_LOCALES}" STREQUAL "")
	## Locale is defined
    ELSEIF(DEFINED _o_SYSTEM_LOCALES)
	EXECUTE_PROCESS(
	    COMMAND ls -1 /usr/share/locale/
	    COMMAND grep -e "^[a-z]*\\(_[A-Z]*\\)\\?\\(@.*\\)\\?$"
	    COMMAND sort -u 
	    COMMAND xargs 
	    COMMAND sed -e "s/ /;/g"
	    OUTPUT_VARIABLE _o_LOCALES
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
    ELSE()
	## LOCALES is not specified, detect now
	EXECUTE_PROCESS(
	    COMMAND find ${poDir} -name "*.po" -printf "%f\n"
	    COMMAND sed -e "s/.po//g"
	    COMMAND sort -u
	    COMMAND xargs
	    COMMAND sed -e "s/ /;/g"
	    OUTPUT_VARIABLE _o_LOCALES
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	LIST(APPEND _o_LOCALES ${_locales})
	IF("${_o_LOCALES}" STREQUAL "")
	    ## Failed to find any locale
	    M_MSG(${M_ERROR} "MANAGE_GETTEXT: Failed to detect locales. Please either specify LOCALES or SYSTEM_LOCALES.")
	ENDIF()
    ENDIF()
    MANAGE_TRANSLATION_LOCALES_SET("${_o_LOCALES}")
    SET(${localeListVar} "${_o_LOCALES}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_GETTEXT_LOCALES)

SET(MANAGE_GETTEXT_VALID_OPTIONS ${MANAGE_POT_FILE_VALID_OPTIONS} "ALL" "POT_FILE")
FUNCTION(MANAGE_GETTEXT)
    VARIABLE_PARSE_ARGN(_o MANAGE_GETTEXT_VALID_OPTIONS ${ARGN})
    IF(DEFINED _o_ALL)
	SET(_all "ALL")
    ELSE()
	SET(_all "")
    ENDIF(DEFINED _o_ALL)

    ## Do we explicit specify the pot?
    IF(NOT "${_o_POT_FILE}" STREQUAL "")
	## Yes, by all means, create it.
	VARIABLE_TO_ARGN(_addPotFileOptList _o MANAGE_POT_FILE_VALID_OPTIONS)
	MANAGE_POT_FILE("${_o_POT_FILE}" ${_addPotFileOptList})
    ENDIF()

    ## Do we need to create the pot file?
    IF("${MANAGE_TRANSLATION_GETTEXT_POT_FILES}" STREQUAL "")
	## Yes, use the default pot file, and create it
	SET(_o_POT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot")
	VARIABLE_TO_ARGN(_addPotFileOptList _o MANAGE_POT_FILE_VALID_OPTIONS)
	MANAGE_POT_FILE("${_o_POT_FILE}" ${_addPotFileOptList})
    ENDIF()

    ## Do we have list of pot files?
    IF("${MANAGE_TRANSLATION_GETTEXT_POT_FILES}" STREQUAL "")
	## No, something wrong.
	M_MSG(${M_ERROR} "MANAGE_GETTEXT: No .pot file is created")
    ENDIF()

    ## Target translation
    ADD_CUSTOM_TARGET(translations ${_all}
	COMMENT "translations: Making translations"
	)

    ## Target pot_files 
    ## PO depends on POT, so no need to put ALL here
    ADD_CUSTOM_TARGET(pot_files
	COMMENT "pot_files: ${MANAGE_TRANSLATION_GETTEXT_POT_FILES}"
	)

    ## Depends on pot_file targets instead of pot files themselves
    ## Otherwise it won't build when pot files is in sub CMakeLists.txt
    FOREACH(potFile ${MANAGE_TRANSLATION_GETTEXT_POT_FILES})
	MANAGE_POT_FILE_OBTAIN_TARGET_NAME(targetName "${potFile}")
	ADD_DEPENDENCIES(pot_files ${targetName}_no_force)
    ENDFOREACH(potFile)

    ## Target update_po 
    ADD_CUSTOM_TARGET(update_po
	DEPENDS ${MANAGE_TRANSLATION_GETTEXT_PO_FILES}
	COMMENT "update_po: ${MANAGE_TRANSLATION_GETTEXT_PO_FILES}"
	)
    ADD_DEPENDENCIES(update_po pot_files)

    ## Target gmo_files 
    IF(MANAGE_TRANSLATION_GETTEXT_MO_FILES)
	ADD_CUSTOM_TARGET(gmo_files
	    DEPENDS ${MANAGE_TRANSLATION_GETTEXT_MO_FILES}
	    COMMENT "update_po: ${MANAGE_TRANSLATION_GETTEXT_MO_FILES}"
	    )
    ENDIF()

    IF(TARGET gmo_files)
	ADD_DEPENDENCIES(gmo_files update_po)
	ADD_DEPENDENCIES(translations gmo_files)
    ELSE()
	ADD_DEPENDENCIES(translations update_po_no_force)
    ENDIF()

ENDFUNCTION(MANAGE_GETTEXT)

