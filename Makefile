# Quartz build & packaging.
#
#   make linux        # build daemon + UI, produce .deb and .rpm in dist/
#   make deb / rpm    # one format
#   make from-source  # user-scoped install without root (any distro)
#   make version V=X.Y.Z   # stamp a new version across every artifact
#   make clean        # drop build output
#   make distclean    # clean + drop the build venv
#
# Prereqs for packaging: python3, flutter, nfpm (https://nfpm.goreleaser.com).

PY      ?= python3
VENV    := backend/.venv
VPY     := $(VENV)/bin/python
VSTAMP  := $(VENV)/.stamp
DIST    := dist
STAGE   := $(DIST)/from-source

.PHONY: all linux deb rpm daemon ui icon stage venv version clean distclean from-source

all: linux

# --- build steps ------------------------------------------------------------

# A stamp file, not a phony target: `make daemon` twice should not re-run pip.
# Rebuilds only when requirements.txt changes.
$(VSTAMP): backend/requirements.txt
	test -d $(VENV) || $(PY) -m venv $(VENV)
	$(VPY) -m pip install -q --upgrade pip
	$(VPY) -m pip install -q -r backend/requirements.txt pyinstaller
	touch $@

venv: $(VSTAMP)

daemon: $(VSTAMP)
	mkdir -p $(DIST)
	$(VENV)/bin/pyinstaller packaging/quartzd.spec \
		--distpath $(DIST) --workpath build/pyinstaller -y

# material_symbols_icons drives IconData from non-constant values, which the
# icon tree-shaker rejects; --no-tree-shake-icons keeps the full font.
ui:
	@if [ -f $(UI_REL)/CMakeCache.txt ] && \
    ! grep -qx 'CMAKE_HOME_DIRECTORY:INTERNAL=$(CURDIR)/ui/linux' $(UI_REL)/CMakeCache.txt; then \
    echo "cmake still has stale cache, so im lowkey gonna nuke ui/build lol"; cd ui && flutter clean; \
	fi
	cd ui && flutter build linux --release --no-tree-shake-icons
	mkdir -p $(DIST)
	rm -rf $(DIST)/ui
	cp -r ui/build/linux/x64/release/bundle $(DIST)/ui

icon: $(VSTAMP)
	mkdir -p $(DIST)
	$(VPY) packaging/gen_icon.py $(DIST)/quartz.png 256 packaging/icon.png

stage: daemon ui icon

# --- Linux packages ---------------------------------------------------------

deb: stage
	nfpm pkg --config packaging/linux/nfpm.yaml --packager deb --target $(DIST)/

rpm: stage
	nfpm pkg --config packaging/linux/nfpm.yaml --packager rpm --target $(DIST)/

linux: deb rpm
	@echo "Packages in $(DIST)/:" && ls -1 $(DIST)/*.deb $(DIST)/*.rpm

# --- Root-less install ------------------------------------------------------

# packaging/linux/install.sh installs from a directory laid out like the
# release tarball (see packaging/build.sh), so assemble that layout from the
# staged build and run it. Installs under ~/.local; no root needed.
install: stage
	rm -rf $(STAGE)
	mkdir -p $(STAGE)
	cp $(DIST)/quartzd $(STAGE)/quartzd
	cp $(DIST)/quartz.png $(STAGE)/quartz-256.png
	cp -r $(DIST)/ui $(STAGE)/ui
	cp packaging/linux/install.sh \
	   packaging/linux/uninstall.sh \
	   packaging/linux/quartz.desktop \
	   packaging/linux/quartzd.service $(STAGE)/
	cp LICENSE $(STAGE)/
	chmod 755 $(STAGE)/install.sh $(STAGE)/uninstall.sh \
	          $(STAGE)/quartzd $(STAGE)/ui/quartz
	$(STAGE)/install.sh

# --- Versioning -------------------------------------------------------------

# Stamps backend/version.py, ui/pubspec.yaml, nfpm.yaml and the Windows
# manifests. With no V=, re-stamps from the existing VERSION file.
version:
	packaging/set-version.sh $(V)

# --- Cleaning ---------------------------------------------------------------

clean:
	rm -rf $(DIST) build/pyinstaller ui/build

distclean: clean
	rm -rf $(VENV)
