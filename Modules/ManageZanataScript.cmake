# - Manage Zanata Script
# Zanata related scripts to be invoked in command line.

MACRO(MANAGE_ZANATA_SCRIPT_PRINT_USAGE)
    MESSAGE("Manage Zanata script: This script is not recommend for end users

cmake -D cmd=zanata_xml_download
      -D url=<zanata_server_url>
      -D project=<project_id>
      -D version=<version_id>
      [-D zanata_xml=<zanata.xml>]
      [-D \"<var>=<value>\"]
    -P <CmakeModulePath>/ManageZanataScript.cmake

    Download zanata.xml from Zanata Server
    Options:
        url: Zanata server URL (e.g. https://translate.zanata.org/zanata/)
	    This should be indentical to what is written in zanata.ini.
	project: project ID in Zanata.
	version: version ID in Zanata.
	zanata_xml: (Optional) zanata.xml output file. 
            Default: zanata.xml

cmake -D cmd=zanata_xml_map
      [-D \"locales=<locale1;locale2...>\"]
      [-D zanata_xml=<zanata.xml>]
      [-D zanata_xml_in=<zanata.xml>]
      [-D \"<var>=<value>\"]
    -P <CmakeModulePath>/ManageZanataScript.cmake

    Map the zanata server locales with client translation files,
    so it will output correctly.
    Options:
        locales: client-side locales to be mapped.
	zanata_xml: (Optional) zanata.xml output file.
	     Default: zanata.xml
	zanata_xml_in: (Optional) zanata.xml input file.
	     Default: zanata.xml

cmake -D cmd=zanata_xml_make
      -D url=<zanata_server_url>
      -D project=<project_id>
      -D version=<version_id>
      [-D \"locales=<locale1;locale2...>\"]
      [-D zanata_xml=<zanata.xml>]
      [-D \"<var>=<value>\"]
    -P <CmakeModulePath>/ManageZanataScript.cmake

    Make a working zanata.xml.
    Options:
        url: Zanata server URL (e.g. https://translate.zanata.org/zanata/)
	    This should be indentical to what is written in zanata.ini.
	project: project ID in Zanata.
	version: version ID in Zanata.
        locales: client-side locales to be mapped.
	zanata_xml: (Optional) zanata.xml output file.
	     Default: zanata.xml
	"
	)
ENDMACRO(MANAGE_ZANATA_SCRIPT_PRINT_USAGE)

MACRO(ZANATA_XML_DOWNLOAD_CHECK)
    SET(_requirementMet 1)
    IF(NOT url)
	M_MSG("${M_ERROR}" "Requires url")
	SET(_requirementMet 0)
    ENDIF()
    IF(NOT project)
	M_MSG("${M_ERROR}" "Requires project")
	SET(_requirementMet 0)
    ENDIF()
    IF(NOT version)
	M_MSG("${M_ERROR}" "Requires version")
	SET(_requirementMet 0)
    ENDIF()
    IF(NOT _requirementMet)
	RETURN()
    ENDIF()
    IF(NOT zanata_xml)
	SET(zanata_xml "zanata.xml")
    ENDIF()
    ZANATA_ZANATA_XML_DOWNLOAD("${zanata_xml}" "${url}" "${project}" "${version}")
ENDMACRO()

MACRO(ZANATA_XML_MAP_CHECK)
    SET(_requirementMet 1)
    IF(NOT zanata_xml_in)
	SET(zanata_xml_in "zanata.xml")
    ENDIF()

    IF(NOT EXISTS ${zanata_xml_in})
	M_MSG("${M_ERROR}" "File not exists: ${zanata_xml_in}")
	SET(_requirementMet 0)
    ENDIF()

    IF(NOT zanata_xml)
	SET(zanata_xml "zanata.xml")
    ENDIF()

    IF(NOT _requirementMet)
	RETURN()
    ENDIF()
    ZANATA_ZANATA_XML_MAP("${zanata_xml}" "${zanata_xml_in}" "${locales}")
ENDMACRO()

FUNCTION(ZANATA_XML_MAKE_CHECK)
    IF(NOT zanata_xml)
	SET(zanata_xml "zanata.xml")
    ENDIF()
    SET(zanata_xml_in "${zanata_xml}")

    IF(NOT EXISTS "${zanata_xml_in}")
	ZANATA_XML_DOWNLOAD_CHECK()
    ENDIF()

    ZANATA_XML_MAP_CHECK()
ENDFUNCTION()

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
    "${MANAGE_MODULE_PATH}" PATH)

INCLUDE(ManageEnvironmentCommon)
INCLUDE(ManageString)
INCLUDE(ManageVariable)
INCLUDE(ManageVersion)
INCLUDE(ManageZanata)

IF(NOT DEFINED cmd)
    MANAGE_ZANATA_SCRIPT_PRINT_USAGE()
ELSE()
    IF("${cmd}" STREQUAL "zanata_xml_download")
	ZANATA_XML_DOWNLOAD_CHECK()
    ELSEIF("${cmd}" STREQUAL "zanata_xml_map")
	ZANATA_XML_MAP_CHECK()
    ELSEIF("${cmd}" STREQUAL "zanata_xml_make")
	ZANATA_XML_MAKE_CHECK()
    ELSE()
	MANAGE_ZANATA_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
    ENDIF()
ENDIF()





