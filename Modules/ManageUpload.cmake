# - Upload files to hosting services.
# You can either use sftp, scp or supply custom command for upload.
#
# This module defines following macros:
#   MANAGE_UPLOAD_TARGET(targetName 
#     [COMMAND program ...] [ADD_CUSTOM_TARGET_ARGUMENTS])
#   - Make an upload target using arbitrary command.
#     This macro check whether the program after COMMAND exist,
#     if program exists, then add the make target,
#     if not, produce M_OFF warning.
#     Parameters:
#     + targetName: target name in make.
#     + program: Program that does upload.
#     + ADD_CUSTOM_TARGET_ARGUMENTS: Other ADD_CUSTOM_TARGET_ARGUMENTS
#
#   MANAGE_UPLOAD_SCP(targetName 
#     [USER user] [HOST_URL url] [UPLOAD_FILES files]
#     [REMOTE_DIR dir] [OPTIONS options] [DEPENDS files]
#     [COMMENT comments])
#   - Make an upload target using scp.
#     This macro check whether scp exist,
#     if program exists, then add the make target, if not, produce M_OFF warning.
#     Parameters:
#     + targetName: target name in make.
#     + USER user: scp user. Note that if USER is used but user is not defined.
#       It produces M_OFF warning.
#     + HOST_URL url: scp server.
#     + UPLOAD_FILES: Files to be uploaded. This will be in DEPENDS list.
#     + REMOTE_DIR dir: Directory on the server.
#     + OPTIONS options: scp options.
#     + DEPENDS files: other files that should be in DEPENDS list.
#     + COMMENT comments: Comment to be shown when building the target.
#
#   MANAGE_UPLOAD_SFTP(targetName 
#     [BATCH batchFile] [USER user] [HOST_URL url] [UPLOAD_FILES files]
#     [REMOTE_DIR dir] [OPTIONS options] [DEPENDS files]
#     [COMMENT comments])
#   - Make an upload target using sftp.
#     This macro check whether sftp exist,
#     if program exists, then add the make target, if not, produce M_OFF warning.
#     Parameters:
#     + targetName: target name in make.
#     + BATCH batchFile to be used in sftp. (sftp -b )
#     + USER user: sftp user. Note that if USER is used but user is not defined.
#       It produces M_OFF warning.
#     + HOST_URL url: sftp server.
#     + UPLOAD_FILES: Files to be uploaded. This will be in DEPENDS list.
#     + REMOTE_DIR dir: Directory on the server.
#     + OPTIONS options: sftp options.
#     + DEPENDS files: other files that should be in DEPENDS list.
#     + COMMENT comments: Comment to be shown when building the target.
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

IF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)
    SET(_MANAGE_UPLOAD_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageVariable)

    FUNCTION(MANAGE_UPLOAD_TARGET targetName)
	SET(_cmd "")
	SET(_state "")
	FOREACH(_arg ${ARGN})
	    IF (_arg STREQUAL "COMMAND")
		SET(_state "cmd")
	    ELSE(_arg STREQUAL "COMMAND")
		IF (_state STREQUAL "cmd")
		    SET(_cmd "${_arg}")
		    BREAK()
		ENDIF(_state STREQUAL "cmd")
	    ENDIF(_arg STREQUAL "COMMAND")
	ENDFOREACH(_arg ${ARGN})
	SET(_upload_target_missing_dependency 0)
	FIND_PROGRAM_ERROR_HANDLING(UPLOAD_CMD
	    ERROR_MSG " Upload target ${targetName} disabled."
	    ERROR_VAR _upload_target_missing_dependency
	    VERBOSE_LEVEL ${M_OFF}
	    "${_cmd}"
        )
        IF(NOT _upload_target_missing_dependency)
	    ADD_CUSTOM_TARGET(${targetName}
		${ARGN}
		)
	ENDIF(NOT _upload_target_missing_dependency)
    ENDFUNCTION(MANAGE_UPLOAD_TARGET targetName)

    MACRO(_MANAGE_UPLOAD_MAKE_URL var)
	SET(${var} ${_opt_HOST_URL})

	IF(NOT "${_opt_USER}" STREQUAL "")
	    SET(${var} "${_opt_USER}@${${var}}")
	ENDIF(NOT "${_opt_USER}" STREQUAL "")

	IF(NOT "${_opt_REMOTE_DIR}" STREQUAL "")
	    SET(${var} "${${var}}:${_opt_REMOTE_DIR}")
	ENDIF(NOT "${_opt_REMOTE_DIR}" STREQUAL "")
    ENDMACRO(_MANAGE_UPLOAD_MAKE_URL var)

    FUNCTION(MANAGE_UPLOAD_SCP targetName)
	SET(_validOptions  "USER" "HOST_URL" "UPLOAD_FILES" "REMOTE_DIR" "OPTIONS" "DEPENDS" "COMMENT")
	VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
	IF("${_opt_HOST_URL}" STREQUAL "")
	    M_MSG(${M_ERROR} "HOST_URL is required.")
	ENDIF("${_opt_HOST_URL}" STREQUAL "")
	IF("${_opt_UPLOAD_FILES}" STREQUAL "")
	    M_MSG(${M_ERROR} "UPLOAD_FILES is required.")
	ENDIF("${_opt_UPLOAD_FILES}" STREQUAL "")
	_MANAGE_UPLOAD_MAKE_URL(_uploadUrl)

	IF("${_opt_COMMENT}" STREQUAL "")
	    SET(_comment "${targetName}: Uploading to ${_uploadUrl}")
	ELSE("${_opt_COMMENT}" STREQUAL "")
	    SET(_comment "${_opt_COMMENT}")
	ENDIF("${_opt_COMMENT}" STREQUAL "")

	MANAGE_UPLOAD_TARGET(${targetName}
	    COMMAND scp ${_opt_OPTIONS} ${_opt_UPLOAD_FILES} ${_uploadUrl}
	    DEPENDS ${_opt_UPLOAD_FILES} ${_opt_DEPENDS}
	    COMMENT ${_comment}
	    VERBATIM
	    )
    ENDFUNCTION(MANAGE_UPLOAD_SCP fileAlias)

    FUNCTION(MANAGE_UPLOAD_SFTP targetName)
	SET(_validOptions  "USER" "HOST_URL" "UPLOAD_FILES" "REMOTE_DIR" "OPTIONS" "DEPENDS" "COMMENT" "BATCH")
	VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
	IF("${_opt_HOST_URL}" STREQUAL "")
	    M_MSG(${M_ERROR} "HOST_URL is required.")
	ENDIF("${_opt_HOST_URL}" STREQUAL "")
	IF("${_opt_UPLOAD_FILES}" STREQUAL "")
	    M_MSG(${M_ERROR} "UPLOAD_FILES is required.")
	ENDIF("${_opt_UPLOAD_FILES}" STREQUAL "")
	_MANAGE_UPLOAD_MAKE_URL(_uploadUrl)

	IF("${_opt_COMMENT}" STREQUAL "")
	    SET(_comment "${targetName}: Uploading to ${_uploadUrl}")
	ELSE("${_opt_COMMENT}" STREQUAL "")
	    SET(_comment "${_opt_COMMENT}")
	ENDIF("${_opt_COMMENT}" STREQUAL "")

	IF(NOT "${_opt_BATCH}" STREQUAL "")
	    SET(_batch "-b" "${_opt_BATCH}")
	ENDIF(NOT "${_opt_BATCH}" STREQUAL "")

	MANAGE_UPLOAD_TARGET(${targetName}
	    COMMAND sftp ${_batch} ${_opt_OPTIONS} ${_opt_UPLOAD_FILES} ${_uploadUrl}
	    DEPENDS ${_opt_UPLOAD_FILES} ${_opt_DEPENDS}
	    COMMENT ${_comment}
	    VERBATIM
	    )
    ENDFUNCTION(MANAGE_UPLOAD_SFTP fileAlias)

    #MACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)
    #	FIND_PROGRAM(CURL_CMD curl)
    #	IF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #	    MESSAGE(FATAL_ERROR "Need curl to perform google upload")
    #	ENDIF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #ENDMACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)
    FUNCTION(MANAGE_UPLOAD_FEDORAHOSTED targetName)
	MANAGE_UPLOAD_SCP(${targetName} 
	    HOST_URL "fedorahosted.org" REMOTE_DIR  "${PROJECT_NAME}"
	    ${ARGN})
    ENDFUNCTION(MANAGE_UPLOAD_FEDORAHOSTED fileAlias)

    FUNCTION(MANAGE_UPLOAD_SOURCEFORGE targetName)
       	MANAGE_UPLOAD_SFTP(${targetName} 
	    HOST_URL "frs.sourceforge.net" 
	    REMOTE_DIR  "/home/frs/project/${PROJECT_NAME}"
	    ${ARGN})
    ENDFUNCTION(MANAGE_UPLOAD_SOURCEFORGE fileAlias)
ENDIF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)

