PREFIX ?= /usr/local
DESTDIR ?=
LIBDIR ?= /usr/lib
SYSTEM_EXTENSION_DIR ?= $(LIBDIR)/password-store/extensions
MANDIR ?= $(PREFIX)/share/man

all:
	@echo "pass-pwq is a shell script, so there is nothing to do. Try \"make install\" instead."

install:
	@install -v -d "$(DESTDIR)$(MANDIR)/man1"
	@install -m 0644 -v man/pass-pwq.1 "$(DESTDIR)$(MANDIR)/man1/pass-pwq.1"
	@install -v -d "$(DESTDIR)$(SYSTEM_EXTENSION_DIR)"
	@install -m 0755 -v src/pwq.bash "$(DESTDIR)$(SYSTEM_EXTENSION_DIR)/pwq.bash"

uninstall:
	@rm -vf \
		"$(DESTDIR)$(SYSTEM_EXTENSION_DIR)/pwq.bash" \
		"$(DESTDIR)$(MANDIR)/man1/pass-pwq.1"

.PHONY: install uninstall
