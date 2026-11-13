#!/usr/bin/env bash
# Config-to-pipeline check for a built rtsp-server: parses each pipeline without opening a camera or a port.
# Usage: services/rtsp-server/check_pipelines.sh <path-to-rtsp-server>
set -uo pipefail

BIN="${1:?usage: $0 <path-to-rtsp-server>}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

# Builds the pipeline for a [camera] body; prints it, or the refusal on stderr.
pipeline() {
    printf '[rtsp]\naddress = "127.0.0.1"\nport = 25600\n[camera]\nresolution = "1280x720"\nframerate = 30\nbitrate = 4000\n%b\n' "$1" > "$TMP/c.toml"
    "$BIN" --config "$TMP/c.toml" --print-pipeline 2>"$TMP/err" | sed -n 's/^Using pipeline: //p'
}

parses() {
    python3 -c 'import sys, gi; gi.require_version("Gst", "1.0"); from gi.repository import Gst; Gst.init(None); Gst.parse_launch(sys.argv[1])' "$1" 2>"$TMP/perr"
}

verdict() {
    if [ "$1" = 0 ]; then echo "PASS  $2"; else echo "FAIL  $2"; fails=$((fails + 1)); fi
}

for src in 'source = "argus"' 'source = "arducam-jetvariety"' 'source = "arducam-jetvariety"\nbayer = "mono"' 'source = "auto"'; do
    for enc in x264enc nvv4l2h264enc nvv4l2h265enc auto; do
        for rot in 0 90; do
            name="$(printf '%b' "$src" | tr "\n" " ") encoder = $enc rotation = $rot"
            p="$(pipeline "$src\nencoder = \"$enc\"\nrotation = \"$rot\"")"
            [ -n "$p" ] && parses "$p"
            verdict $? "$name"
        done
    done
done

p="$(pipeline 'source = "custom"\nlaunch = "videotestsrc ! x264enc ! rtph264pay name=pay0 pt=96"')"
[ "$p" = "( videotestsrc ! x264enc ! rtph264pay name=pay0 pt=96 )" ] && parses "$p"
verdict $? "source = custom"

# The untouched template must give the pipeline the server built before source and encoder existed.
want='( nvarguscamerasrc sensor-id=0 ! video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1 ! nvvidconv flip-method=0 ! video/x-raw,width=1280,height=720,format=I420 ! x264enc key-int-max=30 bitrate=4000 tune=zerolatency speed-preset=ultrafast ! video/x-h264,stream-format=byte-stream,profile=baseline ! rtph264pay config-interval=1 mtu=1400 name=pay0 pt=96 )'
[ "$(pipeline 'source = "argus"')" = "$want" ]
verdict $? "argus x264enc pipeline unchanged"

p="$(pipeline 'source = "arducam-jetvariety"\nencoder = "nvv4l2h265enc"\nrotation = "90"')"
[[ "$p" == *"nvvidconv flip-method=1 ! video/x-raw(memory:NVMM),width=720,height=1280,format=NV12 ! nvv4l2h265enc bitrate=4000000 "*"! h265parse ! rtph265pay "* ]]
verdict $? "rotation 90 swaps the size, h265 takes h265parse and rtph265pay"

refused() {
    pipeline "$1" >/dev/null
    grep -qx "$2" "$TMP/err"
    verdict $? "refused: $2"
}
refused 'source = "usb"' '\[camera\] source: "usb" refused, accepted: auto, argus, arducam-jetvariety, custom'
refused 'encoder = "h264"' '\[camera\] encoder: "h264" refused, accepted: auto, x264enc, nvv4l2h264enc, nvv4l2h265enc'
refused 'source = "arducam-jetvariety"\nbayer = "RGGB"' '\[camera\] bayer: "RGGB" refused, accepted: rggb, bggr, grbg, gbrg, mono'
refused 'source = "custom"' '\[camera\] launch: empty, required by source custom'

"$BIN" --help >/dev/null
verdict $? "--help exits 0"

# Canary: GRAY8 straight into bayer2rgb must fail to parse, or the parse check proves nothing.
! parses "( videotestsrc ! video/x-raw,format=GRAY8 ! bayer2rgb ! fakesink )"
verdict $? "canary: unlinkable pipeline rejected"

echo "failures  $fails"
[ "$fails" = 0 ]
