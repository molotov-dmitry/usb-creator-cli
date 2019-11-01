
BINDIR=$(PREFIX)/usr/local/bin

.PHONY: all install uninstall

all:

$(BINDIR):
	mkdir -p $(BINDIR)

$(BINDIR)/usb-creator-cli: $(BINDIR) usb-creator-cli.sh
	install usb-creator-cli.sh $(BINDIR)/usb-creator-cli

install: $(BINDIR)/usb-creator-cli

uninstall:
	rm -f $(BINDIR)/usb-creator-cli
