
TARGET		= usb-creator-cli
INSTALL_DIR = $(PREFIX)/usr/local/bin

.PHONY: all install uninstall

all:

$(INSTALL_DIR):
	mkdir -p $(INSTALL_DIR)

$(INSTALL_DIR)/$(TARGET): $(INSTALL_DIR) $(TARGET).sh
	install $(TARGET).sh $(INSTALL_DIR)/$(TARGET)

install: $(INSTALL_DIR)/$(TARGET)

uninstall:
	rm -f $(INSTALL_DIR)/$(TARGET)
