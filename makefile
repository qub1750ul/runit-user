#!/bin/make

MAKEFLAGS   := --warn-undefined-variables --no-builtin-rules
.SHELLFLAGS := -eu -o pipefail -c

.ONESHELL:
SHELL := bash

.DEFAULT_GOAL := dist

PACKAGE := runit-user

SRCDIR   = src
BUILDDIR = build
COMPDIR  = $(BUILDDIR)/comp
DISTDIR  = $(BUILDDIR)/dist

MAKEMODULES = lib/makemodules

# Applications

FIND    ?= find
RSYNC   ?= rsync
INSTALL ?= install

include $(MAKEMODULES)/requiredEnvCheck.make
include $(MAKEMODULES)/findutils.make

ifeq ($(wildcard $(BUILDDIR)/configure.make),)
  $(error Project not configured. Run `./configure` to generate configuration)
else
  include $(BUILDDIR)/configure.make
endif

src  := $(call findutils_gensrclist,-type f -not -path '$(SRCDIR)/test/*')
comp := $(subst $(SRCDIR),$(COMPDIR),$(src))

# Standard targets

.SILENT .PHONY: build
build: $(COMPDIR)

.SILENT .PHONY: install
install: $(COMPDIR)
	$(call requiredEnvCheck,INSTALL_MODE INSTALL_DIR)
	echo "Installing $(PACKAGE) $(RUNIT_USER_VERSION) in $(INSTALL_DIR)"

	$(INSTALL) -d $(INSTALL_DIR)/{$(RUNIT_USER_BINDIR),$(LIBDIR)}
	$(RSYNC) -rh $(COMPDIR)/{bin,lib} $(INSTALL_DIR)/$(LIBDIR)/
	
	$(INSTALL) -d $(INSTALL_DIR)/bin
	ln -sf ../$(LIBDIR)/bin/runit-user $(INSTALL_DIR)/bin/

.SILENT .PHONY: dist
dist: $(DISTDIR)/$(DISTMODE)

.SILENT .PHONY: clean
clean:
	rm -rf $(BUILDDIR)

.SILENT .PHONY: mostlyclean
mostlyclean:
	rm -rf $(COMPDIR) $(DISTDIR)

.SILENT .PHONY: distclean
distclean:
	rm -rf $(DISTDIR)/$(DISTMODE)

.SILENT .PHONY: test
test:
	testdist="$(DISTDIR)/test"
	
	if ! test -d $$testdist ; then
		echo "Missing distribution in $$testdist"
		exit 1
	fi
	
	cd $$testdist
# # start tests

# Recipes

.SILENT: $(DISTDIR)/test
$(DISTDIR)/test: $(COMPDIR)
	echo "Updating distribution in $@"

	set -o allexport
	INSTALL_MODE=$(DISTMODE)
	INSTALL_DIR=$@

	$(MAKE) --no-print-directory install

.SILENT: $(COMPDIR)
$(COMPDIR): $(comp)
	echo "Built $(PACKAGE) $(RUNIT_USER_VERSION)"

$(COMPDIR)/%: $(SRCDIR)/%
	@ echo "Compiling $@" 
	@ mkdir -p $(dir $@)
	@ tools/spp $(BUILDDIR)/defines.csv $< $@
