# - Provide uninstall target.
# Use this module to provide uninstall target.
#
# Included Modules:
#   - ManageMessage
#   - ManageFile
#
# Define following targets
#   uninstall: For uninstalling the package.
#

IF(DEFINED _MANAGE_UNINSTALL_CMAKE_)
    RETURN()
ENDIF(DEFINED _MANAGE_UNINSTALL_CMAKE_)
SET(_MANAGE_UNINSTALL_CMAKE_ "DEFINED")

SET(CMAKE_UNINSTALL_IN_SEARCH_PATH 
    ${CMAKE_MODULE_PATH} ${CMAKE_ROOT}/Modules ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/Modules
    )

INCLUDE(ManageFile)
FIND_FILE_ERROR_HANDLING(CMAKE_UNINSTALL_IN
    FIND_ARGS cmake_uninstall.cmake.in PATHS ${CMAKE_UNINSTALL_IN_SEARCH_PATH}
    )

CONFIGURE_FILE("${CMAKE_UNINSTALL_IN}"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

ADD_CUSTOM_TARGET(uninstall
    "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    )

