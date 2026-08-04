# Quartz build & packaging.
#
#   make linux        # build daemon + UI, produce .deb and .rpm in dist/
#   make deb / rpm    # one format
#   make from-source  # user-scoped install without root (any distro)
#   make clean
#
# Prereqs for packaging: python3, flutter, nfpm (https://nfpm.goreleaser.com).

PY      ?= python3
VENV    := backend/.venv
VPY     := $(VENV)/bin/python
DIST    := dist

.PHONY: all linux deb rpm daemon ui icon stage venv clean from-source

all: linux

# --- build steps ------------------------------------------------------------

venv:
	test -d $(VENV) || $(PY) -m venv $(VENV)
	$(VPY) -m pip install -q --upgrade pip
	$(VPY) -m pip install -q -r backend/requirements.txt pyinstaller

daemon: venv
	mkdir -p $(DIST)
	$(VENV)/bin/pyinstaller packaging/quartzd.spec \
		--distpath $(DIST) --workpath build/pyinstaller -y

ui:
	cd ui && flutter build linux --release
	mkdir -p $(DIST)
	rm -rf $(DIST)/ui
	cp -r ui/build/linux/x64/release/bundle $(DIST)/ui

icon: venv
	mkdir -p $(DIST)
	$(VPY) packaging/gen_icon.py $(DIST)/quartz.png 256

stage: daemon ui icon

# --- Linux packages ---------------------------------------------------------

deb: stage
	nfpm pkg --config packaging/linux/nfpm.yaml --packager deb --target $(DIST)/

rpm: stage
	nfpm pkg --config packaging/linux/nfpm.yaml --packager rpm --target $(DIST)/

linux: deb rpm
	@echo "Packages in $(DIST)/:" && ls -1 $(DIST)/*.deb $(DIST)/*.rpm

# --- source install (no root) ----------------------------------------------

from-source:
	packaging/linux/install-from-source.sh

clean:
	rm -rf $(DIST) build/pyinstaller ui/build
