# - Software Translation support
# This module supports software translation by:
#   1) Creates gettext related targets.
#   2) Communicate to Zanata servers.
#
# Defines following targets:
#   + translations: Make the translation files.
#     This target itself does nothing but provide a target for others to
#     depend on.
#     If macro MANAGE_GETTEXT is used, then it depends on the target gmo_files.
#
# Defines following variables:
#   + XGETTEXT_OPTIONS_C: Usual xgettext options for C programs.
# Defines or read from following variables:
#   + MANAGE_TRANSLATION_MSGFMT_OPTIONS: msgfmt options
#     Default: --check --check-compatibility --strict
#   + MANAGE_TRANSLATION_MSGMERGE_OPTIONS: msgmerge options
#     Default: --update --indent --backup=none
#   + MANAGE_TRANSLATION_XGETEXT_OPTIONS: xgettext options
#     Default: ${XGETTEXT_OPTIONS_C}
#
# Defines following macros:
#   MANAGE_GETTEXT [ALL] SRCS src1 [src2 [...]]
#	[LOCALES locale1 [locale2 [...]]]
#	[POTFILE potfile]
#       [MSGFMT_OPTIONS msgfmtOpt]]
#       [MSGMERGE_OPTIONS msgmergeOpt]]
#	[XGETTEXT_OPTIONS xgettextOpt]]
#	)
#   - Provide Gettext support like pot file generation and
#     gmo file generation.
#     You can specify supported locales with LOCALES ...
#     or omit the locales to use all the po files.
#
#     Arguments:
#     + ALL: (Optional) make target "all" depends on gettext targets.
#     + SRCS src1 [src2 [...]]: File list of source code that contains msgid.
#     + LOCALES locale1 [local2 [...]]:(optional) Locale list to be generated.
#       Currently, only the format: lang_Region (such as fr_FR) is supported.
#     + POTFILE potFile: (optional) pot file to be referred.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + MSGFMT_OPTIONS msgfmtOpt: (optional) msgfmt options.
#       Default: ${MANAGE_TRANSLATION_MSGFMT_OPTIONS}
#     + MSGMERGE_OPTIONS msgmergeOpt: (optional) msgmerge options.
#       Default: ${MANAGE_TRANSLATION_MSGMERGE_OPTIONS}, which is
##     + XGETTEXT_OPTIONS xgettextOpt: (optional) xgettext_options.
#       Default: ${XGETTEXT_OPTIONS_C}
#     Defines following variables:
#     + MSGMERGE_CMD: the full path to the msgmerge tool.
#     + MSGFMT_CMD: the full path to the msgfmt tool.
#     + XGETTEXT_CMD: the full path to the xgettext.
#     Targets:
#     + pot_file: Generate the pot_file.
#     + gmo_files: Converts input po files into the binary output mo files.
#
#   MANAGE_ZANATA(serverUrl [YES])
#   - Use Zanata (was flies) as translation service.
#     Arguments:
#     + serverUrl: The URL of Zanata server
#     + YES: Assume yes for all questions.
#     Reads following variables:
#     + ZANATA_XML_FILE: Path to zanata.xml
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_INI_FILE: Path to zanata.ini
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_PUSH_OPTIONS: Options for zanata push
#     + ZANATA_PULL_OPTIONS: Options for zanata pull
#     Targets:
#     + zanata_project_create: Create project with PROJECT_NAME in zanata
#       server.
#     + zanata_version_create: Create version PRJ_VER in zanata server.
#     + zanata_push: Push source messages to zanata server
#     + zanata_push_trans: Push source messages and translations to zanata server.
#     + zanata_pull: Pull translations from zanata server.
#


IF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)
    SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
    SET(XGETTEXT_OPTIONS_C
	--language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
	
	)

    SET(MANAGE_TRANSLATION_MSGFMT_OPTIONS 
	"--check" CACHE STRING "msgfmt options"
	)
    SET(MANAGE_TRANSLATION_MSGMERGE_OPTIONS 
	"--indent" "--update" "--backup=none" CACHE STRING "msgmerge options"
	)
    SET(MANAGE_TRANSLATION_XGETTEXT_OPTIONS 
	${XGETTEXT_OPTIONS_C}
	CACHE STRING "xgettext options"
	)
    SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")

    INCLUDE(ManageArchive)
    INCLUDE(ManageMessage)
    INCLUDE(ManageFile)
    INCLUDE(ManageDependency)
    IF(NOT TARGET translations)
	ADD_CUSTOM_TARGET(translations
	    COMMENT "Making translations"
	    )
    ENDIF(NOT TARGET translations)


    #========================================
    # GETTEXT support

    MACRO(MANAGE_GETTEXT_INIT)
	FOREACH(_name "xgettext" "msgmerge" "msgfmt")
	    STRING(TOUPPER "${_name}" _cmd)
	    FIND_PROGRAM_ERROR_HANDLING(${_cmd}_CMD
		ERROR_MSG " gettext support is disabled."
		ERROR_VAR _gettext_dependency_missing
		VERBOSE_LEVEL ${M_OFF}
		"${_name}"
		)
	ENDFOREACH(_name "xgettext" "msgmerge" "msgfmt")
    ENDMACRO(MANAGE_GETTEXT_INIT)

    FUNCTION(MANAGE_GETTEXT)
	SET(_gettext_dependency_missing 0)
	MANAGE_DEPENDENCY(BUILD_REQUIRES GETTEXT REQUIRED DEVEL)
	MANAGE_GETTEXT_INIT()
	IF(NOT _gettext_dependency_missing)
	    SET(_validOptions 
		"ALL" "SRCS" "LOCALES" "POTFILE"
		"MSGFMT_OPTIONS"
		"MSGMERGE_OPTIONS" "XGETTEXT_OPTIONS"
		)
	    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
	    IF(DEFINED _opt_ALL)
		SET(_all "ALL")
	    ENDIF(DEFINED _opt_ALL)

	    # Default values
	    IF(_opt_POTFILE)
		GET_FILENAME_COMPONENT(_opt_POTFILE "${_opt_POTFILE}" ABSOLUTE)
	    ELSE(_opt_POTFILE)
		SET(_opt_POTFILE 
		    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot")
	    ENDIF(_opt_POTFILE)
	    GET_FILENAME_COMPONENT(_opt_POTFILE_NAME "${_opt_POTFILE}" NAME_WE)
	    SOURCE_ARCHIVE_CONTENTS_ADD("${_opt_POTFILE}")

	    IF(NOT _opt_LOCALES)
		FILE(GLOB _poFiles "*.po")
		FOREACH(_poFile ${_poFiles})
		    GET_FILENAME_COMPONENT(_locale "${_poFile}" NAME_WE)
		    LIST(APPEND _opt_LOCALES "${_locale}")
		ENDFOREACH(_poFile ${_poFiles})
	    ENDIF(NOT _opt_LOCALES)

	    FOREACH(_optName "MSGFMT" "MSGMERGE" "XGETTEXT")
		IF(NOT _opt_${_optName}_OPTIONS)
		    SET(_opt_${_optName}_OPTIONS 
			"${MANAGE_TRANSLATION_${_optName}_OPTIONS}"
			)
		ENDIF(NOT _opt_${_optName}_OPTIONS)
	    ENDFOREACH(_optName "MSGFMT" "MSGMERGE" "XGETTEXT")

	    SET(_srcList "")
	    SET(_srcList_abs "")
	    FOREACH(_sF ${_opt_SRCS})
		FILE(RELATIVE_PATH _relFile 
		    "${CMAKE_CURRENT_BINARY_DIR}" "${_sF}")
		LIST(APPEND _srcList ${_relFile})
		GET_FILENAME_COMPONENT(_absPoFile ${_sF} ABSOLUTE)
		LIST(APPEND _srcList_abs ${_absPoFile})
	    ENDFOREACH(_sF ${_opt_SRCS})

	    ### Generating pot files
	    ADD_CUSTOM_TARGET_COMMAND(pot_file
		NO_FORCE OUTPUT ${_opt_POTFILE} ${_all}
		COMMAND ${XGETTEXT_CMD} ${_opt_XGETTEXT_OPTIONS} 
		    -o ${_opt_POTFILE}
		    --package-name=${PROJECT_NAME} 
		    --package-version=${PRJ_VER} ${_srcList}
		DEPENDS ${_srcList_abs}
		COMMENT "Extract translatable messages to ${_potFile}"
		)

	    ### Generating gmo files
	    SET(_gmoList "")
	    SET(_poList "")
	    FOREACH(_locale ${_opt_LOCALES})
		SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_locale}.gmo)
		SET(_poFile ${CMAKE_CURRENT_SOURCE_DIR}/${_locale}.po)
		SOURCE_ARCHIVE_CONTENTS_ADD("${_poFile}")
		ADD_CUSTOM_COMMAND(OUTPUT ${_poFile}
		    COMMAND ${MSGMERGE_CMD} 
		    ${_opt_MSGMERGE_OPTIONS} ${_poFile} ${_opt_POTFILE}
		    DEPENDS ${_opt_POTFILE}
		    COMMENT "Running ${MSGMERGE_CMD}"
		    )

		ADD_CUSTOM_COMMAND(OUTPUT ${_gmoFile}
		    COMMAND ${MSGFMT_CMD} 
		    ${_opt_MSGFMT_OPTIONS} -o ${_gmoFile} ${_poFile}
		    DEPENDS ${_poFile}
		    COMMENT "Running ${MSGFMT_CMD}"
		    )

		LIST(APPEND _gmoList "${_gmoFile}")
		## No need to use MANAGE_FILE_INSTALL
		## As this will handle by rpmbuild
		INSTALL(FILES ${_gmoFile} DESTINATION 
		    ${DATA_DIR}/locale/${_locale}/LC_MESSAGES 
		    RENAME ${_opt_POTFILE_NAME}.mo
		    )
	    ENDFOREACH(_locale ${_opt_LOCALES})
	    SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_potFile}" )

	    ADD_CUSTOM_TARGET(gmo_files ${_all}
		DEPENDS ${_gmoList}
		COMMENT "Generate gmo files for translation"
		)

	    ADD_DEPENDENCIES(translations gmo_files)
	ENDIF(NOT _gettext_dependency_missing)
    ENDFUNCTION(MANAGE_GETTEXT)


    #========================================
    # ZANATA support
    MACRO(MANAGE_ZANATA serverUrl)
	SET(ZANATA_SERVER "${serverUrl}")
	FIND_PROGRAM(ZANATA_CMD zanata)
	SET(_manage_zanata_dependencies_missing 0)
	IF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata (python client) not found! zanata support disabled.")
	ENDIF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")

	SET(ZANATA_XML_FILE "${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml" CACHE FILEPATH "zanata.xml")
	IF(NOT EXISTS "${ZANATA_XML_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.xml is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_XML_FILE}")

	SET(ZANATA_INI_FILE "$ENV{HOME}/.config/zanata.ini" CACHE FILEPATH "zanata.ni")
	IF(NOT EXISTS "${ZANATA_INI_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.ini is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_INI_FILE}")

	IF(NOT _manage_zanata_dependencies_missing)
	    SET(_zanata_args --url "${ZANATA_SERVER}"
		--project-config "${ZANATA_XML_FILE}" --user-config "${ZANATA_INI_FILE}")

	    # Parsing arguments
	    SET(_yes "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "YES")
		    SET(_yes "yes" "|")
		ENDIF(_arg STREQUAL "YES")
	    ENDFOREACH(_arg ${ARGN})

	    ADD_CUSTOM_TARGET(zanata_project_create
		COMMAND ${ZANATA_CMD} project create ${PROJECT_NAME} ${_zanata_args}
		--project-name "${PROJECT_NAME}" --project-desc "${PRJ_SUMMARY}"
		COMMENT "Creating project ${PROJECT_NAME} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    ADD_CUSTOM_TARGET(zanata_version_create
		COMMAND ${ZANATA_CMD} version create
		${PRJ_VER} ${_zanata_args} --project-id "${PROJECT_NAME}"
		COMMENT "Creating version ${PRJ_VER} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    SET(_po_files_depend "")
	    IF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
		SET(_po_files_depend "DEPENDS" ${MANAGE_TRANSLATION_GETTEXT_PO_FILES})
	    ENDIF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
	    # Zanata push
	    ADD_CUSTOM_TARGET(zanata_push
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_push pot_file)

	    # Zanata push with translation
	    ADD_CUSTOM_TARGET(zanata_push_trans
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} --push-type both ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages and translations to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	    ADD_DEPENDENCIES(zanata_push_trans pot_file)

	    # Zanata pull
	    ADD_CUSTOM_TARGET(zanata_pull
		COMMAND ${_yes}
		${ZANATA_CMD} pull ${_zanata_args} ${ZANATA_PULL_OPTIONS}
		COMMENT "Pull translations fro zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	ENDIF(NOT _manage_zanata_dependencies_missing)
    ENDMACRO(MANAGE_ZANATA serverUrl)

ENDIF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)

