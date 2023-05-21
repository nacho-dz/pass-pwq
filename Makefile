PREFIX ?= /usr
DESTDIR ?=
LIBDIR ?= $(PREFIX)/lib
MANDIR ?= $(PREFIX)/local/share/man

all:
	@echo "pass-pwq is a shell script, so there is nothing to do. Try \"make install\" instead."

install:
	@install -v -d "$(DESTDIR)$(MANDIR)/man1"
	@install -m 0644 -v man/pass-pwq.1 "$(DESTDIR)$(MANDIR)/man1/pass-pwq.1"
	@install -v -d "$(DESTDIR)$(LIBDIR)/password-store/extensions"
	@install -m 0755 -v src/pwq.bash "$(DESTDIR)$(LIBDIR)/password-store/extensions/pwq.bash"

uninstall:
	@rm -vf \
		"$(DESTDIR)$(LIBDIR)/password-store/extensions/pwq.bash" \
		"$(DESTDIR)$(MANDIR)/man1/pass-pwq.1"

.PHONY: install uninstall
