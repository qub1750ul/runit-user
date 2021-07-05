# requiredEnvCheck
# A make library that allows to stop make if required environment variables
# are unset
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
MAKE_REQUIREDENVCHECK_VERSION := v1.0.0

requiredEnvCheck_single = $(if $($(1)),,$(eval requiredEnvCheck_found_unset += $(1)))
requiredEnvCheck_list   = $(foreach var,$(1),$(call requiredEnvCheck_single,$(var)))
requiredEnvCheck_report = $(foreach var,$(requiredEnvCheck_found_unset),$(warning Required variable '$(var)' is not set))

define requiredEnvCheck =
  $(eval requiredEnvCheck_found_unset :=)
  $(call requiredEnvCheck_list,$(1))
  $(call requiredEnvCheck_report)
  $(if $(requiredEnvCheck_found_unset),$(error Incomplete environment detected))
endef
