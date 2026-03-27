INSTALL_NAME=webcam-cfg
INSTALL_PATH=/usr/local/bin

LOCAL_NAME=webcam-cfg.sh
LOCAL_PATH=scripts

UDEV_CONFIG_SCRIPT=udev-cfg.sh

.PHONY: install
install:
	@sudo cp config/*.json /etc
	@sudo install -m 755 $(LOCAL_PATH)/$(LOCAL_NAME) $(INSTALL_PATH)/$(INSTALL_NAME)
	@sudo bash $(LOCAL_PATH)/$(UDEV_CONFIG_SCRIPT)

.PHONY: uninstall
uninstall:
	@sudo rm -f $(INSTALL_PATH)/$(INSTALL_NAME)
