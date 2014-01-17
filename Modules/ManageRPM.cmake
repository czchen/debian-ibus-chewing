# - RPM generation, maintaining (remove old rpm) and verification (rpmlint).
# This module provides macros that provides various rpm building and
# verification targets.
#
# This module needs variable from ManageArchive, so INCLUDE(ManageArchive)
# before this module.
#
# Includes:
#   ManageFile
#   ManageTarget
#
# Reads and defines following variables if dependencies are satisfied:
#   PRJ_RPM_SPEC_FILE: spec file for rpmbuild.
#   RPM_SPEC_BUILD_ARCH: (optional) Set "BuildArch:"
#   RPM_BUILD_ARCH: (optional) Arch that will be built."
#   RPM_DIST_TAG: (optional) Current distribution tag such as el5, fc10.
#     Default: Distribution tag from rpm --showrc
#
#   RPM_BUILD_TOPDIR: (optional) Directory of  the rpm topdir.
#     Default: ${CMAKE_BINARY_DIR}
#
#   RPM_BUILD_SPECS: (optional) Directory of generated spec files
#     and RPM-ChangeLog.
#     Note this variable is not for locating
#     SPEC template (project.spec.in), RPM-ChangeLog source files.
#     These are located through the path of spec_in.
#     Default: ${RPM_BUILD_TOPDIR}/SPECS
#
#   RPM_BUILD_SOURCES: (optional) Directory of source (tar.gz or zip) files.
#     Default: ${RPM_BUILD_TOPDIR}/SOURCES
#
#   RPM_BUILD_SRPMS: (optional) Directory of source rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/SRPMS
#
#   RPM_BUILD_RPMS: (optional) Directory of generated rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/RPMS
#
#   RPM_BUILD_BUILD: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILD
#
#   RPM_BUILD_BUILDROOT: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILDROOT
#
#   RPM_RELEASE_NO: (optional) RPM release number
#     Default: 1
#
# Defines following variables:
#   RPM_IGNORE_FILES: A list of exclude file patterns for PackSource.
#     This value is appended to SOURCE_ARCHIVE_IGNORE_FILES after including
#     this module.
#   RPM_FILES_SECTION_CONTENT: A list of string  
#
# Defines following Macros:
#   RPM_SPEC_STRING_ADD(var str [position])
#   - Add a string to SPEC string.
#     * Parameters:
#       + var: Variable that hold results in string format.
#       + str: String to be added.
#       + position: (Optional) position to put the tag. 
#       Valid value: FRONT for inserting in the beginning.
#       Default: Append in the end of string.
#       of string.
#
#   RPM_SPEC_STRING_ADD_DIRECTIVE var directive attribute content)
#   - Add a SPEC directive (e.g. %description -l zh_TW) to SPEC string.
#     Parameters:
#     + var: Variable that hold results in string format.
#     + directive: Directive to be added.
#     + attribute: Attribute of tag. That is, string between '()'
#     + value: Value fot the tag.
#     + position: (Optional) position to put the tag. 
#       Valid value: FRONT for inserting in the beginning.
#       Default: Append in the end of string.
#       of string.
#
#   RPM_SPEC_STRING_ADD_TAG(var tag attribute value [position])
#   - Add a SPEC tag (e.g. BuildArch: noarch) to SPEC string.
#     Parameters:
#     + var: Variable that hold results in string format.
#     + tag: Tag to be added.
#     + attribute: Attribute of tag. That is, string between '()'
#     + value: Value fot the tag.
#     + position: (Optional) position to put the tag. 
#       Valid value: FRONT for inserting in the beginning.
#       Default: Append in the end of string.
#       of string.
#
#   PACK_RPM([SPEC_IN specInFile] [SPEC specFile])
#   - Generate spec and pack rpm  according to the spec file.
#     Parameters:
#     + SPEC_IN specInFile: RPM SPEC template file as .spec.in
#     + SPEC specFile: Output RPM SPEC file 
#       Default: ${RPM_BUILD_SPEC}/${PROJECT_NAME}.spec
#     Targets:
#     + srpm: Build srpm (rpmbuild -bs).
#     + rpm: Build rpm and srpm (rpmbuild -bb)
#     + rpmlint: Run rpmlint to generated rpms.
#     + clean_rpm": Clean all rpm and build files.
#     + clean_pkg": Clean all source packages, rpm and build files.
#     + clean_old_rpm: Remove old rpm and build files.
#     + clean_old_pkg: Remove old source packages and rpms.
#     This macro defines following variables:
#     + PRJ_RELEASE: Project release with distribution tags. (e.g. 1.fc13)
#     + RPM_RELEASE_NO: Project release number, without distribution tags. (e.g. 1)
#     + PRJ_SRPM_FILE: Path to generated SRPM file, including relative path.
#     + PRJ_RPM_FILES: Binary RPM files to be build.
#     This macro reads following variables
#     + RPM_SPEC_CMAKE_FLAGS: cmake flags in RPM spec.
#     + RPM_SPEC_MAKE_FLAGS: "make flags in RPM spec.
#
#   RPM_MOCK_BUILD()
#   - Add mock related targets.
#     Targets:
#     + rpm_mock_i386: Make i386 rpm
#     + rpm_mock_x86_64: Make x86_64 rpm
#     This macor reads following variables?:
#     + MOCK_RPM_DIST_TAG: Prefix of mock configure file, such as "fedora-11", "fedora-rawhide", "epel-5".
#         Default: Convert from RPM_DIST_TAG
#

IF(NOT DEFINED _MANAGE_RPM_CMAKE_)
    SET (_MANAGE_RPM_CMAKE_ "DEFINED")

    INCLUDE(ManageFile)
    INCLUDE(ManageTarget)
    SET(_manage_rpm_dependency_missing 0)
    SET(_cmake_fedora_dependency_missing 0)
    SET(RPM_SPEC_TAG_PADDING 16 CACHE STRING "RPM SPEC Tag padding")

    FIND_PROGRAM_ERROR_HANDLING(RPM_CMD
	ERROR_MSG " rpm build support is disabled."
	ERROR_VAR _manage_rpm_dependency_missing
	VERBOSE_LEVEL ${M_OFF}
	"rpm"
	)

    FIND_PROGRAM_ERROR_HANDLING(RPMBUILD_CMD
	ERROR_MSG " rpm build support is disabled."
	ERROR_VAR _manage_rpm_dependency_missing
	VERBOSE_LEVEL ${M_OFF}
	NAMES "rpmbuild-md5" "rpmbuild"
	)

    FIND_PROGRAM_ERROR_HANDLING(CMAKE_FEDORA_KOJI_CMD
	ERROR_MSG " cmake-fedora support is disabled."
	ERROR_VAR _cmake_fedora_dependency_missing
	VERBOSE_LEVEL ${M_OFF}
	"cmake-fedora-koji"
	PATHS ${CMAKE_SOURCE_DIR}/scripts
	)

    IF(NOT _manage_rpm_dependency_missing)
	INCLUDE(ManageVariable)

	SET(RPM_SPEC_CMAKE_FLAGS "-DCMAKE_FEDORA_ENABLE_FEDORA_BUILD=1"
	    CACHE STRING "CMake flags in RPM SPEC"
	)
	SET(RPM_SPEC_MAKE_FLAGS "VERBOSE=1 %{?_smp_mflags}"
	    CACHE STRING "Make flags in RPM SPEC"
	)
	SET(RPM_SPEC_BUILD_OUTPUT 
	    "%cmake ${RPM_SPEC_CMAKE_FLAGS} .
make ${RPM_SPEC_MAKE_FLAGS}"
	)

	SET(RPM_SPEC_INSTALL_OUTPUT
	    "%__rm -rf %{buildroot}
make install DESTDIR=%{buildroot}"
	)

        SET(RPM_SPEC_FILES_SECTION_OUTPUT "%defattr(-,root,root-)")

	# %{dist}
	EXECUTE_PROCESS(COMMAND ${RPM_CMD} -E "%{dist}"
	    COMMAND sed -e "s/^\\.//"
	    OUTPUT_VARIABLE _RPM_DIST_TAG
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	SET(RPM_DIST_TAG "${_RPM_DIST_TAG}" CACHE STRING "RPM Dist Tag")

	SET(RPM_RELEASE_NO "1" CACHE STRING "RPM Release Number")

	SET(RPM_BUILD_TOPDIR "${CMAKE_BINARY_DIR}" CACHE PATH "RPM topdir")

	SET(RPM_IGNORE_FILES "debug.*s.list")
	FOREACH(_dir "SPECS" "SOURCES" "SRPMS" "RPMS" "BUILD" "BUILDROOT")
	    IF(NOT RPM_BUILD_${_dir})
		SET(RPM_BUILD_${_dir} "${RPM_BUILD_TOPDIR}/${_dir}" 
		    CACHE PATH "RPM ${_dir} dir"
		    )
		MARK_AS_ADVANCED(RPM_BUILD_${_dir})
		IF(NOT "${_dir}" STREQUAL "SPECS")
		    LIST(APPEND RPM_IGNORE_FILES "/${_dir}/")
		ENDIF(NOT "${_dir}" STREQUAL "SPECS")
		FILE(MAKE_DIRECTORY "${RPM_BUILD_${_dir}}")
	    ENDIF(NOT RPM_BUILD_${_dir})
	ENDFOREACH(_dir "SPECS" "SOURCES" "SRPMS" "RPMS" "BUILD" "BUILDROOT")
	
	# Add RPM build directories in ignore file list.
	LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES ${RPM_IGNORE_FILES})

    ENDIF(NOT _manage_rpm_dependency_missing)

    MACRO(MANAGE_RPM_CHANGELOG)
	EXECUTE_PROCESS(COMMAND cat "${CHANGELOG_ITEM_FILE}"
	    OUTPUT_VARIABLE CHANGELOG_ITEMS
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )
	SET(RPM_CHANGELOG_FILE "${RPM_BUILD_SPECS}/RPM-ChangeLog")
	SET(RPM_CHANGELOG_PREV_FILE "${RPM_CHANGELOG_FILE}.prev")
	IF(NOT _cmake_fedora_dependency_missing)
	    IF(EXISTS "${RPM_CHANGELOG_PREV_FILE}")
		IF("${RELEASE_NOTES_FILE}" IS_NEWER_THAN "${RPM_CHANGELOG_PREV_FILE}")
		    M_MSG(${M_INFO1} "Updating RPM-ChangeLog.prev from koji")
		    EXECUTE_PROCESS(
			COMMAND ${CMAKE_FEDORA_KOJI_CMD} newest-changelog "${PROJECT_NAME}"
			OUTPUT_FILE ${RPM_CHANGELOG_PREV_FILE}
			)
		ELSE("${RELEASE_NOTES_FILE}" IS_NEWER_THAN "${RPM_CHANGELOG_PREV_FILE}")
		    M_MSG(${M_INFO1} "RPM-ChangeLog.prev is newer than RELEASE-NOTES, no need to update")
		ENDIF("${RELEASE_NOTES_FILE}" IS_NEWER_THAN "${RPM_CHANGELOG_PREV_FILE}")
	    ELSE(EXISTS "${RPM_CHANGELOG_PREV_FILE}")
		M_MSG(${M_INFO1} "Create newest RPM-ChangeLog.prev from koji")
		EXECUTE_PROCESS(
		    COMMAND ${CMAKE_FEDORA_KOJI_CMD} newest-changelog "${PROJECT_NAME}"
		    OUTPUT_FILE ${RPM_CHANGELOG_PREV_FILE}
		    )
	    ENDIF(EXISTS "${RPM_CHANGELOG_PREV_FILE}")
	ENDIF(NOT _cmake_fedora_dependency_missing)
	IF(EXISTS ${RPM_CHANGELOG_PREV_FILE})
	    # Update RPM_ChangeLog
	    # Use this instead of FILE(READ is to avoid error when reading '\'
	    # character.
	    EXECUTE_PROCESS(COMMAND cat "${RPM_CHANGELOG_PREV_FILE}"
		OUTPUT_VARIABLE RPM_CHANGELOG_PREV
		OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	ELSE(EXISTS ${RPM_CHANGELOG_PREV_FILE})
	    SET(RPM_CHNAGELOG_PREV "")
	ENDIF(EXISTS ${RPM_CHANGELOG_PREV_FILE})
    ENDMACRO(MANAGE_RPM_CHANGELOG)

    FUNCTION(RPM_SPEC_STRING_ADD var str)
	IF("${ARGN}" STREQUAL "FRONT")
	    STRING_PREPEND(${var} "${str}" "\n")
	    SET(pos "${ARGN}")
	ELSE("${ARGN}" STREQUAL "FRONT")
	    STRING_APPEND(${var} "${str}" "\n")
	ENDIF("${ARGN}" STREQUAL "FRONT")
	SET(${var} "${${var}}" PARENT_SCOPE)
    ENDFUNCTION(RPM_SPEC_STRING_ADD var str)

    FUNCTION(RPM_SPEC_STRING_ADD_DIRECTIVE var directive attribute content)
	SET(_str "%${directive}")
	IF(NOT attribute STREQUAL "")
	    STRING_APPEND(_str " ${attribute}")
	ENDIF(NOT attribute STREQUAL "")

	IF(NOT content STREQUAL "")
	    STRING_APPEND(_str "\n${content}")
	ENDIF(NOT content STREQUAL "")
	STRING_APPEND(_str "\n")
	RPM_SPEC_STRING_ADD(${var} "${_str}" ${ARGN})
	SET(${var} "${${var}}" PARENT_SCOPE)
    ENDFUNCTION(RPM_SPEC_STRING_ADD_DIRECTIVE var directive attribute content)

    FUNCTION(RPM_SPEC_STRING_ADD_TAG var tag attribute value)
	IF("${attribute}" STREQUAL "")
	    SET(_str "${tag}:")
	ELSE("${attribute}" STREQUAL "")
	    SET(_str "${tag}(${attribute}):")
	ENDIF("${attribute}" STREQUAL "")
	STRING_PADDING(_str "${_str}" ${RPM_SPEC_TAG_PADDING})
	STRING_APPEND(_str "${value}")
	RPM_SPEC_STRING_ADD(${var} "${_str}" ${ARGN})
	SET(${var} "${${var}}" PARENT_SCOPE)
    ENDFUNCTION(RPM_SPEC_STRING_ADD_TAG var tag attribute value)

    MACRO(PRJ_RPM_SPEC_PREPARE_FILES fileType pathPrefix)
	FOREACH(_f ${FILE_INSTALL_${fileType}_LIST})
	    RPM_SPEC_STRING_ADD(RPM_SPEC_FILES_SECTION_OUTPUT 
		"${pathPrefix}${_f}" "\n"
	    )
	ENDFOREACH(_f ${FILE_INSTALL_${fileType}_LIST})
    ENDMACRO(PRJ_RPM_SPEC_PREPARE_FILES)

    MACRO(PRJ_RPM_SPEC_PREPARE)
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
		    "Summary" "${lang}" "${PRJ_SUMMARY}"
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

	## Requires (and BuildRequires)
	SET(_buf "")
	FOREACH(_s ${BUILD_REQUIRES})
	    RPM_SPEC_STRING_ADD_TAG(_buf "BuildRequires" "" "${_s}")
	ENDFOREACH(_s ${RPM_SPEC_SOURCES})

	FOREACH(_s ${REQUIRES})
	    RPM_SPEC_STRING_ADD_TAG(_buf "Requires" "" "${_s}")
	ENDFOREACH(_s ${RPM_SPEC_SOURCES})
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

	## Build
	IF(NOT RPM_SPEC_BUILD_OUTPUT)
	    SET(RPM_SPEC_BUILD_OUTPUT
		"%cmake ${RPM_SPEC_CMAKE_FLAGS} .
make ${RPM_SPEC_MAKE_FLAGS}"
	    )
	ENDIF(NOT RPM_SPEC_BUILD_OUTPUT)

	## Install
	STRING_JOIN(PRJ_DOC_LIST " " ${FILE_INSTALL_PRJ_DOC_LIST})
	IF(NOT PRJ_DOC_LIST STREQUAL "")
	    SET(RPM_SPEC_PRJ_DOC_REMOVAL_OUTPUT 
		"# We install document using doc 
(cd %{buildroot}${DOC_DIR}/%{name}-%{version}
   rm -fr *
)"
	    )
	    RPM_SPEC_STRING_ADD(RPM_SPEC_FILES_SECTION_OUTPUT
		"%doc ${PRJ_DOC_LIST}"
	    )
	ENDIF(NOT PRJ_DOC_LIST STREQUAL "")

	IF(HAS_TRANSLATION)
	    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT
		"find_lang" "%{name}" "" FRONT
	    )
	    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_FILES_SECTION_OUTPUT
		"files" "-f %{name}.lang" "" FRONT
	    )
	ELSE(HAS_TRANSLATION)
	    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_FILES_SECTION_OUTPUT
		"files" "" "" FRONT
	    )
	ENDIF(HAS_TRANSLATION)

	PRJ_RPM_SPEC_PREPARE_FILES("BIN" "%{_bindir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("LIB" "%{_libdir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("PRJ_LIB" "%{_libdir}/%{name}/")
	PRJ_RPM_SPEC_PREPARE_FILES("LIBEXEC" "%{_libexecdir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("PRJ_LIBEXEC" "%{_libexecdir}/%{name}/")
	PRJ_RPM_SPEC_PREPARE_FILES("SYSCONF" "%config %{_sysconfdir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("PRJ_SYSCONF" "%config %{_sysconfdir}/%{name}/")
	PRJ_RPM_SPEC_PREPARE_FILES("SYSCONF_NO_REPLACE" "%config(noreplace) %{_sysconfdir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("PRJ_SYSCONF_NO_REPLACE" "%config(noreplace) %{_sysconfdir}/%{name}/")
	PRJ_RPM_SPEC_PREPARE_FILES("DATA" "%{_datadir}/")
	PRJ_RPM_SPEC_PREPARE_FILES("PRJ_DATA" "%{_datadir}/%{name}/")
    ENDMACRO(PRJ_RPM_SPEC_PREPARE)

    MACRO(PACK_RPM)
	IF(NOT _manage_rpm_dependency_missing )
	    SET(_validOptions "SPEC_IN" "SPEC")
	    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})

	    IF(NOT _opt_SPEC_IN)
		FIND_FILE_ERROR_HANDLING(_opt_SPEC_IN
		    ERROR_MSG " spec.in is not found"
		    VERBOSE_LEVEL ${M_ERROR}
		    NAMES "project.spec.in" "${PROJECT_NAME}.spec.in"
		    PATHS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR}
			${CMAKE_CURRENT_SOURCE_DIR}/SPECS
			${CMAKE_SOURCE_DIR}/SPECS
			${CMAKE_CURRENT_SOURCE_DIR}/rpm
			${CMAKE_SOURCE_DIR}/rpm
			${RPM_BUILD_SPECS}
			${CMAKE_ROOT_DIR}/Templates/fedora
		)
		SET(_opt_SPEC "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec")
	    ENDIF(NOT _opt_SPEC_IN)

	    IF(NOT _opt_SPEC)
		SET(_opt_SPEC "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec")
	    ENDIF(NOT _opt_SPEC)
	    ## RPM spec.in and RPM-ChangeLog.prev

	    PRJ_RPM_SPEC_PREPARE()
	    SET(PRJ_RPM_SPEC_FILE "${_opt_SPEC}" CACHE FILEPATH "spec")

	    SET(PRJ_SRPM_FILE "${RPM_BUILD_SRPMS}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.src.rpm"
		CACHE STRING "RPM files" FORCE)

	    SET(PRJ_RPM_FILES "${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.${RPM_BUILD_ARCH}.rpm"
		CACHE STRING "RPM files" FORCE)

	    INCLUDE(DateTimeFormat)
	    MANAGE_RPM_CHANGELOG()

	    # Generate spec
	    IF(NOT "${_opt_SPEC_IN}" STREQUAL "")
		CONFIGURE_FILE(${_opt_SPEC_IN} ${_opt_SPEC})
	    ENDIF(NOT "${_opt_SPEC_IN}" STREQUAL "")
	    #-------------------------------------------------------------------
	    # RPM build commands and targets

	    ADD_CUSTOM_TARGET_COMMAND(srpm
		OUTPUT ${PRJ_SRPM_FILE}
		COMMAND ${RPMBUILD_CMD} -bs ${PRJ_RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${PRJ_RPM_SPEC_FILE} ${SOURCE_ARCHIVE_FILE}
		COMMENT "Building srpm"
		)

	    # RPMs (except SRPM)

	    ADD_CUSTOM_TARGET_COMMAND(rpm
		OUTPUT ${PRJ_RPM_FILES}
		COMMAND ${RPMBUILD_CMD} -bb  ${PRJ_RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${PRJ_SRPM_FILE}
		COMMENT "Building rpm"
		)

	    ADD_CUSTOM_TARGET(install_rpms
		COMMAND find ${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}
		-name '${PROJECT_NAME}*-${PRJ_VER}-${RPM_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm' !
		-name '${PROJECT_NAME}-debuginfo-${RPM_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm'
		-print -exec sudo rpm --upgrade --hash --verbose '{}' '\\;'
		DEPENDS ${PRJ_RPM_FILES}
		COMMENT "Install all rpms except debuginfo"
		)

	    ADD_CUSTOM_TARGET(rpmlint
		COMMAND find .
		-name '${PROJECT_NAME}*-${PRJ_VER}-${RPM_RELEASE_NO}.*.rpm'
		-print -exec rpmlint -I '{}' '\\;'
		DEPENDS ${PRJ_SRPM_FILE} ${PRJ_RPM_FILES}
		)

	    ADD_CUSTOM_TARGET(clean_old_rpm
		COMMAND find .
		-name '${PROJECT_NAME}*.rpm' ! -name '${PROJECT_NAME}*-${PRJ_VER}-${RPM_RELEASE_NO}.*.rpm'
		-print -delete
		COMMAND find ${RPM_BUILD_BUILD}
		-path '${PROJECT_NAME}*' ! -path '${RPM_BUILD_BUILD}/${PROJECT_NAME}-${PRJ_VER}-*'
		-print -delete
		COMMENT "Cleaning old rpms and build."
		)

	    ADD_CUSTOM_TARGET(clean_old_pkg
		)

	    ADD_DEPENDENCIES(clean_old_pkg clean_old_rpm clean_old_pack_src)

	    ADD_CUSTOM_TARGET(clean_rpm
		COMMAND find . -name '${PROJECT_NAME}-*.rpm' -print -delete
		COMMENT "Cleaning rpms.."
		)
	    ADD_CUSTOM_TARGET(clean_pkg
		)

	    ADD_DEPENDENCIES(clean_rpm clean_old_rpm)
	    ADD_DEPENDENCIES(clean_pkg clean_rpm clean_pack_src)
	ENDIF(NOT _manage_rpm_dependency_missing )
    ENDMACRO(PACK_RPM)

    MACRO(RPM_MOCK_BUILD)
	IF(NOT _manage_rpm_dependency_missing )
	    FIND_PROGRAM(MOCK_CMD mock)
	    IF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
		M_MSG(${M_OFF} "mock is not found in PATH, mock support disabled.")
	    ELSE(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
		IF(NOT RPM_BUILD_ARCH STREQUAL "noarch")
		    IF(NOT DEFINED MOCK_RPM_DIST_TAG)
			STRING(REGEX MATCH "^fc([1-9][0-9]*)"  _fedora_mock_dist "${RPM_DIST_TAG}")
			STRING(REGEX MATCH "^el([1-9][0-9]*)"  _el_mock_dist "${RPM_DIST_TAG}")

			IF (_fedora_mock_dist)
			    STRING(REGEX REPLACE "^fc([1-9][0-9]*)" "fedora-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
			ELSEIF (_el_mock_dist)
			    STRING(REGEX REPLACE "^el([1-9][0-9]*)" "epel-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
			ELSE (_fedora_mock_dist)
			    SET(MOCK_RPM_DIST_TAG "fedora-devel")
			ENDIF(_fedora_mock_dist)
		    ENDIF(NOT DEFINED MOCK_RPM_DIST_TAG)

		    #MESSAGE ("MOCK_RPM_DIST_TAG=${MOCK_RPM_DIST_TAG}")
		    ADD_CUSTOM_TARGET(rpm_mock_i386
			COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/i386
			COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-i386" --resultdir="${RPM_BUILD_RPMS}/i386" ${PRJ_SRPM_FILE}
			DEPENDS ${PRJ_SRPM_FILE}
			)

		    ADD_CUSTOM_TARGET(rpm_mock_x86_64
			COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/x86_64
			COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-x86_64" --resultdir="${RPM_BUILD_RPMS}/x86_64" ${PRJ_SRPM_FILE}
			DEPENDS ${PRJ_SRPM_FILE}
			)
		ENDIF(NOT RPM_BUILD_ARCH STREQUAL "noarch")
	    ENDIF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
	ENDIF(NOT _manage_rpm_dependency_missing )

    ENDMACRO(RPM_MOCK_BUILD)

ENDIF(NOT DEFINED _MANAGE_RPM_CMAKE_)

