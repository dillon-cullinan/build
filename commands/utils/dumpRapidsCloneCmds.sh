#!/bin/bash

# Copyright (c) 2019, NVIDIA CORPORATION.

USAGE="
USAGE: $0
"

if (( $# > 0 )); then
    echo "${USAGE}"
    exit 1
fi

THISDIR=$(cd $(dirname $0); pwd)
RAPIDSDEVTOOL_DIR=${THISDIR}/../..
source ${THISDIR}/common.sh

#
# awk script processes repoSettings file line-by-line.
#
awk -v "debug=${DEBUG}" '
    BEGIN {
       inRapidsSection = 0
    }
    /^[a-zA-Z0-9_\-]+_REPO=.+$/ {
       split($0, fields, "=")
       var = fields[1]
       url = fields[2] # Assume url is similar to https://github.com/rapidsai/cudf.git
       repo = substr(var, 1, length(var)-length("_REPO"))
       numFields = split(url, fields, "/")
       last = fields[numFields]
       split(last, fields, ".")
       dir = fields[1]
       repourls[repo] = url
       repodirs[repo] = dir
       next
    }
    /^[a-zA-Z0-9_\-]+_BRANCH=.+$/ {
       split($0, fields, "=")
       var = fields[1]
       branch = fields[2]
       repo = substr(var, 1, length(var)-length("_BRANCH"))
       repobranches[repo] = branch
       next
    }
    END {
       for (repo in repourls) {
          url = repourls[repo]
          dir = repodirs[repo]
          branch = repobranches[repo]
          # NOTE: THIS ASSUMES FUNCTIONS clone AND shouldClone ARE DEFINED!
          # FIXME: This is a hack to support cuML and xgboost (and cudf?) until they change/fix how they use submodules
          if ((dir == "cudf") || (dir == "cuml") || (dir == "xgboost")) {
             printf("if shouldClone %s; then\n   clone %s %s %s noremote\nfi\n", dir, url, dir, branch)
          } else {
             printf("if shouldClone %s; then\n   clone %s %s %s\nfi\n", dir, url, dir, branch)
          }
       }
    }
    ' ${REPOSETTINGS_FILE_NAME}
