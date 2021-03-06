SET(RPM_BUILD_TOPDIR "${CMAKE_BINARY_DIR}/rpm" CACHE FILEPATH "RPM top dir")
SET(RPM_BUILD_SOURCES "${SOURCE_ARCHIVE_DIR}" CACHE FILEPATH "RPM Source dir")
INCLUDE(ManageRPM)
INCLUDE(ManageReleaseFedora)

#RPM_SPEC_STRING_ADD(RPM_SPEC_BUILD_OUTPUT "make VERBOSE=1 translations")

IF(NOT "${IBUS_VERSION}" VERSION_LESS "1.5.3")
    # IBus supports write cache since 1.5.3
    SET(RPM_SPEC_IBUS_WRITE_CACHE "[ -x %{_bindir}/ibus ] && %{_bindir}/ibus write-cache --system &>/dev/null || :")
    SET(RPM_SPEC_POST_COMMON "${RPM_SPEC_IBUS_WRITE_CACHE}")
    SET(RPM_SPEC_POSTUN_COMMON "${RPM_SPEC_IBUS_WRITE_CACHE}")
ELSE()
    SET(RPM_SPEC_POST_COMMON "")
    SET(RPM_SPEC_POSTUN_COMMON "")
ENDIF()


IF(GSETTINGS_SUPPORT)
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT post ""
	"if [ $1 -eq 0 ] ; then
    /usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :
fi
        ${RPM_SPEC_POST_COMMON}
"
	)

    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT postun ""
	"/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :
        ${RPM_SPEC_POSTUN_COMMON}
"
	)
ENDIF()

IF(GCONF2_SUPPORT)
    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT pre ""
	"if [ \"$1\" -gt 1 ] ; then
    export GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source`
    [ -r %{_sysconfdir}/gconf/schemas/%{name}.schemas ] &&
    gconftool-2 --makefile-uninstall-rule %{_sysconfdir}/gconf/schemas/%{name}.schemas >/dev/null || :

   # Upgrading 1.0.2.20090302-1.fc11 or older?
   [ -r %{_sysconfdir}/gconf/schemas/%{name}.schema ] &&
   gconftool-2 --makefile-uninstall-rule %{_sysconfdir}/gconf/schemas/%{name}.schema >/dev/null || :
fi
"
	)

    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT preun ""
	"if [ \"$1\" -eq 0 ] ; then
    export GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source`
    gconftool-2 --makefile-uninstall-rule %{_sysconfdir}/gconf/schemas/%{name}.schemas > /dev/null || :
fi
"
	)

    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT post ""
	"export GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source`
    gconftool-2 --makefile-install-rule %{_sysconfdir}/gconf/schemas/%{name}.schemas > /dev/null || :
    ${RPM_SPEC_POST_COMMON}
"
	)

    RPM_SPEC_STRING_ADD_DIRECTIVE(RPM_SPEC_SCRIPT_OUTPUT postun ""
	"[ -x %{_bindir}/ibus ] && %{_bindir}/ibus write-cache --system &>/dev/null || :
	${RPM_SPEC_POSTUN_COMMON}
"
	)
ENDIF()

ADD_CUSTOM_COMMAND(OUTPUT ${SOURCE_ARCHIVE_FILE}
    COMMAND make pack_src
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

PACK_RPM()
RELEASE_FEDORA(fedora)
# "Off" Warning is displayed if mock is not installed.
RPM_MOCK_BUILD()

