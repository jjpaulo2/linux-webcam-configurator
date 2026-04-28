WEBCAM_SCRIPT=webcam-cfg
UDEV_SCRIPT=udev-cfg

INSTALL_BIN_PATH=/usr/local/bin
LOCAL_BIN_PATH=scripts

INSTALL_CONF_PATH=/etc
LOCAL_CONF_PATH=config


.PHONY: install
install:
	@echo -e "[+] Copying configuration files to $(INSTALL_CONF_PATH)\n"
	@find ./$(LOCAL_CONF_PATH) -type f -name "*.json"
	@sudo cp $(LOCAL_CONF_PATH)/*.json $(INSTALL_CONF_PATH)

	@echo -e "\n[+] Installing $(LOCAL_BIN_PATH) to $(INSTALL_BIN_PATH)\n"
	@find ./$(LOCAL_BIN_PATH) -type f -name "*.sh"
	@sudo install -m 755 $(LOCAL_BIN_PATH)/$(WEBCAM_SCRIPT).sh $(INSTALL_BIN_PATH)/$(WEBCAM_SCRIPT)
	@sudo install -m 755 $(LOCAL_BIN_PATH)/$(UDEV_SCRIPT).sh $(INSTALL_BIN_PATH)/$(UDEV_SCRIPT)
	
	@echo -e "\n[+] Done!\n"
	@echo -e "To enable the udev rules, just run:\nsudo $(UDEV_SCRIPT)"

.PHONY: uninstall
uninstall:
	@echo -e "[+] Uninstalling $(WEBCAM_SCRIPT)..."
	@sudo rm -f $(INSTALL_BIN_PATH)/$(WEBCAM_SCRIPT)
	@echo -e "[+] Uninstalling $(UDEV_SCRIPT)..."
	@sudo rm -f $(INSTALL_BIN_PATH)/$(UDEV_SCRIPT)
	@echo -e "[+] Done!"
