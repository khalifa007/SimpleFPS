#!/usr/bin/env bash
# Builds simpleFPS.elf: Common FPS for PS5 v1.2.1 with simplefps.patch applied.
#
# Needs Linux or WSL with git, cmake and python3, and the PS5 payload SDK
# (https://github.com/ps5-payload-dev/sdk), with PS5_PAYLOAD_SDK pointing at it:
#
#     PS5_PAYLOAD_SDK=/opt/ps5-payload-sdk bash build.sh
#
# The sources are fetched into ./work at the exact commits the patch was written against.
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${PS5_PAYLOAD_SDK:?set PS5_PAYLOAD_SDK to the PS5 payload SDK folder}"
export PS5_PAYLOAD_SDK
work=${SIMPLEFPS_WORK:-$here/work}

fetch() {  # folder, repository, commit
    if [ ! -d "$work/$1/.git" ]; then
        git -c core.autocrlf=false clone -q "$2" "$work/$1"
    fi
    git -C "$work/$1" checkout -q -f "$3"
}
mkdir -p "$work"
fetch src https://github.com/porhe911/Common-FPS-for-PS5.git b7969fd
fetch etahen https://github.com/etaHEN/etaHEN.git d47f99bd37f349ae59b3c4b66e09e93ba69f56cd
fetch shsrv https://github.com/ps5-payload-dev/shsrv.git 6f320637d56d344a0e7797753099e33238bbf146
git -C "$work/src" apply "$here/simplefps.patch"

"$PS5_PAYLOAD_SDK/bin/prospero-cmake" -S "$work/src/ps5" -B "$work/build" -DCMAKE_BUILD_TYPE=Release \
    -DCOMMON_FPS_ETAHEN_SOURCE="$work/etahen" -DCOMMON_FPS_SHSRV_SOURCE="$work/shsrv" > /dev/null
cmake --build "$work/build" -j"$(nproc)" > /dev/null
cp "$work/src/dist/Common_FPS_PS5_v1.2.1.elf" "$here/simpleFPS.elf"
ls -l "$here/simpleFPS.elf"
sha256sum "$here/simpleFPS.elf"
