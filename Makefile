
.PHONY: help

# Shell that make should use
# Make changes to path persistent
# https://stackoverflow.com/a/13468229/13577666
SHELL := /bin/bash
PATH := $(PATH)

# Ubuntu distro string
OS_VERSION_NAME := $(shell lsb_release -cs)

HOSTNAME = $(shell hostname)

# This next section is needed to ensure $$HOME is on PATH in the initial shell session
# The file from bash scripts/before_script_path_fix.sh
# is only loaded in a new shell session.
LOCAL_BIN = $(shell echo $$HOME/.local/bin)
# $(warning LOCAL_BIN is $(LOCAL_BIN))

# Source for conditional: https://stackoverflow.com/a/2741747/13577666
ifneq (,$(findstring $(LOCAL_BIN),$(PATH)))
	# Found: all set; do nothing, $(LOCAL_BIN) is on PATH
	PATH := $(PATH);
else
	# Not found: adding $(LOCAL_BIN) to PATH for this shell session
export PATH := $(LOCAL_BIN):$(PATH); @echo $(PATH)
endif

# Allows user to specify private hostname in ".inventory file"
PRIVATE_INVENTORY = ".inventory"
ifeq ($(shell test -e $(PRIVATE_INVENTORY) && echo -n yes),yes)
	INVENTORY=$(PRIVATE_INVENTORY)
else
    INVENTORY = "inventory"
endif

# Format is from https://github.com/iancleary/ansible-role-zsh_antibody
USER_STRING = '{"users": [{"username": "$(shell whoami)", "skip_zshrc": true}]}'

# Main Ansible Playbook Command (prompts for password)
INSTALL_ANSIBLE_ROLES = ansible-galaxy install -r requirements.yml
ANSIBLE_PLAYBOOK = ansible-playbook desktop.yml -v -i $(INVENTORY) -l $(HOSTNAME) -e $(USER_STRING)

ANSIBLE=$(INSTALL_ANSIBLE_ROLES) && $(ANSIBLE_PLAYBOOK) --ask-become-pass

# Custom GNOME keybindings
CUSTOM_KEYBINDING_BASE = /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

help:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# adds anything that has a double # comment to the phony help list
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ".:*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


setup_inventory_and_group_vars:
setup_inventory_and_group_vars:
	# Ensure chosen hostname is present in group_vars and .inventory folder
	bash scripts/setup_inventory_and_group_vars.sh

bootstrap-before-install:
bootstrap-before-install:
	# Apt Dependencies (removes apt ansible)
	bash scripts/before_install_apt_dependencies.sh

bootstrap-install:
bootstrap-install:
	# Python3 Dependencies (install python3 ansible)
	bash scripts/install_p3_deps.sh

bootstrap-before-script:
bootstrap-before-script:
	# Ensure "$$HOME/.local/bin" is part of PATH on future shell sessions
	# The top of the Makefile takes care of this in the initial session
	bash scripts/before_script_path_fix.sh

bootstrap: setup_inventory_and_group_vars bootstrap-before-install bootstrap-before-script
bootstrap: ## Installs dependencies needed to run playbook

check: DARGS?=
check: ## Checks personal-computer.yml playbook
	@$(ANSIBLE) --check

install: DARGS?=
install: ## Installs everything via personal-computer.yml playbook
	@$(ANSIBLE) --skip-tags="ticktick, nautilus-mounts"
	# ticktick doesn't work on fresh install for some reason
	# no planned test coverage to nautilus-mounts as it deals with file mounts

all: ## Does most everything with Ansible and Make targets
all: bootstrap install non-ansible

non-ansible:
non-ansible: ## Runs all non-ansible make targets for fresh install (all target)

	# No user input required
	make flameshot-keybindings
apt:
apt: ## Install apt
	@$(ANSIBLE) --tags="apt"

zsh:
zsh: ## Install zsh and oh-my-zsh
	@$(ANSIBLE) --tags="zsh"

yadm:
yadm: ## Install yadm dotfile manager
	@$(ANSIBLE) --tags="yadm"

docker:
docker: ## Install Docker and Docker-Compose
	@$(ANSIBLE) --tags="docker"

#jetbrains-mono:
#jetbrains-mono: ## Install JetBrains Mono font
#	@$(ANSIBLE) --tags="jetbrains-mono"

common-snaps:
common-snaps: ## Install Common Snaps
	@$(ANSIBLE) --tags="common-snaps"

chat-clients:
chat-clients: ## Install Chat Client Snaps
	@$(ANSIBLE) --tags="chat-clients"

development-tools:
development-tools:
	@$(ANSIBLE) --tags="development-tools"

web-browsers:
web-browsers: ## Installs web-browsers as snaps
	@$(ANSIBLE) --tags="web-browsers"

peek:
peek: ## Install Peek (GIF Screen Recorder) using a Flatpak
	@$(ANSIBLE) --tags="flatpak" -e '{"flatpak_applications": ["com.uploadedlobster.peek"]}'

timeshift:
timeshift: ## Install Timeshift (Backup Utility) using a PPA and apt
	@$(ANSIBLE) --tags="timeshift"

flameshot:
flameshot: ## Install Flameshot 0.6.0 Screenshot Tool and Create Custom GNOME Keybindings
	@$(ANSIBLE) --tags="flameshot"

gsettings-keybindings:
gsettings-keybindings:  ## Sets GNOME custom keybindings

	gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$(CUSTOM_KEYBINDING_BASE)/flameshot/','$(CUSTOM_KEYBINDING_BASE)/hyper/']"

flameshot-keybindings: ## Flameshot custon GNOME keybindings
flameshot-keybindings: gsettings-keybindings
	# For whatever reason, I bricked my GNOME session trying this with ansible
	# so for now, I'm just going to chain this to the new machine script
	# and leave it as a make target

	# Update gnome keybindings
	# source: https://askubuntu.com/a/1116076

	gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "[]"
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ name 'flameshot'
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ command '/usr/bin/flameshot gui'
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ binding 'Print'

github-cli:
github-cli: ## Install GitHub CLI deb, directly from GitHub Release
	@$(ANSIBLE) --tags="github-cli"

# gnome-boxes:
# gnome-boxes: ## Install GNOME Boxes, using Flatpak
# 	@$(ANSIBLE) --tags="flatpak,gnome-boxes"

gnome-dash-to-dock:
gnome-dash-to-dock: ## Set my GNOME Dash to Dock Preferences
	@$(ANSIBLE) --tags="gnome-dash-to-dock"

gnome-extensions:
gnome-extensions: ## Install GNOME Extensions
	@$(ANSIBLE) --tags="gnome-extensions"

gnome-keybindings:
gnome-keybindings: ## Set my GNOME Keybindings Preferences
	@$(ANSIBLE) --tags="gnome-keybindings"

gnome-preferences:
gnome-preferences: ## Set my general GNOME shell Preferences
	@$(ANSIBLE) --tags="gnome-preferences"

gtk3-icon-browser: ## Launch the GTK Icon Browser
gtk3-icon-browser:
	# https://askubuntu.com/questions/695796/view-list-of-all-available-unique-icons-with-their-names-and-thumbnail/695958
	# sudo apt-get install -y gtk-3-examples
	# Installs in gnome-preferences role
	@gtk3-icon-browser &

stacer:
stacer: ## Install Stacer (Material System Utility)
	@$(ANSIBLE) --tags="stacer"

ulauncher:
ulauncher: ## Install ULauncher App Launcher (CTRL+spacebar)
	@$(ANSIBLE) --tags="ulauncher"

.DEFAULT_GOAL := help
