ACLOCAL_AMFLAGS = -I m4

SYSTEMD_DIR = $(DESTDIR)$(sysconfdir)/systemd/system

do_subst = sed -e 's,[@]datadir[@],$(datadir),g' \
	   -e 's,[@]localstatedir[@],$(localstatedir),g' \
	   -e 's,[@]sysconfdir[@],$(sysconfdir),g' \
	   -e 's,[@]ZAP_LIBPATH[@],$(ZAP_LIBPATH),g' \
	   -e 's,[@]sbindir[@],$(sbindir),g' \
	   -e 's,[@]bindir[@],$(bindir),g' 

EXTRA_DIST = balerd.service.in

SERVICE_FILES = $(builddir)/balerd.service

# rules to generate service file
$(builddir)/%.service: $(srcdir)/%.service.in
	$(do_subst) < $< > $@

install-data-local: $(SERVICE_FILES)
	$(MKDIR_P) $(SYSTEMD_DIR)
	$(INSTALL_DATA) $(SERVICE_FILES) $(SYSTEMD_DIR)/

uninstall-local:
	rm -f $(SYSTEMD_DIR)/baler.service
