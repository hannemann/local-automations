-include .env

ifndef TOPIC_AFFIX_MACHINE
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
	[ -f $$HOME/.local/etc/mqtt-broker.conf ] || install -m 700 -pD ./local/etc/mqtt-broker.conf $$HOME/.local/etc/mqtt-broker.conf
	[ -f $$HOME/.local/etc/desktop-lights-control.conf ] || install -m 700 -pD ./local/etc/desktop-lights-control.conf $$HOME/.local/etc/desktop-lights-control.conf
	[ -d $$HOME/.local/etc/desktop-lights-control.d ] || install -m 700 -pD ./local/etc/desktop-lights-control.d/games $$HOME/.local/etc/desktop-lights-control.d/games
	# systemd
	$(MAKE) mqtt-config
	/usr/bin/systemctl --user daemon-reload
	/usr/bin/systemctl --user enable --now desktop-lights-control.service
	/usr/bin/systemctl --user enable --now steam-remote.service

mqtt-config:
	sed -i "s|HOST=.*|HOST=${HOST}|" $$HOME/.local/etc/mqtt-broker.conf
	sed -i "s|USER=.*|USER=${USER}|" $$HOME/.local/etc/mqtt-broker.conf
	sed -i "s|PASS=.*|PASS=${PASS}|" $$HOME/.local/etc/mqtt-broker.conf
	sed -i "s|BIN_PUB=.*|BIN_PUB=${BIN_PUB}|" $$HOME/.local/etc/mqtt-broker.conf
	sed -i "s|BIN_SUB=.*|BIN_SUB=${BIN_SUB}|" $$HOME/.local/etc/mqtt-broker.conf
	sed -i "s|TOPIC_AFFIX_MACHINE=.*|TOPIC_AFFIX_MACHINE=${TOPIC_AFFIX_MACHINE}|" $$HOME/.local/etc/mqtt-broker.conf

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
