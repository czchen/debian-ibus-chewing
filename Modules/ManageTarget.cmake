# - Modules for managing targets and outputs.
#
# Includes:
#   ManageVariable
#
# Defines following macros:
#   ADD_CUSTOM_TARGET_COMMAND(target OUTPUT file1 [file2 ..]
#   [ALL] COMMAND
#   command1 ...)
#   - Combine ADD_CUSTOM_TARGET and ADD_CUSTOM_COMMAND.
#     Always build when making the target, also specify the output files
#     Arguments:
#     + target: target for this command
#     + file1, file2 ... : Files to be outputted by this command
#     + command1 ... : Command to be run. The rest arguments are same with
#                      ADD_CUSTOM_TARGET.
#

IF(NOT DEFINED _MANAGE_TARGET_CMAKE_)
    SET(_MANAGE_TARGET_CMAKE_ "DEFINED")
    INCLUDE(ManageVariable)
    MACRO(ADD_CUSTOM_TARGET_COMMAND target OUTPUT)
	SET(_validOptions "OUTPUT" "ALL" "COMMAND")
	VARIABLE_PARSE_ARGN(_opt _validOptions ${ARGN})
	IF(DEFINED _opt_ALL)
	    SET(_all "ALL")
	ELSE(DEFINED _opt_ALL)
	    SET(_all "")
	ENDIF(DEFINED _opt_ALL)

	ADD_CUSTOM_TARGET(${target} ${_all}
	    COMMAND ${_opt_COMMAND}
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_opt} 
	    COMMAND ${_opt_COMMAND}
	    )
    ENDMACRO(ADD_CUSTOM_TARGET_COMMAND)

ENDIF(NOT DEFINED _MANAGE_TARGET_CMAKE_)

