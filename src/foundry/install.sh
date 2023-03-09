#!/bin/sh
. ./ensure_command.sh
ensure_command bash
bash install.bash || exit 1
