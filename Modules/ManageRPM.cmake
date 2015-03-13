# - RPM generation, maintaining (remove old rpm) and verification (rpmlint).
# This module provides macros that provides various rpm building and
# verification targets.
#
# This module needs variables from ManageArchive, so
# INCLUDE(ManageArchive)
# before this module.
#
# Included Modules:
#   - ManageFile
#   - ManageTarget
#   - ManageVariable
#
# Reads and defines following variables:
#   - RPM_SPEC_CMAKE_FLAGS: cmake flags in RPM spec.
#   - RPM_SPEC_MAKE_FLAGS: "make flags in RPM spec.
#
# Reads and defines following variables if dependencies are satisfied:
#   - PRJ_RPM_SPEC_FILE: spec file for rpmbuild.
#   - RPM_SPEC_BUILD_ARCH: (optional) Set "BuildArch:"
#   - RPM_BUILD_ARCH: (optional) Arch that will be built."
#   - RPM_DIST_TAG: (optional) Current distribution tag such as el5, fc10.
#     Default: Distribution tag from rpm --showrc
#
#   - RPM_BUILD_TOPDIR: (optional) Directory of  the rpm topdir.
#     Default: ${CMAKE_BINARY_DIR}
#
#   - RPM_BUILD_SPECS: (optional) Directory of generated spec files
#       and RPM-ChangeLog.
#     Note this variable is not for locating SPEC template file
#       (i.e. project.spec.in). The SPEC template file should be
#       specified in PACK_RPM()
#     Default: ${RPM_BUILD_TOPDIR}/SPECS
#
#   - RPM_BUILD_SOURCES: (optional) Directory of source archive files.
#     Default: ${RPM_BUILD_TOPDIR}/SOURCES
#
#   - RPM_BUILD_SRPMS: (optional) Directory of source rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/SRPMS
#
#   - RPM_BUILD_RPMS: (optional) Directory of generated rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/RPMS
#
#   - RPM_BUILD_BUILD: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILD
#
#   - RPM_BUILD_BUILDROOT: (optional) Directory for RPM buildroot.
#     Default: ${RPM_BUILD_TOPDIR}/BUILDROOT
#
#   - RPM_RELEASE_NO: (optional) RPM release number.
#     Default: 1
#
# Defines following variables:
#   - RPM_IGNORE_FILES: A list of exclude file patterns for PackSource.
#     This value is appended to SOURCE_ARCHIVE_IGNORE_FILES after
#     including this module.
#
# Defines following Functions:
#   RPM_SPEC_STRING_ADD(<var> <str> [<position>])
#   - Add a string to SPEC string.
#     * Parameters:
#       + var: Variable that hold results in string format.
#       + str: String to be added.
#       + position: (Optional) position to put the tag. 
#       Valid value: FRONT for inserting in the beginning.
#       Default: Append in the end of string.
#       of string.
#
#   RPM_SPEC_STRING_ADD_DIRECTIVE <var> <directive> <attribute> <content>)
#   - Add a SPEC directive (e.g. %description -l zh_TW) to SPEC string.
#     * Parameters:
#       + var: Variable that hold results in string format.
#       + directive: Directive to be added.
#       + attribute: Attribute of tag. That is, string between '()'
#       + value: Value fot the tag.
#       + position: (Optional) position to put the tag. 
#         Valid value: FRONT for inserting in the beginning.
#         Default: Append in the end of string.
#
#   RPM_SPEC_STRING_ADD_TAG(<var> <tag> <attribute> <value> [<position>])
#   - Add a SPEC tag (e.g. BuildArch: noarch) to SPEC string.
#     * Parameters:
#       + var: Variable that hold results in string format.
#       + tag: Tag to be added.
#       + attribute: Attribute of tag. That is, string between '()'
#       + value: Value fot the tag.
#       + position: (Optional) position to put the tag. 
#         Valid value: FRONT for inserting in the beginning.
#         Default: Append in the end of string.
#
# Defines following Macros:
#   PACK_RPM([SPEC_IN <specInFile>] [SPEC <specFile>]
#       [CONFIG_REPLACE <file1> ...])
#     - Generate spec and pack rpm  according to the spec file.
#       * Parameters:
#         + SPEC_IN specInFile: RPM SPEC template file as .spec.in
#         + SPEC specFile: Output RPM SPEC file 
#           Default: ${RPM_BUILD_SPEC}/${PROJECT_NAME}.spec
#         + CONFIG_REPLACE <file1> ...: Configure file that should be
#             replaced after update. 
#           Example: 
#              CONFIG_REPLACE ${SYSCONF_DIR}/${PROJECT_NAME}.conf
#       * Targets:
#         + srpm: Build srpm (rpmbuild -bs).
#         + rpm: Build binary rpm (rpmbuild -bb)
#         + rpmlint: Run rpmlint to generated RPMs.
#         + install_rpm: Install all RPMs of this version,
#             excepts debug-info.
#         + clean_rpm: Clean all rpm and build files.
#         + clean_pkg": Clean all source packages, rpm and build files.
#         + clean_old_rpm: Remove old rpm and build files.
#         + clean_old_pkg: Remove old source packages and rpms.
#       * Variables defined:
#         + PRJ_RELEASE: Project release with distribution tags. 
#           (e.g. 1.fc13)
#         + RPM_RELEASE_NO: Project release number, without 
#           distribution tags. (e.g. 1)
#         + PRJ_SRPM_FILE: Path to generated SRPM file, including
#           relative path.
#         + PRJ_RPM_FILES: Binary RPM files to be build.
#
#   RPM_MOCK_BUILD([MOCK_CONFIG <mockConfig> ...])
#     - Add mock related targets.
#       * Parameters:
#         + MOCK_CONFIG mockConfig ... : Mock config name without .cfg.
#            (e.g. fedora-rawhide-i386, epel-7-x86_64)
#           Default: default
#       * Targets:
#         + rpm_mock_<mockConfig>: Build RPM with <mockConfig>.
#

IF(DEFINED _MANAGE_RPM_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_RPM_CMAKE_)
SET (_MANAGE_RPM_CMAKE_ "DEFINED")

INCLUDE(ManageFile)
INCLUDE(ManageTarget)
SET(_manage_rpm_dependency_missing 0)

# Variables to be passed for SPEC building
SET(RPM_SPEC_IN_VARIABLE_LIST
    "REQUIRES"
    "REQUIRES_PRE"
    "REQUIRES_PREUN"
    "REQUIRES_POST"
    "REQUIRES_POSTUN"
    "BUILD_REQUIRES"
    "RPM_SPEC_BUILD_OUTPUT"
    "RPM_SPEC_SUB_PACKAGE_OUTPUT"
    "RPM_SPEC_INSTALL_SECTION_OUTPUT"
    "RPM_SPEC_SCRIPT_OUTPUT"
    )

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

M_MSG(${M_INFO2} "CMAKE_FEDORA_SCRIPT_PATH_HINTS=${CMAKE_FEDORA_SCRIPT_PATH_HINTS}")

FIND_PROGRAM_ERROR_HANDLING(RPM_EXECUTABLE
    ERROR_MSG "ManageRPM: rpm not found, rpm build support is disabled."
    ERROR_VAR _manage_rpm_dependency_missing
    VERBOSE_LEVEL ${M_OFF}
    FIND_ARGS NAMES rpm
    )

FIND_PROGRAM_ERROR_HANDLING(RPMBUILD_CMD
    ERROR_MSG "ManageRPM: rpmbuild-md5 or rpmbuild not found, rpm build support is disabled."
    ERROR_VAR _manage_rpm_dependency_missing
    VERBOSE_LEVEL ${M_OFF}
    FIND_ARGS NAMES "rpmbuild-md5" "rpmbuild"
    )

FIND_PROGRAM_ERROR_HANDLING(CMAKE_FEDORA_KOJI_CMD
    ERROR_MSG "ManageRPM: cmake-fedora-koji not found, rpm build support is disabled."
    ERROR_VAR _manage_rpm_dependency_missing
    VERBOSE_LEVEL ${M_OFF}
    FIND_ARGS NAMES cmake-fedora-koji
    HINTS  ${CMAKE_FEDORA_SCRIPT_PATH_HINTS}
    )


IF(_manage_rpm_dependency_missing)
    RETURN()
ENDIF(_manage_rpm_dependency_missing)
INCLUDE(ManageVariable)
CMAKE_FEDORA_CONF_GET_ALL_VARIABLES()


## arch
IF(BUILD_ARCH STREQUAL "noarch")
    SET(RPM_BUILD_ARCH ${BUILD_ARCH})
ELSE(BUILD_ARCH STREQUAL "noarch")
    EXECUTE_PROCESS(COMMAND ${RPM_EXECUTABLE} -E "%{_arch}"
	COMMAND sed -e "s/^\\.//"
	OUTPUT_VARIABLE RPM_BUILD_ARCH
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
ENDIF(BUILD_ARCH STREQUAL "noarch")

## %{dist}
EXECUTE_PROCESS(COMMAND ${RPM_EXECUTABLE} -E "%{dist}"
    COMMAND sed -e "s/^\\.//"
    OUTPUT_VARIABLE _RPM_DIST_TAG
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
SET(RPM_DIST_TAG "${_RPM_DIST_TAG}" CACHE STRING "RPM Dist Tag")

SET(RPM_RELEASE_NO "1" CACHE STRING "RPM Release Number")

SET(RPM_BUILD_TOPDIR "${CMAKE_BINARY_DIR}" CACHE PATH "RPM topdir")

IF(SOURCE_ARCHIVE_DIR)
    SET(RPM_BUILD_SOURCES "${SOURCE_ARCHIVE_DIR}" CACHE PATH "RPM SOURCE dir")
ELSE()
    SET(RPM_BUILD_SOURCES "${RPM_BUILD_TOPDIR}/SOURCES" CACHE PATH "RPM SOURCE dir")
ENDIF()

SET(RPM_IGNORE_FILES "debug.*s.list")
FOREACH(_dir "SPECS" "SRPMS" "RPMS" "BUILD" "BUILDROOT")
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

MACRO(MANAGE_RPM_SPEC)
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
	    ${CMAKE_CURRENT_SOURCE_DIR}/cmake-fedora/Templates/fedora
	    )
    ENDIF(NOT _opt_SPEC_IN)

    IF(NOT _opt_SPEC)
    	SET(_opt_SPEC "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec")
    ENDIF(NOT _opt_SPEC)

    SET(INSTALL_MANIFESTS_FILE "${CMAKE_BINARY_DIR}/install_manifest.txt")
    ADD_CUSTOM_COMMAND(OUTPUT ${INSTALL_MANIFESTS_FILE}
	COMMAND cmake -Dcmd=make_manifests
	-Dmanifests=${INSTALL_MANIFESTS_FILE}
	-Dtmp_dir=${CMAKE_FEDORA_TMP_DIR}
	-P ${CMAKE_FEDORA_MODULE_DIR}/ManageRPMScript.cmake
	COMMENT "install_manifest.txt: ${INSTALL_MANIFESTS_FILE}"
	)

    FOREACH(v ${RPM_SPEC_IN_VARIABLE_LIST})
	PRJ_INFO_CMAKE_APPEND(${v})
    ENDFOREACH(v)

    SET(_specInOptList "")
    IF(_opt_CONFIG_REPLACE)
	LIST(APPEND _specInOptList "\"-Dconfig_replace=${_opt_CONFIG_REPLACE}\"")
    ENDIF(_opt_CONFIG_REPLACE)

    ADD_CUSTOM_TARGET_COMMAND(spec OUTPUT ${_opt_SPEC}
	COMMAND cmake -Dcmd=spec
            -Dspec=${_opt_SPEC}
            -Dspec_in=${_opt_SPEC_IN}
	    -Dmanifests=${INSTALL_MANIFESTS_FILE}
	    -Drelease=${RELEASE_NOTES_FILE}
	    -Dprj_info=${PRJ_INFO_CMAKE_FILE}
	    ${_specInOptList}
	    -P ${CMAKE_FEDORA_MODULE_DIR}/ManageRPMScript.cmake
	    DEPENDS ${_opt_SPEC_IN} ${RELEASE_NOTES_FILE}
	    ${INSTALL_MANIFESTS_FILE}
	    ${SOURCE_ARCHIVE_FILE}
	    COMMENT "spec: ${_opt_SPEC}"
	    )
ENDMACRO(MANAGE_RPM_SPEC)

MACRO(PACK_RPM)
    IF(_manage_rpm_dependency_missing)
	RETURN()
    ENDIF(_manage_rpm_dependency_missing)

    SET(_validOptions "SPEC_IN" "SPEC" "CONFIG_REPLACE")
    VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
    MANAGE_RPM_SPEC()

    SET(PRJ_SRPM_FILE "${RPM_BUILD_SRPMS}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.src.rpm"
	CACHE STRING "RPM files" FORCE)

    SET(PRJ_RPM_FILES "${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}/${PROJECT_NAME}-${PRJ_VER}-${RPM_RELEASE_NO}.${RPM_DIST_TAG}.${RPM_BUILD_ARCH}.rpm"
	CACHE STRING "Building RPM files" FORCE)

    #-------------------------------------------------------------------
    # RPM build commands and targets

    ADD_CUSTOM_TARGET_COMMAND(srpm
	NO_FORCE
	OUTPUT ${PRJ_SRPM_FILE}
	COMMAND ${RPMBUILD_CMD} -bs ${_opt_SPEC}
	--define '_sourcedir ${RPM_BUILD_SOURCES}'
	--define '_builddir ${RPM_BUILD_BUILD}'
	--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
	--define '_specdir ${RPM_BUILD_SPECS}'
	DEPENDS ${_opt_SPEC} ${SOURCE_ARCHIVE_FILE}
	COMMENT "srpm: ${PRJ_SRPM_FILE}"
	)
    ADD_DEPENDENCIES(srpm_no_force dist)
    ADD_DEPENDENCIES(srpm dist)

    # Binary RPMs
    ADD_CUSTOM_TARGET_COMMAND(rpm
	OUTPUT ${PRJ_RPM_FILES}
	NO_FORCE
	COMMAND ${RPMBUILD_CMD} --rebuild ${PRJ_SRPM_FILE}
	--define '_rpmdir ${RPM_BUILD_RPMS}'
	--define '_builddir ${RPM_BUILD_BUILD}'
	--define '_buildrootdir ${RPM_BUILD_BUILDROOT}'
	DEPENDS ${PRJ_SRPM_FILE}
	COMMENT "rpm: ${PRJ_RPM_FILES}"
	)
    ADD_DEPENDENCIES(rpm_no_force srpm_no_force)
    ADD_DEPENDENCIES(rpm srpm)

    ADD_CUSTOM_TARGET(install_rpms
	COMMAND find ${RPM_BUILD_RPMS}/${RPM_BUILD_ARCH}
	-name '${PROJECT_NAME}*-${PRJ_VER}-${RPM_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm' !
	-name '${PROJECT_NAME}-debuginfo-${RPM_RELEASE_NO}.*.${RPM_BUILD_ARCH}.rpm'
	-print -exec sudo rpm --upgrade --hash --verbose '{}' '\\;'
	COMMENT "install_rpm: Install all rpms except debuginfo"
	)
    ADD_DEPENDENCIES(install_rpms rpm_no_force)

    ADD_CUSTOM_TARGET(rpmlint
	COMMAND find .
	-name '${PROJECT_NAME}*-${PRJ_VER}-${RPM_RELEASE_NO}.*.rpm'
	| xargs rpmlint -i -v
	DEPENDS ${PRJ_SRPM_FILE} ${PRJ_RPM_FILES}
	COMMENT "rpmlint: ${PRJ_SRPM_FILE} ${PRJ_RPM_FILES}"
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
ENDMACRO(PACK_RPM)

MACRO(RPM_MOCK_BUILD)
    IF(_manage_rpm_dependency_missing)
	RETURN()
    ENDIF(_manage_rpm_dependency_missing)

    SET(_mock_missing 0)
    FIND_PROGRAM_ERROR_HANDLING(MOCK_CMD
	ERROR_MSG "mock not found, mock build support is disabled."
	ERROR_VAR _mock_missing
	VERBOSE_LEVEL ${M_OFF}
	FIND_ARGS NAMES mock
	)

    IF(_manage_rpm_dependency_missing)
	RETURN()
    ENDIF(_manage_rpm_dependency_missing)

    IF(_mock_missing)
	RETURN()
    ENDIF(_mock_missing)

    SET(_validOptions "MOCK_CONFIG")
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})

    IF("${_o_MOCK_CONFIG}" STREQUAL "")
	SET(_o_MOCK_CONFIG "default")
    ENDIF("${_o_MOCK_CONFIG}" STREQUAL "")

    FOREACH(_mName ${_o_MOCK_CONFIG})
	## Filter out mock config that does not exists
	## Figure out the actual config file (which has arch)
	GET_FILENAME_COMPONENT(_mCfg "/etc/mock/${_mName}.cfg" REALPATH)
	IF(EXISTS "${_mCfg}")
	    IF("${RPM_BUILD_ARCH}" STREQUAL "noarch")
		SET(_resultDir ${RPM_BUILD_RPMS}/noarch)
	    ELSEIF("${_mCfg}" MATCHES "-x86_64.cfg")
		SET(_resultDir ${RPM_BUILD_RPMS}/x86_64)
	    ELSEIF("${_mCfg}" MATCHES "-i386.cfg")
		SET(_resultDir ${RPM_BUILD_RPMS}/i386)
	    ELSE()
		M_MSG(${M_OFF} "RPM_MOCK_BUILD: ${_mCfg} is not supported yet.")
		SET(_resultDir "")
	    ENDIF("${RPM_BUILD_ARCH}" STREQUAL "noarch")
	    IF(NOT "${_resultDir}" STREQUAL "")
		ADD_CUSTOM_TARGET(rpm_mock_${_mName}
		    COMMAND ${CMAKE_COMMAND} -E make_directory ${_resultDir}
		    COMMAND ${MOCK_CMD} -r  "${_mName}" --resultdir="${_resultDir}" ${PRJ_SRPM_FILE}
		    DEPENDS ${PRJ_SRPM_FILE}
		    COMMENT "rpm_mock_${_mName}: ${PRJ_SRPM_FILE}"
		    )
	    ENDIF(NOT "${_resultDir}" STREQUAL "")
	ELSE(EXISTS "${_mCfg}")
	    M_MSG(${M_OFF} 
		"RPM_MOCK_BUILD: mock config ${_mCfg} does not exists"
		)
	ENDIF(EXISTS "${_mCfg}")
    ENDFOREACH(_mName)
ENDMACRO(RPM_MOCK_BUILD)

