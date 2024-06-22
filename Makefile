.POSIX:
.SUFFIXES:
HARE=hare
HAREFLAGS=

DESTDIR=
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

.PHONY: all
all: fi

.PHONY: fi
fi:
	$(HARE) build $(HAREFLAGS) -o $@ cmd/$@/

.PHONY: check
check:
	$(HARE) test $(HAREFLAGS)

.PHONY: clean
clean:
	rm -f example-cmd

.PHONY: install
install:
	install -Dm755 example-cmd $(DESTDIR)$(BINDIR)/example-cmd

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(BINDIR)/example-cmd
