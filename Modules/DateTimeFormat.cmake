# - Date/time format module.
#
# Define the following variables:
#   - TODAY_CHANGELOG: Today in the format that is used in RPM Changelog.
#      e.g. Wed 08 Aug 2010
#   - TODAY_SHORT: Short presentation of today, e.g. 20100818.
#
# Defines the following macros:
#    TODAY(<date_var> <format> [<locale>])
#      - Get date of today in specified format and locale.
#        * Parameters:
#     	   + date_var: Result date string
#          + format: date format for date(1)
#          + locale: locale of the string.
#            Use current locale setting if locale is not given.
#
#

IF(DEFINED _DATE_TIME_FORMAT_CMAKE_)
    RETURN()
ENDIF(DEFINED _DATE_TIME_FORMAT_CMAKE_)
SET(_DATE_TIME_FORMAT_CMAKE_ "DEFINED")

FUNCTION(TODAY date_var format)
    SET(_locale ${ARGV2})
    IF(_locale)
	SET(ENV{LC_ALL} ${_locale})
    ENDIF(_locale)
    EXECUTE_PROCESS(COMMAND date -u "${format}"
	OUTPUT_VARIABLE _ret
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    SET(${date_var} "${_ret}" PARENT_SCOPE)
ENDFUNCTION(TODAY date_var format)

TODAY(TODAY_CHANGELOG "+%a %b %d %Y" "C")
TODAY(TODAY_SHORT "+%Y%m%d" "C")

