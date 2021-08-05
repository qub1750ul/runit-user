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
DISTHOME = $(BUILDDIR)/dist
DISTDIR  = $(DISTHOME)/$(DISTMODE)

MAKEMODULES = lib/makemodules

DISTARCH = $(DISTHOME)/$(PACKAGE)-$(PKGVER).tar

# Applications

TAR     ?= tar
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
build: $(comp)
	echo "Built $(PACKAGE) $(RUNIT_USER_VERSION)"

.SILENT .PHONY: dist
dist: $(DISTDIR)

.SILENT .PHONY: distarch
distarch: $(DISTARCH)

.SILENT .PHONY: install
install:
	echo "Installing $(PACKAGE) $(PKGVER) to $(PREFIX)"
	$(RSYNC) -hr --progress $(DISTDIR) $(PREFIX)/

.SILENT .PHONY: clean
clean:
	rm -rf $(BUILDDIR)

.SILENT .PHONY: mostlyclean
mostlyclean:
	rm -rf $(COMPDIR) $(DISTDIR)

.SILENT .PHONY: distclean
distclean:
	rm -rf $(DISTDIR)

.SILENT .PHONY: test
test:
	testdist="$(DISTDIR)/test"
	
	if ! test -d $$testdist ; then
		echo "Missing distribution in $$testdist"
		exit 1
	fi
	
	cd $$testdist
	# start tests

# Recipes

.SILENT: $(DISTDIR)
$(DISTDIR): makefile $(BUILDDIR)/configure.make $(comp)

	# Install core package components
	$(INSTALL) -d $@/{$(RUNIT_USER_BINDIR),$(LIBDIR)}
	$(RSYNC) -rh $(COMPDIR)/{bin,lib} $@/$(LIBDIR)/

	# Install test components

ifeq ($(DISTMODE),test)
	:
endif

	# Install system links
	$(INSTALL) -d $@/bin
	ln -sf ../$(LIBDIR)/bin/runit-user $@/bin/

	echo "Updated distribution in $@"

.SILENT: $(DISTARCH)
$(DISTARCH): $(DISTDIR) makefile
	$(TAR) -cf $(DISTARCH) -C $< $(subst $</,,$(wildcard $</*))
	echo "Created distribution archive $@"

$(COMPDIR)/%: $(BUILDDIR)/configure.spp $(SRCDIR)/%
	@ echo "Compiling $@"
	@ mkdir -p $(dir $@)
	tools/spp $? $@