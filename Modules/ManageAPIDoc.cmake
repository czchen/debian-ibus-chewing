# - Manage generated API documents
# This module provide functions for API document generation.
#
# Included Modules:
#   - ManageDependency
#   - ManageMessage
# 
# Defines following functions:
#   MANAGE_APIDOC_DOXYGEN([DOXYGEN <Doxyfile>]
#     [OUTPUT_DIRECTORY <dir>] ...
#     )
#     - Provide Doxygen processing and targets.
#       DOXYGEN options can also be provided here.
#       For example:
#         MANAGE_APIDOC_DOXYGEN(DOXYGEN Doxyfile
#           OUTPUT_DIRECTORY doc
#           CREATE_SUBDIR no
#           )
#       Will write the configure file to Doxyfile, generate documents
#       will be put in doc/, and CREATE_SUBDIR is set as "no".
#
#       * Parameters:
#         + DOXYGEN Doxyfile: Doxygen file.
#           Default: ${CMAKE_BINARY_DIR}/Doxygn
#         + OUTPUT_DIRECTORYCREATE_SUBDIR dir: Directory for generated
#           documents.
#         + ... : Other Doxygen options.
#         + docSrcdir: Document source directory to be copied from.
#       * Targets:
#         + doxygen: Make doxygen documents.
#         + doxygen_update_doxyfile: Update Doxyfile.
#           Doxyfile configuration options such as PROJECT_NUMBER will be
#           updated according to project information.
#       * Reads following variable:
#         + PRJ_DOC_DIR: Directory for installed documents.
#           Default: /usr/share/doc/${PROJECT_NAME}
#
IF(DEFINED _MANAGE_APIDOC_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_APIDOC_CMAKE_)
SET(_MANAGE_APIDOC_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageDependency)

FUNCTION(MANAGE_APIDOC_DOXYGEN_ADD_OPTION doxyfile listVar key value)
    LIST(APPEND ${listVar}
	"COMMAND" "sed" "-i" "-e"
	's|^${key}\\s*=.*|${key}="${value}"|' "${doxyfile}"
	)
    SET(${listVar} "${${listVar}}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_APIDOC_DOXYGEN_ADD_OPTION)

FUNCTION(MANAGE_APIDOC_DOXYGEN)
    LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES "/Doxyfile$")
    SET(_manage_apidoc_doxygen_dependency_missing 0)
    MANAGE_DEPENDENCY(BUILD_REQUIRES DOXYGEN PROGRAM_NAMES "doxygen")
    IF(NOT DEFINED DOXYGEN_FOUND)
	RETURN()
    ENDIF(NOT DEFINED DOXYGEN_FOUND)
    IF("${PRJ_DOC_DIR}" STREQUAL "")
	SET(PRJ_DOC_DIR "/usr/share/doc/${PROJECT_NAME}"
	    CACHE PATH "Project document dir"
	    )
    ENDIF("${PRJ_DOC_DIR}" STREQUAL "")
    M_MSG(${M_INFO2} "PRJ_DOC_DIR=${PRJ_DOC_DIR}")

    SET(_stage "key")
    SET(_key "")
    SET(_doxygenOptList "")
    FOREACH(_arg ${ARGN})
	IF(_stage STREQUAL "key")
	    SET(_key "${_arg}")
	    SET(_stage "value")
	ELSE(_stage STREQUAL "key")
	    SET(_opt_${_key} "${_arg}")
	    IF(NOT "${_key}" STREQUAL "DOXYGEN")
		MANAGE_APIDOC_DOXYGEN_ADD_OPTION("${_opt_DOXYGEN}"
		    _doxygenOptList "${_key}" "${_arg}"
		    )
	    ENDIF(NOT "${_key}" STREQUAL "DOXYGEN")
	    SET(_stage "key")
	ENDIF(_stage STREQUAL "key")
    ENDFOREACH(_arg)

    IF("${_opt_DOXYGEN}" STREQUAL "")
	SET(_opt_DOXYGEN "${CMAKE_BINARY_DIR}/Doxyfile")
    ENDIF("${_opt_DOXYGEN}" STREQUAL "")

    IF("${_opt_OUTPUT_DIRECTORY}" STREQUAL "")
	SET(_opt_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/doc")
    ENDIF("${_opt_OUTPUT_DIRECTORY}" STREQUAL "")

    ADD_CUSTOM_TARGET(doxygen
	COMMAND "${DOXYGEN_EXECUTABLE}" "${opt_DOXYGEN}"
	DEPENDS ${_opt_DOXYGEN}
	COMMENT "doxygen: ${opt_DOXYGEN}"
	)

    MANAGE_APIDOC_DOXYGEN_ADD_OPTION("${_opt_DOXYGEN}"
	_doxygenOptList "PROJECT_NAME" "${PROJECT_NAME}"
	)
    MANAGE_APIDOC_DOXYGEN_ADD_OPTION("${_opt_DOXYGEN}"
	_doxygenOptList "PROJECT_NUMBER" "${PRJ_VER}"
	)
    MANAGE_APIDOC_DOXYGEN_ADD_OPTION("${_opt_DOXYGEN}"
	_doxygenOptList "PROJECT_BRIEF" "${PRJ_SUMMARY}"
	)

    ADD_CUSTOM_TARGET_COMMAND(doxygen_update_doxyfile
	OUTPUT "${_opt_DOXYGEN}"
	COMMAND "${DOXYGEN_EXECUTABLE}" -g "${_opt_DOXYGEN}"
	${_doxygenOptList}
	COMMENT "doxygen_update_doxyfile: ${_opt_DOXYGEN}"
	)

    INSTALL(DIRECTORY ${_opt_OUTPUT_DIRECTORY}
	DESTINATION "${PRJ_DOC_DIR}"
	)
ENDFUNCTION(MANAGE_APIDOC_DOXYGEN doxygen_template)

