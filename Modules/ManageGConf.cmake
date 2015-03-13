# - GConf relative targets such as install/unstall schemas.
# This module finds gconftool-2 or gconftool for GConf manipulation.
#
# Defines the following macros:
#   MANAGE_GCONF_SCHEMAS([FILE <schemasFile>] 
#       [INSTALL_DIR <dir>] [CONFIG_SOURCE <source>]
#     )
#     - Process schemas file.
#       * Parameters:
#         + FILE <schemasFile>: (Optional) Path to GConf .schema.
#           Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.schemas
#         + INSTALL_DIR <dir>: (Optional) Directory to install GConf .schemas file.
#	    Default: ${SYSCONF_DIR}/gconf/schemas
#         + CONFIG_SOURCE <source>: (Optional) Configuration source.
#           Default: "" (Use the system default) 
#       * Variables to cache:
#         + GCONF2_PKG_CONFIG: GConf2 pkg-config name
#           Default: gconf-2.0
#         + GCONF2_DEVEL_PACKAGE_NAME: GConf2 devel package name
#           Default: GConf2-devel
#       * Defines following targets:
#         + install_schemas: install schemas.
#         + uninstall_schemas: uninstall schemas.
#

IF(DEFINED _MANAGE_GCONF_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_GCONF_CMAKE_)
SET(_MANAGE_GCONF_CMAKE_ DEFINED)
INCLUDE(ManageDependency)
SET(GCONF2_PKG_CONFIG "gconf-2.0" CACHE STRING "GConf2 pkg-config name")
SET(GCONF2_PACKAGE_NAME "GConf2" CACHE STRING "GConf2 package name")
SET(GCONF2_DEVEL_PACKAGE_NAME "GConf2-devel" CACHE STRING "GConf2 devel package name")
MANAGE_DEPENDENCY(REQUIRES GCONF2 REQUIRED PACKAGE_NAME "GConf2")
MANAGE_DEPENDENCY(BUILD_REQUIRES GCONF2 REQUIRED 
    PKG_CONFIG ${GCONF2_PKG_CONFIG} PACKAGE_NAME "${GCONF2_DEVEL_PACKAGE_NAME}"
    )
MANAGE_DEPENDENCY(REQUIRES_PRE GCONF2 REQUIRED 
    PACKAGE_NAME "${GCONF2_PACKAGE_NAME}"
    )
MANAGE_DEPENDENCY(REQUIRES_PREUN GCONF2 REQUIRED 
    PACKAGE_NAME "${GCONF2_PACKAGE_NAME}"
    )
MANAGE_DEPENDENCY(REQUIRES_POST GCONF2 REQUIRED 
    PACKAGE_NAME "${GCONF2_PACKAGE_NAME}"
    )

SET(MANAGE_GCONF_SCHEMAS_VALID_OPTIONS "FILE" "INSTALL_DIR" "CONFIG_SOURCE")
FUNCTION(MANAGE_GCONF_SCHEMAS)
    INCLUDE(ManageVersion)
    VARIABLE_PARSE_ARGN(_o MANAGE_GCONF_SCHEMAS_VALID_OPTIONS ${ARGN})

    IF(NOT _o_FILE)
	SET(_o_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.schemas")
    ENDIF()

    GET_FILENAME_COMPONENT(schemasBasename ${_o_FILE} NAME)

    IF(NOT _o_INSTALL_DIR)
	SET(_o_INSTALL_DIR  "${SYSCONF_DIR}/gconf/schemas")
    ENDIF()


    ADD_CUSTOM_TARGET(uninstall_schemas
	COMMAND GCONF_CONFIG_SOURCE=${_o_CONFIG_SOURCE}
	${GCONF2_EXECUTABLE} --makefile-uninstall-rule
	"${_o_INSTALL_DIR}/${schemasBasename}"
	COMMENT "uninstall_schemas"
	VERBATIM
	)

    ADD_CUSTOM_TARGET(install_schemas
	COMMAND ${CMAKE_COMMAND} -E copy "${_o_FILE}" "${_o_INSTALL_DIR}/${schemasBasename}"
	COMMAND GCONF_CONFIG_SOURCE=${GCONF_CONFIG_SOURCE}
	${GCONF2_EXECUTABLE} --makefile-install-rule
	"${_o_INSTALL_DIR}/${schemasBasename}"
	DEPENDS "${_o_FILE}"
	COMMENT "install_schemas"
	VERBATIM
	)

    INSTALL(FILES ${_o_FILE} DESTINATION "${SYSCONF_DIR}/gconf/schemas")
ENDFUNCTION(MANAGE_GCONF_SCHEMAS)

