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
	# config
	[ -f /etc/ha-mqtt-broker.conf ] || sudo install -g ${USER} -m 640 -pD ./root/etc/ha-mqtt-broker.conf /etc/ha-mqtt-broker.conf
	[ -f $$HOME/.local/etc/desktop-lights-control.conf ] || install -m 700 -pD ./local/etc/desktop-lights-control.conf $$HOME/.local/etc/desktop-lights-control.conf
	[ -d $$HOME/.local/etc/desktop-lights-control.d ] || install -m 700 -pD ./local/etc/desktop-lights-control.d/games $$HOME/.local/etc/desktop-lights-control.d/games
	# systemd
	$(MAKE) mqtt-config
	/usr/bin/systemctl --user daemon-reload
	/usr/bin/systemctl --user enable --now desktop-lights-control.service
	/usr/bin/systemctl --user enable --now steam-remote.service
	$(MAKE) install-mqtt-online-status

mqtt-config:
	sudo sed -i "s|MQTT_HOST=.*|MQTT_HOST=${MQTT_HOST}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_USER=.*|MQTT_USER=${MQTT_USER}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_PASS=.*|MQTT_PASS=${MQTT_PASS}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_BIN_PUB=.*|MQTT_BIN_PUB=${MQTT_BIN_PUB}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_BIN_SUB=.*|MQTT_BIN_SUB=${MQTT_BIN_SUB}|" /etc/ha-mqtt-broker.conf
	sudo sed -i "s|MQTT_TOPIC_AFFIX_MACHINE=.*|MQTT_TOPIC_AFFIX_MACHINE=${MQTT_TOPIC_AFFIX_MACHINE}|" /etc/ha-mqtt-broker.conf

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
	$(MAKE) uninstall-mqtt-online-status
	sudo rm /etc/ha-mqtt-broker.conf

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

install-mqtt-online-status:
	sudo install -m 755 ./root/usr/local/bin/mqtt-online-status /usr/local/bin/mqtt-online-status
	sudo install -m 644 ./root/etc/systemd/system/mqtt-online-status.service /etc/systemd/system/mqtt-online-status.service
	sudo /usr/bin/systemctl enable --now mqtt-online-status.service

uninstall-mqtt-online-status:
	- sudo /usr/bin/systemctl disable --now g15daemon.service
	- sudo rm /etc/systemd/system/mqtt-online-status.service
	sudo /usr/bin/systemctl daemon-reload 
	sudo rm /usr/local/bin/mqtt-online-status

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
	sudo install -m 644 ./root/etc/systemd/system/g15daemon.service /etc/systemd/system/g15daemon.service
	sudo install -m 644 ./root/etc/systemd/system/g15daemon-suspend-resume.service /etc/systemd/system/g15daemon-suspend-resume.service
	sudo /usr/bin/systemctl daemon-reload 
	sudo /usr/bin/systemctl enable --now g15daemon.service
	sudo /usr/bin/systemctl enable --now g15daemon-suspend-resume.service
	install -m 644 ./g15daemon/Xmodmap $$HOME/.Xmodmap
	/usr/bin/xmodmap $$HOME/.Xmodmap

uninstall-g15daemon:
	- sudo /usr/bin/systemctl disable --now g15daemon.service
	- sudo /usr/bin/systemctl disable --now g15daemon-suspend-resume.service
	- sudo rm /etc/systemd/system/g15daemon.service
	- sudo rm /etc/systemd/system/g15daemon-suspend-resume.service
	sudo /usr/bin/systemctl daemon-reload 
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15.git
	cd $$HOME/src/libg15 && sudo make uninstall
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/libg15render.git
	cd $$HOME/src/libg15render && sudo make uninstall
	- cd $$HOME/src && /usr/bin/git clone git@github.com:hannemann/g15daemon.git
	cd $$HOME/src/g15daemon && sudo make uninstall

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
