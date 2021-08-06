#!/usr/bin/bash

set -o errexit
set -o nounset

source tools/configure/libconf.bash
source tools/configure/cli/argparser.bash

loadConf
writeConf
