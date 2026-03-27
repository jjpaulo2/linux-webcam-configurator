INSTALL_NAME=webcam-cfg
INSTALL_PATH=/usr/local/bin

LOCAL_NAME=configure.sh
LOCAL_PATH=scripts

.PHONY: install
install:
	@sudo install -m 755 $(LOCAL_PATH)/$(LOCAL_NAME) $(INSTALL_PATH)/$(INSTALL_NAME)

.PHONY: uninstall
uninstall:
	@sudo rm -f $(INSTALL_PATH)/$(INSTALL_NAME)
