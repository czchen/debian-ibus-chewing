# - RPM generation, maintaining (remove old rpm) and verification (rpmlint).
# This module provides macros that provides various rpm building and
# verification targets.
#
# This module needs variable from ManageArchive, so INCLUDE(ManageArchive)
# before this module.
#
# Includes:
#   ManageMessage
#   ManageTarget
#
# Reads and defines following variables if dependencies are satisfied:
#   PRJ_RPM_SPEC_IN_FILE: spec.in that generate spec
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
#   PACK_RPM()
#   - Generate spec and pack rpm  according to the spec file.
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

    INCLUDE(ManageMessage)
    INCLUDE(ManageFile)
    INCLUDE(ManageTarget)
    SET(_manage_rpm_dependency_missing 0)

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

    FIND_FILE_ERROR_HANDLING(PRJ_RPM_SPEC_IN_FILE
	ERROR_MSG " rpm build support is disabled."
	ERROR_VAR _manage_rpm_dependency_missing
	VERBOSE_LEVEL ${M_OFF}
	NAMES "${PROJECT_NAME}.spec.in" "project.spec.in"
	PATHS "${CMAKE_CURRENT_SOURCE_DIR}/SPECS"
	"${CMAKE_SOURCE_DIR}/SPECS" "SPECS" "rpm" "."
	"${CMAKE_SOURCE_DIR}/Templates/fedora"
	"${CMAKE_ROOT}/Templates/fedora"
	)

    FIND_FILE_ERROR_HANDLING(RPM_CHANGELOG_PREV_FILE
	ERROR_MSG " rpm build support is disabled."
	ERROR_VAR _manage_rpm_dependency_missing
	VERBOSE_LEVEL ${M_OFF}
	NAMES RPM-ChangeLog.prev
	PATHS "${CMAKE_CURRENT_SOURCE_DIR}/SPECS"
	"${CMAKE_SOURCE_DIR}/SPECS" "SPECS" "rpm" "."
	)

    IF(NOT _manage_rpm_dependency_missing)
	INCLUDE(ManageVariable)

	SET (SPEC_FILE_WARNING "This file is generated, please modified the .spec.in file instead!")

	# %{dist}
	EXECUTE_PROCESS(COMMAND ${RPM_CMD} -E "%{dist}"
	    COMMAND sed -e "s/^\\.//"
	    OUTPUT_VARIABLE _RPM_DIST_TAG
	    OUTPUT_STRIP_TRAILING_WHITESPACE)
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

	## RPM spec.in and RPM-ChangeLog.prev
	SET(PRJ_RPM_SPEC_FILE "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec" CACHE FILEPATH "spec")

	SET(RPM_CHANGELOG_FILE "${RPM_BUILD_SPECS}/RPM-ChangeLog" CACHE FILEPATH "ChangeLog for RPM")

	# Add RPM build directories in ignore file list.
	LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES ${RPM_IGNORE_FILES})

    ENDIF(NOT _manage_rpm_dependency_missing)

    MACRO(PRJ_RPM_SPEC_DATA_PREPARE)
	SET(RPM_SPEC_CMAKE_FLAGS "-DCMAKE_FEDORA_ENABLE_FEDORA_BUILD=1"
	    CACHE STRING "CMake flags in RPM SPEC"
	    )

	SET(RPM_SPEC_MAKE_FLAGS "VERBOSE=1 %{?_smp_mflags}"
	    CACHE STRING "Make flags in RPM SPEC"
	    )
	# %{_build_arch}
	IF("${RPM_SPEC_BUILD_ARCH}" STREQUAL "")
	    EXECUTE_PROCESS(COMMAND ${RPM_CMD} -E "%{_build_arch}"
		OUTPUT_VARIABLE _RPM_BUILD_ARCH
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	    SET(RPM_BUILD_ARCH "${_RPM_BUILD_ARCH}" 
		CACHE STRING "RPM Arch")
	    SET(RPM_SPEC_BUILD_ARCH_OUTPUT "")
	ELSE("${RPM_SPEC_BUILD_ARCH}" STREQUAL "")
	    SET(RPM_BUILD_ARCH "${RPM_SPEC_BUILD_ARCH}" 
		CACHE STRING "RPM Arch")
	    SET(RPM_SPEC_BUILD_ARCH_OUTPUT 
		"BuildArch:  ${RPM_SPEC_BUILD_ARCH}")
	ENDIF("${RPM_SPEC_BUILD_ARCH}" STREQUAL "")

	SET(RPM_SPEC_SUMMARY_TRANSLATION_OUTPUT "")
	SET(_lang "")
	FOREACH(_sT ${SUMMARY_TRANSLATIONS})
	    IF(_lang STREQUAL "")
		SET(_lang "${_sT}")
	    ELSE(_lang STREQUAL "")
		STRING_APPEND(RPM_SPEC_SUMMARY_TRANSLATION_OUTPUT
		    "Summary(${_lang}): ${_sT}" "\n"
		    )
		SET(_lang "")
	    ENDIF(_lang STREQUAL "")
	ENDFOREACH(_sT ${SUMMARY_TRANSLATIONS})
	SET(RPM_SPEC_URL_OUTPUT ${URL_TEMPLATE})
	SET(RPM_SPEC_SOURCE0_OUTPUT ${SOURCE_DOWNLOAD_URL_TEMPLATE})
	
	SET(RPM_SPEC_BUILD_REQUIRES_OUTPUT "")
	FOREACH(_d ${BUILD_REQUIRES})
	    STRING_APPEND(RPM_SPEC_BUILD_REQUIRES_OUTPUT
		"BuildRequires:   ${_d}"  "\n"
		)
	ENDFOREACH(_d ${BUILD_REQUIRES})

	SET(RPM_SPEC_REQUIRES_OUTPUT "")
	FOREACH(_d ${REQUIRES})
	    STRING_APPEND(RPM_SPEC_REQUIRES_OUTPUT "Requires:   ${_d}" "\n")
	ENDFOREACH(_d ${REQUIRES})
	FOREACH(_d ${REQUIRES_PRE})
	    STRING_APPEND(RPM_SPEC_REQUIRES_PRE_OUTPUT 
		"Requires(pre):   ${_d}" "\n"
		)
	ENDFOREACH(_d ${REQUIRES_PRE})
	FOREACH(_d ${REQUIRES_PREUN})
	    STRING_APPEND(RPM_SPEC_REQUIRES_PREUN_OUTPUT 	
		"Requires(preun): ${_d}" "\n"
		)
	ENDFOREACH(_d ${REQUIRES_PREUN})
	FOREACH(_d ${REQUIRES_POST})
	    STRING_APPEND(RPM_SPEC_REQUIRES_POST_OUTPUT
		"Requires(preun): ${_d}" "\n"
		)
	ENDFOREACH(_d ${REQUIRES_POST})

	SET(RPM_SPEC_DESCRIPTION_TRANSLATION_OUTPUT "")
	SET(_lang "")
	FOREACH(_dT ${DESCRIPTION_TRANSLATIONS})
	    IF(_lang STREQUAL "")
		SET(_lang "${_dT}")
	    ELSE(_lang STREQUAL "")
		STRING_APPEND(RPM_SPEC_DESCRIPTION_TRANSLATION_OUTPUT
		    "%description -l ${_lang}" "\n"
		    )
		STRING_APPEND(RPM_SPEC_DESCRIPTION_TRANSLATION_OUTPUT
		    "${_dT}\n" "\n"
		    )
		SET(_lang "")
	    ENDIF(_lang STREQUAL "")
	ENDFOREACH(_dT ${DESCRIPTION_TRANSLATIONS})

	IF(HAS_TRANSLATION)
	    SET(RPM_SPEC_FIND_LANG_SECTION_OUTPUT "%find_lang %{name}")
	    SET(RPM_SPEC_FILES_SECTION_OUTPUT "%files -f %{name}.lang")
	ELSE(HAS_TRANSLATION)
	    SET(RPM_SPEC_FILES_SECTION_OUTPUT "%files")
	ENDIF(HAS_TRANSLATION)

	STRING_JOIN(PRJ_DOC_LIST " " ${FILE_INSTALL_PRJ_DOC_LIST})
	IF(NOT PRJ_DOC_LIST STREQUAL "")
	    SET(RPM_SPEC_PRJ_DOC_REMOVAL_OUTPUT 
		"# We install document using doc
(cd \$RPM_BUILD_ROOT${PRJ_DOC_DIR}
    rm -fr *
)"
		)
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%doc ${PRJ_DOC_LIST}" "\n"
		)
	ENDIF(NOT PRJ_DOC_LIST STREQUAL "")

	FOREACH(_f ${FILE_INSTALL_BIN_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_bindir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_BIN_LIST})

	FOREACH(_f ${FILE_INSTALL_LIB_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_libdir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_LIB_LIST})

	FOREACH(_f ${FILE_INSTALL_PRJ_LIB_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_libdir}/%{name}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_PRJ_LIB_LIST})

	FOREACH(_f ${FILE_INSTALL_LIBEXEC_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_libexecdir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_LIBEXEC_LIST})

	FOREACH(_f ${FILE_INSTALL_PRJ_LIBEXEC_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_libexecdir}/%{name}${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_PRJ_LIBEXEC_LIST})

	FOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%config %{_sysconfdir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_SYSCONF_LIST})

	FOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%config %{_sysconfdir}/%{name}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_LIST})

	FOREACH(_f ${FILE_INSTALL_SYSCONF_NO_REPLACE_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%config(noreplce) %{_sysconfdir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_SYSCONF_NO_REPLACE_LIST})

	FOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_NO_REPLACE_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%config(noreplce) %{_sysconfdir}/%{name}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_PRJ_SYSCONF_NO_REPLACE_LIST})

	FOREACH(_f ${FILE_INSTALL_DATA_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_datadir}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_DATA_LIST})

	FOREACH(_f ${FILE_INSTALL_PRJ_DATA_LIST})
	    STRING_APPEND(RPM_SPEC_FILES_SECTION_OUTPUT 
		"%{_datadir}/%{name}/${_f}" "\n"
		)
	ENDFOREACH(_f ${FILE_INSTALL_PRJ_DATA_LIST})
    ENDMACRO(PRJ_RPM_SPEC_DATA_PREPARE)

    MACRO(RPM_CHANGELOG_WRITE_FILE)
	INCLUDE(DateTimeFormat)

	FILE(WRITE ${RPM_CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}-${RPM_RELEASE_NO}\n")
	FILE(READ "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" CHANGELOG_ITEMS)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "${CHANGELOG_ITEMS}\n\n")

	# Update RPM_ChangeLog
	# Use this instead of FILE(READ is to avoid error when reading '\'
	# character.
	EXECUTE_PROCESS(COMMAND cat "${RPM_CHANGELOG_PREV_FILE}"
	    OUTPUT_VARIABLE RPM_CHANGELOG_PREV
	    OUTPUT_STRIP_TRAILING_WHITESPACE)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "${RPM_CHANGELOG_PREV}")

	ADD_CUSTOM_COMMAND(OUTPUT ${RPM_CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${CHANGELOG_FILE} ${RPM_CHANGELOG_PREV_FILE}
	    COMMENT "Write ${RPM_CHANGELOG_FILE}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(rpm_changelog_prev_update
	    COMMAND ${CMAKE_COMMAND} -E copy ${RPM_CHANGELOG_FILE} ${RPM_CHANGELOG_PREV_FILE}
	    DEPENDS ${RPM_CHANGELOG_FILE}
	    COMMENT "${RPM_CHANGELOG_FILE} are saving as ${RPM_CHANGELOG_PREV_FILE}"
	    )

	IF(TARGET after_release_commit_pre)
	    ADD_DEPENDENCIES(after_release_commit_pre rpm_changelog_prev_update)
	ENDIF(TARGET after_release_commit_pre)
    ENDMACRO(RPM_CHANGELOG_WRITE_FILE)

    MACRO(PACK_RPM)
	IF(NOT _manage_rpm_dependency_missing )
	    SET(PRJ_SRPM_FILE "${RPM_BUILD_SRPMS}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.src.rpm"
		CACHE STRING "RPM files" FORCE)

	    SET(PRJ_RPM_FILES "${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.${RPM_BUILD_ARCH}.rpm"
		CACHE STRING "RPM files" FORCE)

	    PRJ_RPM_SPEC_DATA_PREPARE()
   	    RPM_CHANGELOG_WRITE_FILE()

	    # Generate spec
	    CONFIGURE_FILE(${PRJ_RPM_SPEC_IN_FILE} ${PRJ_RPM_SPEC_FILE})
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
		-print -exec rpmlint '{}' '\\;'
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

