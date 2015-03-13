# - Manage Zanata translation service support
# 
# Zanata is a web-based translation services, this module creates required targets. 
# for common Zanata operation, like put-project, put-version, 
#  push source and/or translation, pull translation and/or sources.
# 
#
# Included Modules:
#   - ManageFile
#   - ManageMessage
#   - ManageString
#
# Define following functions:
#   MANAGE_ZANATA([<serverUrl>] [YES]
#       [DEFAULT_PROJECT_TYPE <projectType>]
#       [PROJECT_TYPE <projectType>]
#       [PROJECT_SLUG <projectId>]
#       [VERSION <ver>]
#       [USERNAME <username>]
#       [CLIENT_COMMAND <command> ... ]
#       [LOCALES <locale1,locale2...> ]
#       [SRC_DIR <srcDir>]
#       [TRANS_DIR <transDir>]
#       [PUSH_OPTIONS <option> ... ]
#       [PULL_OPTIONS <option> ... ]
#       [DISABLE_SSL_CERT]
#       [GENERATE_ZANATA_XML]
#       [CLEAN_ZANATA_XML]
#       [PROJECT_CONFIG <zanata.xml>]
#       [USER_CONFIG <zanata.ini>]
#     )
#     - Use Zanata as translation service.
#         Zanata is a web-based translation manage system.
#         It uses ${PROJECT_NAME} as project Id (slug);
#         ${PRJ_SUMMARY} as project name;
#         ${PRJ_DESCRIPTION} as project description 
#         (truncate to 80 characters);
#         and ${PRJ_VER} as version, unless VERSION option is defined.
#
#         In order to use Zanata with command line, you will need either
#         Zanata client:
#         * zanata-cli: Zanata java command line client.
#         * mvn: Maven build system.
#
#         In addition, zanata.ini is also required as it contains API key.
#         API key should not be put in source tree, otherwise it might be
#         misused.
#
#         Feature disabled warning (M_OFF) will be shown if Zanata client
#         or zanata.ini is missing.
#       * Parameters:
#         + serverUrl: (Optional) The URL of Zanata server
#           Default: https://translate.zanata.org/zanata/
#         + YES: (Optional) Assume yes for all questions.
#         + DEFAULT_PROJECT_TYPE projectType::(Optional) Zanata project-type 
#             on creating project.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#           Default: gettext
#         + PROJECT_TYPE projectType::(Optional) Zanata project type 
#             for this version.
#	      Normally version inherit the project-type from project,
#             if this is not the case, use this parameter to specify
#             the project type.
#           Valid values: file, gettext, podir, properties,
#             utf8properties, xliff
#         + PROJECT_SLUG projectId: (Optional) This project ID in Zanata
#           It is required if it is different from PROJECT_NAME
#           Default: PROJECT_NAME
#         + VERSION version: (Optional) The version to push
#         + USERNAME username: (Optional) Zanata username
#         + CLIENT_COMMAND command ... : (Optional) Zanata client.
#             Specify zanata client.
#           Default: mvn -e
#         + LOCALES locales: Locales to sync with Zanata.
#             Specify the locales to sync with this Zanata server.
#             If not specified, it uses client side system locales.
#         + SRC_DIR dir: (Optional) Directory to put source documents 
#             (e.g. .pot).
#           Default: CMAKE_CURRENT_SOURCE_DIR
#         + TRANS-DIR dir: (Optional) Directory to put translated documents.
#           Default: CMAKE_CURRENT_BINARY_DIR
#         + PUSH_OPTIONS opt ... : (Optional) Zanata push options.
#             Options should be specified like "includes=**/*.properties"
#             No need to put option "push-type=both", or options
#             shown in this cmake-fedora function. (e.g. SRC_DIR,
#             TRANS_DIR, YES)
#         + PULL_OPTIONS opt ... : (Optional) Zanata pull options.
#             Options should be specified like "encode-tabs=true"
#             No need to put options shown in this cmake-fedora function.
#             (e.g. SRC_DIR, TRANS_DIR, YES)
#         + DISABLE_SSL_CERT: (Optional) Disable SSL check
#         + GENERATE_ZANATA_XML: (Optional) Automatic generate a zanata.xml
#         + CLEAN_ZANATA_XML: (Optional) zanata.xml will be removed with 
#             "make clean"
#         + PROJECT_CONFIG zanata.xml: (Optoional) Path to zanata.xml
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/zanata.xml
#         + USER_CONFIG zanata.ini: (Optoional) Path to zanata.ini
#             Feature disabled warning (M_OFF) will be shown if 
#             if zanata.ini is missing.
#           Default: $HOME/.config/zanata.ini
#       * Targets:
#         + zanata_put_projet: Put project in zanata server.
#         + zanata_put_version: Put version in zanata server.
#         + zanata_push: Push source messages to zanata server.
#         + zanata_push_trans: Push translations to  zanata server.
#         + zanata_push_both: Push source messages and translations to
#             zanata server.
#         + zanata_pull: Pull translations from zanata server.
#


IF(DEFINED _MANAGE_ZANATA_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_ZANATA_CMAKE_)
SET(_MANAGE_ZANATA_CMAKE_ "DEFINED")
INCLUDE(ManageMessage)
INCLUDE(ManageFile)
INCLUDE(ManageString)
INCLUDE(ManageVariable)
INCLUDE(ManageZanataSuggest)

SET(ZANATA_MAVEN_SUBCOMMAND_PREFIX "org.zanata:zanata-maven-plugin:")

## Internal
FUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE var opt)
    STRING_SPLIT(_strList "-" "${opt}")
    SET(_first 1)
    SET(_retStr "")
    FOREACH(_s ${_strList})
	IF("${_retStr}" STREQUAL "")
	    SET(_retStr "${_s}")
	ELSE()
	    STRING(LENGTH "${_s}" _len)
	    MATH(EXPR _tailLen ${_len}-1)
	    STRING(SUBSTRING "${_s}" 0 1 _head)
	    STRING(SUBSTRING "${_s}" 1 ${_tailLen} _tail)
	    STRING(TOUPPER "${_head}" _head)
	    STRING(TOLOWER "${_tail}" _tail)
	    STRING_APPEND(_retStr "${_head}${_tail}")
	ENDIF()
    ENDFOREACH(_s)
    SET(${var} "${_retStr}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE)

## Internal
FUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND var backend opt)
    STRING(REPLACE "_" "-" opt "${opt}")
    STRING(TOLOWER "${opt}" opt)
    IF(NOT "${ARGN}" STREQUAL "")
	SET(value "${ARGN}")
    ENDIF()
    IF("${backend}" STREQUAL "mvn")
	ZANATA_CLIENT_OPT_DASH_TO_CAMEL_CASE(opt "${opt}")
	IF(NOT "${value}" STREQUAL "")
	    LIST(APPEND ${var} "-Dzanata.${opt}=${value}")
	ELSE()
	    LIST(APPEND ${var} "-Dzanata.${opt}")
	ENDIF()
    ELSE()
	## zanata-cli
	LIST(APPEND ${var} "--${opt}")
	IF(NOT "${value}" STREQUAL "")
	    LIST(APPEND ${var} "${value}")
	ENDIF()
    ENDIF()
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND var backend opt)
    STRING_SPLIT(_list "=" "${opt}")
    ZANATA_CLIENT_OPT_LIST_APPEND(${var} ${backend} ${_list})
    SET(${var} "${${var}}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_CLIENT_OPT_LIST_PARSE_APPEND)

## Internal
FUNCTION(ZANATA_CLIENT_SUB_COMMAND var backend subCommand)
    IF("${backend}" STREQUAL "mvn")
	SET(${var} "${ZANATA_MAVEN_SUBCOMMAND_PREFIX}:${subCommand}" PARENT_SCOPE)
    ELSE()
	## zanata-cli
	SET(${var} "${subCommand}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION(ZANATA_CLIENT_SUB_COMMAND)

SET(MANAGE_ZANATA_COMMON_VALID_OPTIONS "YES" "USERNAME" "DISABLE_SSL_CERT" "USER_CONFIG")
SET(MANAGE_ZANATA_PROJECT_VALID_OPTIONS "DEFAULT_PROJECT_TYPE")
SET(MANAGE_ZANATA_VERSION_VALID_OPTIONS "PROJECT_TYPE" "VERSION" )
SET(MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS "PROJECT_CONFIG" "SRC_DIR" "TRANS_DIR")
SET(MANAGE_ZANATA_PUSH_VALID_OPTIONS "")
SET(MANAGE_ZANATA_PULL_VALID_OPTIONS "")
SET(MANAGE_ZANATA_VALID_OPTIONS "GENERATE_ZANATA_XML" "CLEAN_ZANATA_XML"
    "PUSH_OPTIONS" "PULL_OPTIONS"
    "CLIENT_COMMAND"
    ${MANAGE_ZANATA_COMMON_VALID_OPTIONS}
    ${MANAGE_ZANATA_PROJECT_VALID_OPTIONS}
    ${MANAGE_ZANATA_VERSION_VALID_OPTIONS}
    ${MANAGE_ZANATA_PUSH_VALID_OPTIONS}
    ${MANAGE_ZANATA_PULL_VALID_OPTIONS}
    )

FUNCTION(MANAGE_ZANATA)
    VARIABLE_PARSE_ARGN(_o MANAGE_ZANATA_VALID_OPTIONS ${ARGN})

    SET(_zanata_dependency_missing 0)
    ## Is zanata.ini exists
    IF("${_o_USER_CONFIG}" STREQUAL "")
	SET(_o_USER_CONFIG "$ENV{HOME}/.config/zanata.ini")
    ENDIF()
    IF(NOT EXISTS ${_o_USER_CONFIG})
	SET(_zanata_dependency_missing 1)
	M_MSG(${M_OFF} "MANAGE_ZANATA: Failed to find zanata.ini at ${_o_USER_CONFIG}"
	    )
    ENDIF(NOT EXISTS ${_o_USER_CONFIG})

    ## Find client command 
    IF("${_o_CLIENT_COMMAND}" STREQUAL "")
	FIND_PROGRAM_ERROR_HANDLING(ZANATA_EXECUTABLE
	    ERROR_MSG " Zanata support is disabled."
	    ERROR_VAR _zanata_dependency_missing
	    VERBOSE_LEVEL ${M_OFF}
	    FIND_ARGS NAMES zanata-cli mvn
	    )

	IF(NOT _zanata_dependency_missing)
	    SET(_o_CLIENT_COMMAND "${ZANATA_EXECUTABLE}" "-e")
	ENDIF()
    ELSE()
	LIST(GET _o_CLIENT_COMMAND 0 ZANATA_EXECUTABLE)
    ENDIF()

    ## Disable unsupported  client.
    IF(_zanata_dependency_missing)
	RETURN()
    ELSE()
	GET_FILENAME_COMPONENT(ZANATA_BACKEND "${ZANATA_EXECUTABLE}" NAME)
	IF(ZANATA_BACKEND STREQUAL "mvn")
	ELSEIF(ZANATA_BACKEND STREQUAL "zanata-cli")
	ELSE()
	    M_MSG(${M_OFF} "${ZANATA_BACKEND} is ${_o_CLIENT_CMD} not a supported Zanata client")
	    RETURN()
	ENDIF()
    ENDIF()

    ## Manage zanata.xml
    IF("${_o}" STREQUAL "")
	SET(_o_URL "https://translate.zanata.org/zanata/")
    ELSE()
	SET(_o_URL "${_o}")
    ENDIF()
    IF("${_o_PROJECT_SLUG}" STREQUAL "")
	SET(_o_PROJECT_SLUG "${PROJECT_NAME}")
    ENDIF()
    IF("${_o_VERSION}" STREQUAL "")
	SET(_o_VERSION "${PRJ_VER}")
    ENDIF()
    IF(_o_PROJECT_CONFIG)
	SET(zanataXml "${_o_PROJECT_CONFIG}")
    ELSE()
	SET(zanataXml "${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml")
    ENDIF()
    IF(DEFINED _o_GENERATE_ZANATA_XML)
	ADD_CUSTOM_TARGET_COMMAND(zanata_xml
	    OUTPUT "${zanataXml}"
	    COMMAND ${CMAKE_COMMAND} 
	    -D cmd=zanata_xml_make
	    -D "url=${_o_URL}"
	    -D "project=${_o_PROJECT_SLUG}"
	    -D "version=${_o_VERSION}"
	    -D "locales=${_o_LOCALES}"
	    -D "zanataXml=${zanataXml}"
	    -P ${CMAKE_FEDORA_MODULE_DIR}/ManageZanataScript.cmake
	    COMMENT "zanata_xml: ${zanataXml}"
	    VERBATIM
	    )
	IF(NOT DEFINED _o_CLEAN_ZANATA_XML)
	    SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")
	ENDIF()
    ENDIF()

    ## Convert to client options
    IF(DEFINED _o_YES)
	LIST(APPEND _o_CLIENT_COMMAND "-B")
    ENDIF()


    ### Common options
    SET(zanataCommonOptions "")
    FOREACH(optCName "URL" ${MANAGE_ZANATA_COMMON_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(zanataCommonOptions "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)

    IF("${_o_DEFAULT_PROJECT_TYPE}" STREQUAL "")
	SET(_o_DEFAULT_PROJECT_TYPE "gettext")
    ENDIF()


    ### zanata_put_project
    SET(ZANATA_DESCRIPTION_SIZE 80 CACHE STRING "Zanata description size")
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "put-project")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-slug" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-name" "${PROJECT_NAME}")
    STRING(LENGTH "${PRJ_SUMMARY}" _prjSummaryLen)
    IF(NOT _prjSummaryLen GREATER ${ZANATA_DESCRIPTION_SIZE})
	SET(_description "${PRJ_SUMMARY}")
    ELSE()
	STRING(SUBSTRING "${PRJ_SUMMARY}" 0
	    ${ZANATA_DESCRIPTION_SIZE} _description
	    )
    ENDIF()
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-desc" "${_description}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "default-project-type" "${_o_DEFAULT_PROJECT_TYPE}")
    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_put_project
	COMMAND ${exec}
	COMMENT "zanata_put_project: with ${exec}"
	)

    ### zanata_put_version options
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "put-version")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "version-project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "version-slug" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_put_version
	COMMAND ${exec}
	COMMENT "zanata_put_version: with ${exec}"
	)

    ### zanata_push
    IF("${_o_SRC_DIR}" STREQUAL "")
	SET(_o_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()
    IF("${_o_TRANS_DIR}" STREQUAL "")
	SET(_o_TRANS_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF()

    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "push")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-version" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    FOREACH(optCName ${MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)
    IF(_o_PUSH_OPTIONS)
	FOREACH(optStr ${o_PUSH_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PUSH_OPTION ${optStr}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(options "${ZANATA_BACKEND}" "${optStr}")
	ENDFOREACH(optStr)
    ENDIF()

    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_push
	COMMAND ${exec}
	COMMENT "zanata_push: with ${exec}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_both
    SET(extraOptions "")
    ZANATA_CLIENT_OPT_LIST_APPEND(extraOptions "${ZANATA_BACKEND}" "push-type" "both")
    ADD_CUSTOM_TARGET(zanata_push_both 
	COMMAND ${exec} ${extraOptions}
	COMMENT "zanata_push: with ${exec} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ### zanata_push_trans
    SET(extraOptions "")
    ZANATA_CLIENT_OPT_LIST_APPEND(extraOptions "${ZANATA_BACKEND}" "push-type" "trans")
    ADD_CUSTOM_TARGET(zanata_push_trans 
	COMMAND ${exec} ${extraOptions}
	COMMENT "zanata_push: with ${exec} ${extraOptions}"
	DEPENDS ${zanataXml}
	)

    ## zanata_pull
    ZANATA_CLIENT_SUB_COMMAND(subCommand "${ZANATA_BACKEND}" "pull")
    SET(options "")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project" "${_o_PROJECT_SLUG}")
    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-version" "${_o_VERSION}")
    IF(_o_PROJECT_TYPE)
	ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "project-type" "${_o_PROJECT_TYPE}")
    ENDIF()
    FOREACH(optCName ${MANAGE_ZANATA_PROJECT_VERSION_VALID_OPTIONS})
	SET(value "${_o_${optCName}}")
	IF(value)
	    ZANATA_CLIENT_OPT_LIST_APPEND(options "${ZANATA_BACKEND}" "${optCName}" "${value}")
	ENDIF()
    ENDFOREACH(optCName)
    IF(_o_PULL_OPTIONS)
	FOREACH(optStr ${o_PULL_OPTIONS})
	    M_MSG(${M_INFO2} "ManageZanata: PULL_OPTION ${optStr}")
	    ZANATA_CLIENT_OPT_LIST_PARSE_APPEND(options "${ZANATA_BACKEND}" "${optStr}")
	ENDFOREACH(optStr)
    ENDIF()

    SET(exec ${_o_CLIENT_COMMAND} ${subCommand} ${zanataCommonOptions} ${options}) 
    ADD_CUSTOM_TARGET(zanata_pull
	COMMAND ${exec}
	COMMENT "zanata_pull: with ${exec}"
	DEPENDS ${zanataXml}
	)

ENDFUNCTION(MANAGE_ZANATA)

#######################################
# MANAGE_ZANATA_XML_MAKE
#
FUNCTION(ZANATA_LOCALE_COMPLETE var language script country modifier)
    IF("${modifier}" STREQUAL "")
	SET(sModifier "${ZANATA_SUGGEST_MODIFIER_${language}_${script}_}")
	IF(NOT "${sModifier}" STREQUAL "")
	    SET(modifier "${sModifier}")
	ENDIF()
    ENDIF()
    IF("${country}" STREQUAL "")
	SET(sCountry "${ZANATA_SUGGEST_COUNTRY_${language}_${script}_}")
	IF(NOT "${sCountry}" STREQUAL "")
	    SET(country "${sCountry}")
	ENDIF()
    ENDIF()
    IF("${script}" STREQUAL "")
	SET(sScript "${ZANATA_SUGGEST_SCRIPT_${language}_${country}_${modifier}}")
	IF(NOT "${sScript}" STREQUAL "")
	    SET(script "${sScript}")
	ENDIF()
    ENDIF()
    SET(${var} "${language}_${script}_${country}_${modifier}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_LOCALE_COMPLETE var locale)

FUNCTION(ZANATA_PARSE_LOCALE language script country modifier str)
    INCLUDE(ManageZanataSuggest)
    SET(s "")
    SET(c "")
    SET(m "")
    IF("${str}" MATCHES "(.*)@(.*)")
	SET(m "${CMAKE_MATCH_2}")
	SET(str "${CMAKE_MATCH_1}")
    ENDIF()
    STRING(REPLACE "-" "_" str "${str}")
    STRING_SPLIT(lA "_" "${str}")
    LIST(LENGTH lA lLen)
    LIST(GET lA 0 l)
    IF(lLen GREATER 2)
	LIST(GET lA 2 c)
    ENDIF()
    IF(lLen GREATER 1)
	LIST(GET lA 1 x)
	IF("${x}" MATCHES "[A-Z][a-z][a-z][a-z]")
	    SET(s "${x}")
	ELSE()
	    SET(c "${x}")
	ENDIF()
    ENDIF()

    SET(${language} "${l}" PARENT_SCOPE)
    SET(${script} "${s}" PARENT_SCOPE)
    SET(${country} "${c}" PARENT_SCOPE)
    SET(${modifier} "${m}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_PARSE_LOCALE)

FUNCTION(ZANATA_ZANATA_XML_DOWNLOAD zanataXml url project version)
    SET(zanataXmlUrl 
	"${url}iteration/view/${project}/${version}?actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29"
	)
    GET_FILENAME_COMPONENT(zanataXmlDir "${zanataXml}" PATH)
    IF(NOT zanataXmlDir)
	SET(zanataXml "./${zanataXml}")
    ENDIF()
    FILE(DOWNLOAD "${zanataXmlUrl}" "${zanataXml}" LOG logv)
    M_MSG(${M_INFO1} "LOG=${logv}")
ENDFUNCTION(ZANATA_ZANATA_XML_DOWNLOAD)

FUNCTION(ZANATA_BEST_MATCH_LOCALES var serverLocales clientLocales)
    ## Build "Client Hash"
    FOREACH(cL ${clientLocales})
	ZANATA_PARSE_LOCALE(cLang cScript cCountry cModifier "${cL}")
	SET(_ZANATA_CLIENT_LOCALE_${cLang}_${cScript}_${cCountry}_${cModifier} "${cL}")
	ZANATA_LOCALE_COMPLETE(cCLocale "${cLang}" "${cScript}" "${cCountry}" "${cModifier}")
	SET(compKey "_ZANATA_CLIENT_COMPLETE_LOCALE_${cCLocale}")
	IF("${${compKey}}" STREQUAL "")
	    SET("${compKey}" "${cL}")
	ENDIF()
    ENDFOREACH()

    ## 1st pass: Exact match
    FOREACH(sL ${serverLocales})
	ZANATA_PARSE_LOCALE(sLang sScript sCountry sModifier "${sL}")
	SET(scKey "_ZANATA_CLIENT_LOCALE_${sLang}_${sScript}_${sCountry}_${sModifier}")
	## Exact match locale
	SET(cLExact "${${scKey}}")
	IF(NOT "${cLExact}" STREQUAL "")
	    SET(_ZANATA_SERVER_LOCALE_${sL} "${cLExact}")
	    SET(_ZANATA_CLIENT_LOCALE_${cLExact}  "${sL}")
	    LIST(APPEND result "${sL},${cLExact}")
	ENDIF()
    ENDFOREACH() 

    ## 2nd pass: Find the next best match
    FOREACH(sL ${serverLocales})
	IF("${_ZANATA_SERVER_LOCALE_${sL}}" STREQUAL "")
	    ## no exact match
	    ZANATA_PARSE_LOCALE(sLang sScript sCountry sModifier "${sL}")

	    ## Locale completion
	    ZANATA_LOCALE_COMPLETE(sCLocale "${sLang}" "${sScript}" "${sCountry}" "${sModifier}")
	    SET(sCompKey "_ZANATA_CLIENT_COMPLETE_LOCALE_${sCLocale}")
	    SET(bestMatch "")

	    ## Match client locale after Locale completion
	    SET(cLComp "${${sCompKey}}")
	    IF(NOT "${cLComp}" STREQUAL "")
		## And the client locale is not occupied
		IF("${_ZANATA_CLIENT_LOCALE_${cLComp}}" STREQUAL "")
		    SET(_ZANATA_SERVER_LOCALE_${sL} "${cLComp}")
		    SET(_ZANATA_CLIENT_LOCALE_${cLComp}  "${sL}")
		    SET(bestMatch "${cLComp}")
		ENDIF()
	    ENDIF()
	    IF(bestMatch STREQUAL "")
		## No matched, use corrected sL
		STRING(REPLACE "-" "_" bestMatch "${sL}")
		IF("${bestMatch}" STREQUAL "${sL}")
		    M_MSG(${M_OFF} "${sL} does not have matched client locale, use as-is.")
		ELSE()
		    M_MSG(${M_OFF} "${sL} does not have matched client locale, use ${bestMatch}.")
		ENDIF()
	    ENDIF()
	    LIST(APPEND result "${sL},${bestMatch}")
	ENDIF()
    ENDFOREACH() 
    LIST(SORT result)
    SET(${var} "${result}" PARENT_SCOPE)
ENDFUNCTION(ZANATA_BEST_MATCH_LOCALES)

FUNCTION(ZANATA_ZANATA_XML_MAP zanataXml zanataXmlIn clientLocales)
    INCLUDE(ManageTranslation)
    INCLUDE(ManageZanataSuggest)
    SET(localeListVar "${ARGN}")
    FILE(STRINGS "${zanataXmlIn}" zanataXmlLines)
    FILE(REMOVE ${zanataXml})

    IF("${clientLocales}" STREQUAL "")
	## Use client-side system locales.
	MANAGE_GETTEXT_LOCALES(clientLocales "" SYSTEM_LOCALES)
    ENDIF()
    M_MSG(${M_INFO3} "clientLocales=${clientLocales}")

    ## Build "Client Hash"
    IF("${clientLocales}" STREQUAL "")
	## Use client-side system locales.
	MANAGE_GETTEXT_LOCALES(clientLocales "" SYSTEM_LOCALES)
    ENDIF()
    SET(serverLocales "")
    SET(zanataXmlHeader "")
    SET(zanataXmlFooter "")
    SET(zanataXmlIsHeader 1)

    ## Start parsing zanataXmlIn and gather serverLocales
    FOREACH(line ${zanataXmlLines})
	IF("${line}" MATCHES "<locale>(.*)</locale>")
	    ## Is a locale string
	    Set(zanataXmlIsHeader 0)
	    SET(sL "${CMAKE_MATCH_1}")
	    LIST(APPEND serverLocales "${sL}")
	ELSE()
	    IF(zanataXmlIsHeader)
		STRING_APPEND(zanataXmlHeader "${line}" "\n")
	    ELSE()
		STRING_APPEND(zanataXmlFooter "${line}" "\n")
	    ENDIF()
	    ## Not a locale string, write as-is
	ENDIF()
    ENDFOREACH()
    ZANATA_BEST_MATCH_LOCALES(bestMatches "${serverLocales}" "${clientLocales}")
    FILE(WRITE "${zanataXml}" "${zanataXmlHeader}\n")

    FOREACH(bM ${bestMatches})
	STRING_SPLIT(lA "," "${bM}")
	LIST(GET lA 0 sLocale)
	LIST(GET lA 1 cLocale)
	IF("${sLocale}" STREQUAL "${cLocale}")
	    FILE(APPEND "${zanataXml}" "    <locale>${sLocale}</locale>\n")
	ELSE()
	    FILE(APPEND "${zanataXml}" "    <locale map-from=\"${cLocale}\">${sLocale}</locale>\n")
	ENDIF()
    ENDFOREACH(bM)
    FILE(APPEND "${zanataXml}" "${zanataXmlFooter}\n")
ENDFUNCTION(ZANATA_ZANATA_XML_MAP)



