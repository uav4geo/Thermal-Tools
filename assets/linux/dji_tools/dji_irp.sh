#!/bin/bash

__dirname=$(cd "$(dirname "$0")"; pwd -P)
cd "${__dirname}"

chmod +x ./dji_irp 
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd) ./dji_irp "$@"
