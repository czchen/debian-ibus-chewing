# - Manage RPM Script
# RPM related scripts to be invoked in command line.

MACRO(MANAGE_RPM_SCRIPT_PRINT_USAGE)
    MESSAGE(
	"Manage RPM script: This script is not recommend for end users
	
cmake -Dcmd=spec -Dspec=<project.spec> -Dspec_in=<project.spec.in>
      -Dmanifests=<path/install_manifests.txt>
      -Drelease=<path/RELEASE-NOTES.txt>
      -Dprj_info=<path/prj_info.cmake>
      [\"-Dconfig_replace=<file1;file2>\"]
      [\"-D<var>=<value>\"]
    -P <CmakeModulePath>/ManageRPMScript.cmake
  Make project spec file according to spec_in and prj_info.cmake
  Options:
    -Dconfig_replace: List of configure files that should use
      %config instead of %config(noreplace)
    -Dmainfests: Path to install_manifests.txt
    -Drelease: Path to RELEASE-NOTES.txt
  Note: Please pass the necessary variables via -Dvar=VALUE,
      e.g. \"-DPROJECT_NAME=cmake-fedora\"

cmake -Dcmd=spec_manifests
      -Dmanifests=<path/install_manifests.txt>
      -Dprj_info=<path/prj_info.cmake>
      [\"-Dconfig_replace=<file1;file2>\"]
      [\"-D<var>=<value>\"]
    -P <CmakeModulePath>/ManageRPMScript.cmake
  Convert install_manifests.txt to part of a SPEC file.
  Options:
    -Dconfig_replace: List of configure files that should use
      %config instead of %config(noreplace)
    -Dmainfests: Path to install_manifests.txt
  Note: Please pass the necessary variables via -Dvar=VALUE,
    e.g. \"-DPROJECT_NAME=cmake-fedora\"
    
cmake -Dcmd=spec_changelog
      -Dmanifests=<path/install_manifests.txt>
      -Drelease=<path/RELEASE-NOTES.txt>
      -Dprj_info=<path/prj_info.cmake>
      [\"-D<var>=<value>\"]
    -P <CmakeModulePath>/ManageRPMScript.cmake
  Convert RELEASE-NOTES.txt to ChangeLog a SPEC file.
    Options:
      -Dmainfests: Path to install_manifests.txt
    Note: Please pass the necessary variables via -Dvar=VALUE,
       e.g. \"-DPROJECT_NAME=cmake-fedora\"

cmake -Dcmd=make_manifests
       [\"-Dmanifests=<path>/install_manifests.txt>\"]
       [\"-Dtmp_dir=<dir>\"]
  Make install_manifests.txt.
  Options:
    -Dmainfests: Path to install_manifests.txt
    -Dtmp_dir: Directory for tempory files. 
       Default is CMAKE_FEDORA_TMP_DIR

"
)
ENDMACRO(MANAGE_RPM_SCRIPT_PRINT_USAGE)

MACRO(MANIFEST_TO_STRING strVar hasTransVar manifestsFile)
    SET(${hasTransVar} 0)

    FILE(STRINGS ${manifestsFile} _filesInManifests)
    SET(_docList "")
    SET(_fileList "")
    FOREACH(_file ${_filesInManifests})
	SET(_addToFileList 1)
	SET(_config_replace_detected 0)
	IF(config_replace)
	    FOREACH(_mF ${config_replace})
		IF("${_file}" STREQUAL "${_mF}")
		    SET(_config_replace_detected 1)
		    BREAK()
		ENDIF()
	    ENDFOREACH()		
	ENDIF()
	STRING(REPLACE "${PROJECT_NAME}" "%{name}" _file "${_file}")
        IF("${_file}" MATCHES "^/usr/bin/")
	    STRING(REGEX REPLACE "^/usr/bin/" "%{_bindir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/sbin/")
	    STRING(REGEX REPLACE "^/usr/sbin/" "%{_sbindir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/libexec/")
	    STRING(REGEX REPLACE "^/usr/libexec/" "%{_libexecdir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/lib")
	    STRING(REGEX REPLACE "^/usr/lib(64)?/" "%{_libdir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/include/")
	    STRING(REGEX REPLACE "^/usr/include/" "%{_includedir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/etc/rc.d/init.d/")
	    STRING(REGEX REPLACE "^/etc/rc.d/init.d/" "%{_initrddir}/" _f "${_file}")
	ELSEIF("${_file}" MATCHES "^/etc/")
	    STRING(REGEX REPLACE "^/etc/" "%config(noreplace) %{_sysconfdir}/" _file "${_file}")
	ELSEIF("${_file}" MATCHES "^/usr/share/info/")
	    STRING(REGEX REPLACE "^/usr/share/info/" "%{_infodir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/doc/")
	    SET(_addToFileList 0)
	    STRING(REGEX REPLACE "^/usr/share/doc/%{name}[^/]*/" "" _file ${_file})
	    LIST(APPEND _docList ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/man/")
	    STRING(REGEX REPLACE "^/usr/share/man/" "%{_mandir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/usr/share/")
	    IF(_file MATCHES "^/usr/share/locale/")
		SET(_addToFileList 0)
		SET(${hasTransVar} 1)
	    ENDIF()
	    STRING(REGEX REPLACE "^/usr/share/" "%{_datadir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/var/lib/")
	    STRING(REGEX REPLACE "^/var/lib/" "%{_sharedstatedir}/" _file ${_file})
	ELSEIF("${_file}" MATCHES "^/var/")
	    STRING(REGEX REPLACE "^/var/" "%{_localstatedir}/" _file ${_file})
	ELSE()
	    M_MSG(${M_ERROR} "ManageRPMScript: Unhandled file: ${_file}")
	ENDIF()
	IF(_config_replace_detected)
	    IF("${_file}" MATCHES "%config\\(noreplace\\)")
		STRING(REPLACE "%config(noreplace)" "%config" 
		    _file ${_file})
	    ELSE()
		STRING(REGEX REPLACE "^%" "%config %" _file ${_file})
	    ENDIF()
	ENDIF()

	IF(_addToFileList)
	    LIST(APPEND _fileList "${_file}")
	ENDIF(_addToFileList)
    ENDFOREACH(_file ${_filesInManifests})
    IF(${hasTransVar} EQUAL 1)
	STRING_APPEND(${strVar} "%files -f %{name}.lang" "\n")
    ELSE()
	STRING_APPEND(${strVar} "%files" "\n")
    ENDIF()
    STRING_APPEND(${strVar} "%defattr(-, root, root, -)" "\n")
    # Append %doc
    STRING_JOIN(_docStr " " ${_docList})
    STRING_APPEND(${strVar} "%doc ${_docStr}" "\n")

    # Append rest of files
    LIST(SORT _fileList)
    FOREACH(_f ${_fileList})
	STRING_APPEND(${strVar} "${_f}" "\n")
    ENDFOREACH(_f ${_fileList})
ENDMACRO(MANIFEST_TO_STRING)

FUNCTION(SPEC_MANIFESTS)
    IF(NOT manifests)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Dmanifests=<install_manifests.txt>\"")
    ENDIF()
    SET(RPM_FAKE_INSTALL_DIR "/tmp/cmake-fedora-fake-install")
    EXECUTE_PROCESS(COMMAND make DESTDIR=${RPM_FAKE_INSTALL_DIR} install)
    MANIFEST_TO_STRING(mStr hasTrans ${manifests})
    M_OUT("${mStr}")
ENDFUNCTION(SPEC_MANIFESTS)

MACRO(CHANGELOG_TO_STRING strVar)
    EXECUTE_PROCESS(
	COMMAND ${CMAKE_COMMAND}
	-Dcmd=extract_current
	-Drelease=${release}
	-P ${CMAKE_FEDORA_MODULE_DIR}/ManageChangeLogScript.cmake
	OUTPUT_VARIABLE _changeLogThis
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)

    FIND_PROGRAM_ERROR_HANDLING(CMAKE_FEDORA_KOJI_CMD
	FIND_ARGS NAMES cmake-fedora-koji
	PATHS  ${CMAKE_FEDORA_SCRIPT_PATH_HINTS}
	)

    SET(CMAKE_FEDORA_TMP_DIR "/tmp")
    SET(RPM_CHANGELOG_TMP_FILE "${CMAKE_FEDORA_TMP_DIR}/${PROJECT_NAME}.changelog")

    EXECUTE_PROCESS(
	COMMAND ${CMAKE_FEDORA_KOJI_CMD} newest-changelog "${PROJECT_NAME}" | tail -n +2
	OUTPUT_VARIABLE _changeLogPrev
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)

    SET(${strVar} "%changelog")
    STRING_APPEND(${strVar} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}-${RPM_RELEASE_NO}" "\n")
    STRING_APPEND(${strVar} "${_changeLogThis}\n" "\n")
    STRING_APPEND(${strVar} "${_changeLogPrev}" "\n")
ENDMACRO(CHANGELOG_TO_STRING strVar)

FUNCTION(SPEC_CHANGELOG)
    IF(NOT release)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Drelease=<RELEASE-NOTES.txt>\"")
    ENDIF()
    PRJ_INFO_CMAKE_READ(${prj_info})
    CHANGELOG_TO_STRING(_changeLogStr)
    M_OUT("${_changeLogStr}")
ENDFUNCTION(SPEC_CHANGELOG)

# Not exactly a header, but the first half
MACRO(SPEC_WRITE_HEADER)
    ## Summary
    RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_SUMMARY_OUTPUT
	"Summary" "" "${PRJ_SUMMARY}"
	)
    SET(_lang "")
    FOREACH(_sT ${SUMMARY_TRANSLATIONS})
	IF(_lang STREQUAL "")
	    SET(_lang "${_sT}")
	ELSE(_lang STREQUAL "")
	    RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_SUMMARY_OUTPUT
		"Summary" "${_lang}" "${_sT}"
		)
	    SET(_lang "")
	ENDIF(_lang STREQUAL "")
    ENDFOREACH(_sT ${SUMMARY_TRANSLATIONS})

    ## Url
    SET(RPM_SPEC_URL_OUTPUT "${RPM_SPEC_URL}")

    ## Source
    SET(_buf "")
    SET(_i 0)
    FOREACH(_s ${RPM_SPEC_SOURCES})
	RPM_SPEC_STRING_ADD_TAG(_buf "Source${_i}" "" "${_s}")
	MATH(EXPR _i ${_i}+1)
    ENDFOREACH(_s ${RPM_SPEC_SOURCES})
    RPM_SPEC_STRING_ADD(RPM_SPEC_SOURCE_OUTPUT "${_buf}" FRONT)

    ## Requires and BuildRequires
    SET(_buf "")
    FOREACH(_s ${BUILD_REQUIRES})
	RPM_SPEC_STRING_ADD_TAG(_buf "BuildRequires" "" "${_s}")
    ENDFOREACH(_s)

    FOREACH(_s ${REQUIRES})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "" "${_s}")
    ENDFOREACH(_s)
    FOREACH(_s ${REQUIRES_PRE})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "pre" "${_s}")
    ENDFOREACH(_s)
    FOREACH(_s ${REQUIRES_PREUN})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "preun" "${_s}")
    ENDFOREACH(_s)
    FOREACH(_s ${REQUIRES_POST})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "post" "${_s}")
    ENDFOREACH(_s)
    FOREACH(_s ${REQUIRES_POSTUN})
	RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "postun" "${_s}")
    ENDFOREACH(_s)
    RPM_SPEC_STRING_ADD(RPM_SPEC_REQUIRES_OUTPUT "${_buf}" FRONT)

    ## Description
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_DESCRIPTION_OUTPUT
	"description" "" "${PRJ_DESCRIPTION}"
	)
    SET(_lang "")
    FOREACH(_sT ${DESCRIPTION_TRANSLATIONS})
	IF(_lang STREQUAL "")
	    SET(_lang "${_sT}")
	ELSE(_lang STREQUAL "")
	    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_DESCRIPTION_OUTPUT
		"description" "-l ${_lang}" "${_sT}" "\n"
		)
	    SET(_lang "")
	ENDIF(_lang STREQUAL "")
    ENDFOREACH(_sT ${DESCRIPTION_TRANSLATIONS})

    ## Header
    ## %{_build_arch}
    IF("${BUILD_ARCH}" STREQUAL "")
	EXECUTE_PROCESS(COMMAND ${RPM_CMD} -E "%{_build_arch}"
	    OUTPUT_VARIABLE _RPM_BUILD_ARCH
	    OUTPUT_STRIP_TRAILING_WHITESPACE)
	SET(RPM_BUILD_ARCH "${_RPM_BUILD_ARCH}" 
	    CACHE STRING "RPM Arch")
    ELSE("${BUILD_ARCH}" STREQUAL "")
	SET(RPM_BUILD_ARCH "${BUILD_ARCH}" 
	    CACHE STRING "RPM Arch")
	RPM_SPEC_STRING_ADD_TAG(RPM_SPEC_HEADER_OUTPUT
	    "BuildArch" "" "${BUILD_ARCH}"
	    )
    ENDIF("${BUILD_ARCH}" STREQUAL "")

    ## Install
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_INSTALL_SECTION_OUTPUT
	"install" "" "rm -rf %{buildroot}
make install DESTDIR=%{buildroot}"
        )

    RPM_SPEC_STRING_ADD(RPM_SPEC_INSTALL_SECTION_OUTPUT
    "# We install document using doc 
rm -fr %{buildroot}%{_docdir}/*")

ENDMACRO(SPEC_WRITE_HEADER)

FUNCTION(SPEC_MAKE)
    IF(NOT manifests)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Dmanifests=<install_manifests.txt>\"")
    ENDIF()
    IF(NOT release)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires \"-Drelease=<RELEASE-NOTES.txt>\"")
    ENDIF()
    IF(NOT prj_info)
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Requires -Dprj_info=<prj_info.cmake>")
    ENDIF()
    PRJ_INFO_CMAKE_READ(${prj_info})
    SPEC_WRITE_HEADER()
    MANIFEST_TO_STRING(RPM_SPEC_FILES_SECTION_OUTPUT hasTrans ${manifests})
    IF(hasTrans)
	RPM_SPEC_STRING_ADD(RPM_SPEC_INSTALL_SECTION_OUTPUT 
	    "\n%find_lang %{name}\n")
    ENDIF()
    CHANGELOG_TO_STRING(RPM_SPEC_CHANGELOG_SECTION_OUTPUT)
    CONFIGURE_FILE(${spec_in} ${spec} @ONLY)
ENDFUNCTION(SPEC_MAKE)

FUNCTION(MAKE_MANIFESTS)
    IF(NOT tmp_dir)
	SET(tmp_dir "${CMAKE_FEDORA_TMP_DIR}")
    ENDIF(NOT tmp_dir)
    SET(_opts "")
    IF(manifests)
	GET_FILENAME_COMPONENT(manifestsDir "${manifests}" PATH)
	SET(_opts "WORKING_DIRECTORY" "${manifestsDir}")
    ENDIF()
    
    EXECUTE_PROCESS(COMMAND make install DESTDIR=${tmp_dir}
	${_opts})
ENDFUNCTION(MAKE_MANIFESTS)

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
CMAKE_FEDORA_CONF_GET_ALL_VARIABLES()
INCLUDE(DateTimeFormat)
INCLUDE(ManageVersion)
INCLUDE(ManageRPM)

IF(NOT DEFINED cmd)
    MANAGE_RPM_SCRIPT_PRINT_USAGE()
ELSE()
    ## Append FILE_INSTALL_SYSCONF_LIST as config_replace
    FOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})
	LIST(APPEND _config_replace "/etc/${_f}")
    ENDFOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})
    FOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})
	LIST(APPEND _config_replace "/etc/${PROJECT_NAME}/${_f}")
    ENDFOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})
    IF("${cmd}" STREQUAL "spec")
	IF(NOT spec)
	    MANAGE_RPM_SCRIPT_PRINT_USAGE()
	    M_MSG(${M_FATAL} "Requires -Dspec=<file.spec>")
	ENDIF(NOT spec)
	SPEC_MAKE()
    ELSEIF("${cmd}" STREQUAL "spec_manifests")
	SPEC_MANIFESTS()
    ELSEIF("${cmd}" STREQUAL "spec_changelog")
	SPEC_CHANGELOG()
    ELSEIF("${cmd}" STREQUAL "make_manifests")
	MAKE_MANIFESTS()
    ELSE()
	MANAGE_RPM_SCRIPT_PRINT_USAGE()
	M_MSG(${M_FATAL} "Invalid cmd ${cmd}")
    ENDIF()
ENDIF()


