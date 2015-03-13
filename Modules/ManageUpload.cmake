# - Manage upload source archive to hosting site
# cmake-fedora can upload source archive to hosting site by
# scp, sftp or any other command.
#
# Included Modules:
#   - ManageMessage
#   - ManageVariable
#
# This module defines following functions:
#   MANAGE_UPLOAD_TARGET(<targetName> 
#       COMMAND <program> ... 
#       [COMMENT <comment>]
#       [ADD_CUSTOM_TARGET_ARGS <arg> ...]
#     )
#     - Make an upload target using arbitrary command.
#       If COMMAND program exists the target <targetName> will be created;
#       if not, a M_OFF message is shown and target will not be created.
#       * Parameters:
#         + targetName: target for use this command.
#         + COMMAND program ... : Upload command and arguments
#         + COMMENT comment (Optional) Comment when target is being built.
#           Default: "<targetName>: Upload with <program> ..."
#         + ADD_CUSTOM_TARGET_ARGS <arg> ...: (Optional) Other arguments to be 
#             passed to ADD_CUSTOM_TARGET.
#       * Targets:
#         + <targetName>
#
#   MANAGE_UPLOAD_SCP(<targetName> 
#       HOST_URL <url>
#       [USER <user>]  [UPLOAD_FILES <file> ...] [DEPENDS <file> ...]
#       [REMOTE_DIR <dir>] [OPTIONS <options>]
#       [COMMENT <comment>]
#       [ADD_CUSTOM_TARGET_ARGS <arg> ...]
#     )
#     - Make an upload target using scp. 
#       This functions check whether scp exists, see MANAGE_UPLOAD_TARGET 
#       for detailed behavior.
#       * Parameters:
#         + targetName: target for use this command.
#         + HOST_URL url: scp server.
#         + USER user: (Optional) scp user.
#           Default: Environment variable $USER.
#         + UPLOAD_FILES file ... : (Optional) Files to be uploaded.
#             This will also tell cmake the build to those files,
#             thus, <targetName> depends on those files.
#           Default: ${SOURCE_ARCHIVE_FILE}
#         + DEPENDS file ...: (Optional) Files that <targetName> should depends on,
#             but no need to upload.
#         + REMOTE_DIR dir: (Optional) Directory on the server.
#         + OPTIONS options: (Optional) scp options.
#         + COMMENT comment (Optional) Comment when target is being built.
#           Default: "<targetName>: Upload with scp [<options>] user@url:dir/file1 ..."
#         + ADD_CUSTOM_TARGET_ARGS <arg> ...: (Optional) Other arguments to be 
#             passed to ADD_CUSTOM_TARGET.
#       * Targets:
#         + <targetName>
#
#   MANAGE_UPLOAD_SFTP(<targetName> 
#       HOST_URL <url>
#       [BATCH <batchFile>]
#       [USER <user>] [UPLOAD_FILES <file> ...] [DEPENDS <file> ...]
#       [REMOTE_DIR <dir>] [OPTIONS <options>]
#       [COMMENT <comment>]
#       [ADD_CUSTOM_TARGET_ARGS <arg> ...]
#     )
#     - Make an upload target using sftp. 
#       This functions check whether sftp exists, see MANAGE_UPLOAD_TARGET 
#       for detailed behavior.
#       * Parameters:
#         + targetName: target for use this command.
#         + HOST_URL url: sftp server.
#         + BATCH batchFile: (Optional) File of sftp batch command.
#             If not specified, a batch file will be generated at 
#             ${CMAKE_CURRENT_BINARY_DIR}/<targetName>-sftp-batch
#         + USER user: (Optional) sftp user.
#           Default: Environment variable $USER.
#         + UPLOAD_FILES file ... : (Optional) Files to be uploaded.
#             This will also tell cmake the build to those files,
#             thus, <targetName> depends on those files.
#           Default: ${SOURCE_ARCHIVE_FILE}
#         + DEPENDS file ...: (Optional) Files that <targetName> should depends on,
#             but no need to upload.
#         + REMOTE_DIR dir: (Optional) Directory on the server.
#         + OPTIONS options: (Optional) sftp options.
#         + COMMENT comment (Optional) Comment when target is being built.
#           Default: "<targetName>: Upload with sftp [<options>] user@url/dir/file1 ..."
#         + ADD_CUSTOM_TARGET_ARGS <arg> ...: (Optional) Other arguments to be 
#             passed to ADD_CUSTOM_TARGET.
#       * Targets:
#         + <targetName>
#
#
#   MANAGE_UPLOAD_FEDORAHOSTED(<targetName> 
#       [USER <user>]  [UPLOAD_FILES <file> ...] [DEPENDS <file> ...]
#       [OPTIONS <options>]
#       [COMMENT <comment>]
#       [ADD_CUSTOM_TARGET_ARGS <arg> ...]
#     )
#     - Make an upload target to fedora hosted.
#       This functions check whether scp exists, see MANAGE_UPLOAD_TARGET 
#       for detailed behavior.
#       * Parameters:
#         + targetName: target for use this command.
#         + USER user: (Optional) scp user.
#           Default: Environment variable $USER.
#         + UPLOAD_FILES file ... : (Optional) Files to be uploaded.
#             This will also tell cmake the build to those files,
#             thus, <targetName> depends on those files.
#           Default: ${SOURCE_ARCHIVE_FILE}
#         + DEPENDS file ...: (Optional) Files that <targetName> should depends on,
#             but no need to upload.
#         + OPTIONS options: (Optional) scp options.
#         + COMMENT comment (Optional) Comment when target is being built.
#           Default: "<targetName>: Upload with scp [<options>] user@url:dir/file1 ..."
#         + ADD_CUSTOM_TARGET_ARGS <arg> ...: (Optional) Other arguments to be 
#             passed to ADD_CUSTOM_TARGET.
#       * Targets:
#         + <targetName>
#
#   MANAGE_UPLOAD_SOURCEFORGE(<targetName> 
#       [BATCH <batchFile>]
#       [USER <user>] [UPLOAD_FILES <file> ...] [DEPENDS <file> ...]
#       [OPTIONS <options>]
#       [COMMENT <comment>]
#       [ADD_CUSTOM_TARGET_ARGS <arg> ...]
#     )
#     - Make an upload target using sftp. 
#       This functions check whether sftp exists, see MANAGE_UPLOAD_TARGET 
#       for detailed behavior.
#       * Parameters:
#         + targetName: target for use this command.
#         + BATCH batchFile: (Optional) File of sftp batch command.
#             If not specified, a batch file will be generated at 
#             ${CMAKE_CURRENT_BINARY_DIR}/<targetName>-sftp-batch
#         + USER user: (Optional) sftp user.
#           Default: Environment variable $USER.
#         + UPLOAD_FILES file ... : (Optional) Files to be uploaded.
#             This will also tell cmake the build to those files,
#             thus, <targetName> depends on those files.
#           Default: ${SOURCE_ARCHIVE_FILE}
#         + DEPENDS file ...: (Optional) Files that <targetName> should depends on,
#             but no need to upload.
#         + OPTIONS options: (Optional) sftp options.
#         + COMMENT comment (Optional) Comment when target is being built.
#           Default: "<targetName>: Upload with sftp [<options>] user@url/dir/file1 ..."
#         + ADD_CUSTOM_TARGET_ARGS <arg> ...: (Optional) Other arguments to be 
#             passed to ADD_CUSTOM_TARGET.
#       * Targets:
#         + <targetName>
#
#   MANAGE_UPLOAD_FEDORAHOSTED(targetName 
#     [USER user] [UPLOAD_FILES files] [OPTIONS options] [DEPENDS files]
#     [COMMENT comments])
#   - Make an upload target for uploading to FedoraHosted.
#     Parameters:
#     + targetName: target name in make.
#     + USER user: scp user. Note that if USER is used but user is not defined.
#       It produces M_OFF warning.
#     + UPLOAD_FILES: Files to be uploaded. This will be in DEPENDS list.
#     + OPTIONS options: scp options.
#     + DEPENDS files: other files that should be in DEPENDS list.
#     + COMMENT comments: Comment to be shown when building the target.
#
#   MANAGE_UPLOAD_SOURCEFORGE(targetName [BATCH batchFile] 
#     [USER user] [UPLOAD_FILES files] [OPTIONS options] [DEPENDS files]
#     [COMMENT comments])
#     [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make an upload target for uploading to SourceForge
#     Parameters:
#     + targetName: target name in make.
#     + BATCH batchFile to be used in sftp. (sftp -b )
#     + USER user: sftp user. Note that if USER is used but user is not defined.
#       It produces M_OFF warning.
#     + UPLOAD_FILES: Files to be uploaded. This will be in DEPENDS list.
#     + OPTIONS options: sftp options.
#     + DEPENDS files: other files that should be in DEPENDS list.
#     + COMMENT comments: Comment to be shown when building the target.
#
#

IF(DEFINED _MANAGE_UPLOAD_CMAKE_)
    RETURN()
ENDIF()
SET(_MANAGE_UPLOAD_CMAKE_ "DEFINED")

INCLUDE(ManageMessage)
INCLUDE(ManageString)
INCLUDE(ManageVariable)

FUNCTION(MANAGE_UPLOAD_TARGET targetName)
    SET(_validOptions "COMMAND" "COMMENT" "ADD_CUSTOM_TARGET_ARGS")
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})

    LIST(GET _o_COMMAND 0 _cmd)
    FIND_PROGRAM_ERROR_HANDLING(${targetName}_UPLOAD_EXECUTABLE
	ERROR_MSG " Upload target ${targetName} disabled."
	ERROR_VAR _upload_target_missing_dependency
	VERBOSE_LEVEL ${M_OFF}
	"${_cmd}"
	)

    IF("${_o_COMMENT}" STREQUAL "")
	SET(_o "${targetName}: Upload with ${_o_COMMAND}")
    ENDIF()

    IF(NOT _upload_target_missing_dependency)
	ADD_CUSTOM_TARGET(${targetName}
	    COMMAND ${_o_COMMAND}
	    COMMENT "${_o_COMMENT}"
	    ${_o_ADD_CUSTOM_TARGET_ARGS}
	    )
    ENDIF()
ENDFUNCTION(MANAGE_UPLOAD_TARGET targetName)

## Internal
FUNCTION(MANAGE_UPLOAD_MAKE_URL var user url)
    IF(NOT "${user}" STREQUAL "")
	SET(_str "${user}@${url}")
    ELSE()
	SET(_str "${url}")
    ENDIF()
    SET(${var} "${_str}" PARENT_SCOPE)
ENDFUNCTION(MANAGE_UPLOAD_MAKE_URL)


FUNCTION(MANAGE_UPLOAD_SCP targetName)
    SET(_validOptions "HOST_URL" "USER" 
	"UPLOAD_FILES" "DEPENDS" "REMOTE_DIR" "OPTIONS" "COMMENT"
	"ADD_CUSTOM_TARGET_ARGS"
	)
    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})

    IF("${_o_HOST_URL}" STREQUAL "")
        M_MSG(${M_ERROR} "HOST_URL is required.")
    ENDIF()

    IF("${_o_UPLOAD_FILES}" STREQUAL "")
	SET(_o_UPLOAD_FILES "${SOURCE_ARCHIVE_FILE}")
    ENDIF()

    MANAGE_UPLOAD_MAKE_URL(_uploadUrl "${_o_USER}" "${_o_HOST_URL}")
    IF(NOT "${_o_REMOTE_DIR}" STREQUAL "")
	STRING_APPEND(_uploadUrl ":${_o_REMOTE_DIR}")
    ENDIF()

    IF("${_o_COMMENT}" STREQUAL "")
	SET(_o "${targetName}: Upload with scp ${_o_OPTIONS} ${_o_UPLOAD_FILES} ${_uploadUrl}")
    ENDIF()

    MANAGE_UPLOAD_TARGET(${targetName}
	COMMAND scp ${_o_OPTIONS} ${_o_UPLOAD_FILES} ${_uploadUrl}
	DEPENDS ${_o_UPLOAD_FILES} ${_o_DEPENDS}
	COMMENT "${_o_COMMENTS}"
	ADD_CUSTOM_TARGET_ARGS VERBATIM ${_o_ADD_CUSTOM_TARGET_ARGS}
	)
ENDFUNCTION(MANAGE_UPLOAD_SCP fileAlias)

FUNCTION(MANAGE_UPLOAD_SFTP targetName)
    SET(_validOptions "HOST_URL" "USER" 
	"BATCH"
	"UPLOAD_FILES" "DEPENDS" "REMOTE_DIR" "OPTIONS" "COMMENT"
	"ADD_CUSTOM_TARGET_ARGS"
	)

    VARIABLE_PARSE_ARGN(_o _validOptions ${ARGN})

    IF("${_o_HOST_URL}" STREQUAL "")
	M_MSG(${M_ERROR} "HOST_URL is required.")
    ENDIF()

    IF("${_o_UPLOAD_FILES}" STREQUAL "")
	SET(_o_UPLOAD_FILES "${SOURCE_ARCHIVE_FILE}")
    ENDIF()

    MANAGE_UPLOAD_MAKE_URL(_uploadUrl "${_o_USER}" "${_o_HOST_URL}")

    ## Generate batch
    IF("${_o_BATCH}" STREQUAL "")
	SET(_o_BATCH "${CMAKE_CURRENT_BINARY_DIR}/${targetName}-sftp-batch")
	FILE(WRITE "${_o_BATCH}" "pwd\n")
	FOREACH(_f ${_o_UPLOAD_FILES})
	    FILE(APPEND "${_o_BATCH}" "put -p ${_f} ${_o_REMOTE_DIR}\n")
	ENDFOREACH()
	FILE(APPEND "${_o_BATCH}" "bye\n")
    ENDIF()

    IF("${_o_COMMENT}" STREQUAL "")
	SET(_o "${targetName}: Upload with scp ${_o_OPTIONS} ${_o_UPLOAD_FILES} ${_uploadUrl}")
    ENDIF()

    MANAGE_UPLOAD_TARGET(${targetName}
	COMMAND sftp -b ${_o_BATCH} ${_o_OPTIONS} ${_uploadUrl}
	DEPENDS ${_o_UPLOAD_FILES} ${_o_DEPENDS}
	COMMENT "${_o_COMMENTS}"
	ADD_CUSTOM_TARGET_ARGS VERBATIM ${_o_ADD_CUSTOM_TARGET_ARGS}
	)
ENDFUNCTION(MANAGE_UPLOAD_SFTP targetName)

FUNCTION(MANAGE_UPLOAD_FEDORAHOSTED targetName)
    MANAGE_UPLOAD_SCP(${targetName} 
	HOST_URL "fedorahosted.org" REMOTE_DIR "${PROJECT_NAME}" ${ARGN}
	)
ENDFUNCTION(MANAGE_UPLOAD_FEDORAHOSTED)

FUNCTION(MANAGE_UPLOAD_SOURCEFORGE targetName)
    MANAGE_UPLOAD_SFTP(${targetName} 
	HOST_URL "frs.sourceforge.net" 
	REMOTE_DIR  "/home/frs/project/${PROJECT_NAME}"	${ARGN}
	)
ENDFUNCTION(MANAGE_UPLOAD_SOURCEFORGE)

