# findutils
# A make library to ease common 'find' usage in makefiles
#
# Copyright (C) 2020 Giuseppe Masino ( qub1750ul ) <dev.gmasino@pm.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

# Current version of this module
MAKE_FINDUTILS_VERSION := v1.0.0

# Module environment variables and sensible defaults
FINDUTILS_MAKEMODULES ?= $(MAKEMODULES)
FINDUTILS_FIND     ?= $(FIND)
FINDUTILS_ROOTPATH ?= $(SRCDIR)
FINDUTILS_SUBMAKEFILE_NAMES ?= makefile Makefile GNUMakefile

define findutils_required_env_vars :=
  FINDUTILS_FIND
  FINDUTILS_ROOTPATH
  FINDUTILS_SUBMAKEFILE_NAMES
endef

# Check for required environment to be set
include $(FINDUTILS_MAKEMODULES)/requiredEnvCheck.make
$(call requiredEnvCheck,$(findutils_required_env_vars))

##
# Invoke find
findutils_find = $(shell $(FINDUTILS_FIND) $(FINDUTILS_ROOTPATH) $(1))

##
# Find listed files
# @param $(1) A list of files
findutils_findFileList = $(call findutils_find,-false $(foreach name,$(1),-or -type f -name $(name) -print))

##
# Find parent directories of listed files
# @param $(1) A list of files
findutils_findFileListDirs = $(shell printf "%s\n" $(dir $(call findutils_findFileList,$(1))) | sed 's!/$$!\*!' )

##
# Find subtree roots that contain a makefile of the type listed in FINDUTILS_SUBMAKEFILE_NAMES
findutils_findSubMakeDirs = $(call findutils_findFileListDirs,$(FINDUTILS_SUBMAKEFILE_NAMES))

##
# Generate a list of POSIX 'find' commands to exclude some paths from the results
# @param $(1) A list of paths
findutils_genPruneCmds = -false $(foreach path,$(1),-or -path $(path) -prune)

##
# Generate a list of POSIX 'find' commands to exclude tree branches that contain
# makefiles having a name listed in FINDUTILS_SUBMAKEFILE_NAMES
findutils_submakeRootsPruneCmds = $(call findutils_genPruneCmds,$(call findutils_findSubMakeDirs))

##
# Generate a source list excluding source tree branches that contain a makefile
# @param $(1) A find expression
findutils_gensrclist = $(call findutils_find,$(findutils_submakeRootsPruneCmds) -or $(if $(1),$(1),-false -print))
