-include .env

ifndef MQTT_TOPIC_AFFIX_MACHINE
$(error .env file not valid. invoke make prepare?)
endif

prepare:
	cp env.example .env
	@echo now edit your configuration in .env file

install:
	# install
	install -pD ./local/bin/* -t $$HOME/.local/bin/
	install -pD ./config/systemd/user/* -t $$HOME/.config/systemd/user/
	install -pD ./local/share/applications/* -t $$HOME/.local/share/applications/
	- cd $$HOME/src && /usr/bin/git clone --branch pipewire git@github.com:hannemann/pulse-scripts.git
	cd $$HOME/src/pulse-scripts && make install
	mkdir $$HOME/.launcher-extension
	ln -s $$HOME/.local/bin/desktop-session $$HOME/.launcher-extension/Desktop\ Session
	ln -s $$HOME/.local/bin/gaming-session $$HOME/.launcher-extension/Gaming\ Session
	# config
	[ -f /etc/ha-mqtt-broker.conf ] || sudo install -g ${USER} -m 640 -pD ./root/etc/ha-mqtt-broker.conf /etc/ha-mqtt-broker.conf
	[ -f $$HOME/.local/etc/desktop-lights-control.conf ] || install -m 700 -pD ./local/etc/desktop-lights-control.conf $$HOME/.local/etc/desktop-lights-control.conf
	[ -d $$HOME/.local/etc/desktop-lights-control.d ] || install -m 700 -pD ./local/etc/desktop-lights-control.d/* -t $$HOME/.local/etc/desktop-lights-control.d/
	install -m 640 -pD ./config/pulse-scripts/entities $$HOME/.config/pulse-scripts/entities
	$(MAKE) install-gnome-monitor-config
	$(MAKE) mqtt-config
	$(MAKE) install-mqtt-online-status
	# systemd
	/usr/bin/systemctl --user daemon-reload
	/usr/bin/systemctl --user enable --now desktop-lights-control.service
	/usr/bin/systemctl --user enable --now steam-remote.service
	# autostart
	install -m 644 -pD ./config/autostart/* -t $$HOME/.config/autostart

uninstall:
	- /usr/bin/systemctl --user disable --now desktop-lights-control.service
	- /usr/bin/systemctl --user disable --now steam-remote.service
	- /usr/bin/systemctl --user daemon-reload
	- cd ./config/systemd/user; find . -type f -exec rm $$HOME/.config/systemd/user/{} \;
	cd -
	- rmdir $$HOME/.config/systemd/user
	- rmdir $$HOME/.config/systemd
	- cd ./local/bin/; find . -type f -exec rm $$HOME/.local/bin/{} \;
	cd -
	- rmdir $$HOME/.local/bin
	$(MAKE) uninstall-gnome-monitor-config
	$(MAKE) uninstall-mqtt-online-status
	sudo rm /etc/ha-mqtt-broker.conf
	cd $$HOME/src/pulse-scripts && make uninstall
	- cd ./config/autostart; find . -type f -exec rm $$HOME/.config/autostart/{} \;
	cd -
	- cd ./local/share/applications; find . -type f -exec rm $$HOME/.local/share/applications/{} \;
	cd -
	rm -r $$HOME/.launcher-extension/Desktop\ Session
	rm -r $$HOME/.launcher-extension/Gaming\ Session
	- rmdir $$HOME/.launcher-extension

prune:
	$(MAKE) uninstall
	- cd ./local/etc/desktop-lights-control.d/; find . -type f -exec rm $$HOME/.local/etc/desktop-lights-control.d/{} \;
	cd -
	- cd ./local/etc; find . -type f -exec rm $$HOME/.local/etc/{} \;
	cd -
	- rmdir $$HOME/.local/etc/desktop-lights-control.d
	- rmdir $$HOME/.local/etc

restart:
	/usr/bin/systemctl --user restart desktop-lights-control.service
	/usr/bin/systemctl --user restart steam-remote.service
	sudo /usr/bin/systemctl restart mqtt-online-status.service

mqtt-config:
	sudo sed -i "s|MQTT_HOST=.*|MQTT_HOST=${MQTT_HOST}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_USER=.*|MQTT_USER=${MQTT_USER}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_PASS=.*|MQTT_PASS=${MQTT_PASS}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_BIN_PUB=.*|MQTT_BIN_PUB=${MQTT_BIN_PUB}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_BIN_SUB=.*|MQTT_BIN_SUB=${MQTT_BIN_SUB}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_TOPIC_AFFIX_MACHINE=.*|MQTT_TOPIC_AFFIX_MACHINE=${MQTT_TOPIC_AFFIX_MACHINE}|" /etc/ha-mqtt-broker.conf

install-mqtt-online-status:
	sudo install -m 755 -pD ./root/usr/local/bin/mqtt-online-status /usr/local/bin/mqtt-online-status
	sudo install -m 644 -pD ./root/etc/systemd/system/mqtt-online-status.service /etc/systemd/system/mqtt-online-status.service
	sudo /usr/bin/systemctl enable --now mqtt-online-status.service

uninstall-mqtt-online-status:
	- sudo /usr/bin/systemctl disable --now mqtt-online-status.service
	- sudo rm /etc/systemd/system/mqtt-online-status.service
	sudo /usr/bin/systemctl daemon-reload 
	sudo rm /usr/local/bin/mqtt-online-status

install-gnome-monitor-config:
	sudo zypper in cairo-devel
	- cd $$HOME/src && /usr/bin/git clone https://github.com/jadahl/gnome-monitor-config.git
	cd $$HOME/src/gnome-monitor-config && git pull
	cd $$HOME/src/gnome-monitor-config && meson build
	cd $$HOME/src/gnome-monitor-config/build && meson compile
	sudo install -m 755 $$HOME/src/gnome-monitor-config/build/src/gnome-monitor-config /usr/local/bin

uninstall-gnome-monitor-config:
	sudo rm /usr/local/bin/gnome-monitor-config
	rm -rf $$HOME/src/gnome-monitor-config

build-g15daemon:
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15.git
	cd $$HOME/src/libg15 && git pull && ./configure && make clean && make
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15render.git
	cd $$HOME/src/libg15render && git pull && ./configure && make clean && make
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon.git
	cd $$HOME/src/g15daemon && git pull && autoreconf --force --install && ./configure && make clean && make

install-g15daemon:
	cd $$HOME/src/libg15 && sudo make install
	cd $$HOME/src/libg15render && sudo make install
	cd $$HOME/src/g15daemon && sudo make install
	sudo install -m 644 -pD ./root/etc/systemd/system/g15daemon.service /etc/systemd/system/g15daemon.service
	sudo /usr/bin/systemctl daemon-reload 
	sudo /usr/bin/systemctl enable --now g15daemon.service
	install -m 644 ./g15daemon/Xmodmap $$HOME/.Xmodmap
	# next line does not work... left here for reference
	/usr/bin/xmodmap $$HOME/.Xmodmap

uninstall-g15daemon:
	- sudo /usr/bin/systemctl disable --now g15daemon.service
	- sudo rm /etc/systemd/system/g15daemon.service
	sudo /usr/bin/systemctl daemon-reload 
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15.git
	cd $$HOME/src/libg15 && sudo make uninstall
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15render.git
	cd $$HOME/src/libg15render && sudo make uninstall
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon.git
	cd $$HOME/src/g15daemon && sudo make uninstall
	rm $$HOME/.Xmodmap

install-g15stats:
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon-addons.git
	cd $$HOME/src/g15daemon-addons && git pull
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && autoupdate 
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && ./autogen.sh 
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && ./configure 
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && && make && sudo make install 

uninstall-g15stats:
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon-addons.git
	cd $$HOME/src/g15daemon-addons && git pull
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && autoupdate
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && ./autogen.sh
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && ./configure
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15stats && sudo make uninstall

install-g15-utils:
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon-addons.git
	cd $$HOME/src/g15daemon-addons && git pull
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && autoupdate
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && ./autogen.sh
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && ./configure
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && make && sudo make install

uninstall-g15-utils:
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon-addons.git
	cd $$HOME/src/g15daemon-addons && git pull
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && autoupdate
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && ./autogen.sh
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && ./configure
	cd $$HOME/src/g15daemon-addons/g15daemon-clients/g15-utils && sudo make uninstall

install-sleep-inhibitor:
	sudo install -m 644 -pD ./root/etc/systemd/system/sleep-inhibitor.service /etc/systemd/system/sleep-inhibitor.service
	sudo install -m 755 -pD ./root/usr/local/bin/sleep-inhibitor /usr/local/bin/sleep-inhibitor
	sudo install -pD ./root/etc/sleep-inhibitor/sleep-inhibitor.d/* -t /etc/sleep-inhibitor/sleep-inhibitor.d/
	sudo /usr/bin/systemctl daemon-reload
	sudo /usr/bin/systemctl enable --now sleep-inhibitor.service

uninstall-sleep-inhibitor:
	sudo /usr/bin/systemctl disable --now sleep-inhibitor.service
	sudo rm /etc/systemd/system/sleep-inhibitor.service
	sudo rm /usr/local/bin/sleep-inhibitor
	sudo /usr/bin/systemctl daemon-reload

reinstall-sleep-inhibitor:
	$(MAKE) uninstall-sleep-inhibitor
	$(MAKE) install-sleep-inhibitor