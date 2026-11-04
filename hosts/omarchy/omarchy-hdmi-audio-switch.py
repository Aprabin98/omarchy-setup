#!/usr/bin/env python3
"""Select HDMI audio while its monitor is connected, otherwise laptop speakers."""
import re
import subprocess
import time

CARD = "alsa_card.pci-0000_00_1f.3"
HDMI_PROFILE = "output:hdmi-stereo+input:analog-stereo"
ANALOG_PROFILE = "output:analog-stereo+input:analog-stereo"
HDMI_SINK = "alsa_output.pci-0000_00_1f.3.hdmi-stereo"
ANALOG_SINK = "alsa_output.pci-0000_00_1f.3.analog-stereo"
current_target = None


def run(*args):
    return subprocess.run(args, text=True, capture_output=True, check=False)


def hdmi_connected():
    result = run("pactl", "list", "cards")
    if result.returncode:
        return None
    card = re.search(r"(?ms)^Card #.*?^\s*Name: " + re.escape(CARD) + r"\n.*?(?=^Card #|\Z)", result.stdout)
    if not card:
        return None
    port = re.search(r"(?ms)^\s*hdmi-output-0:.*?(?=^\s{2,}[a-zA-Z0-9_-]+:|\Z)", card.group())
    if not port:
        return False
    header = port.group().splitlines()[0].lower()
    if "not available" in header or "unavailable" in header or "available: no" in header:
        return False
    return "available" in header


def apply_target(connected):
    global current_target
    target = "hdmi" if connected else "analog"
    if target == current_target:
        return
    profile = HDMI_PROFILE if connected else ANALOG_PROFILE
    sink = HDMI_SINK if connected else ANALOG_SINK
    if run("pactl", "set-card-profile", CARD, profile).returncode:
        return
    for _ in range(10):
        if run("pactl", "set-default-sink", sink).returncode == 0:
            current_target = target
            return
        time.sleep(0.2)


def refresh():
    connected = hdmi_connected()
    if connected is not None:
        apply_target(connected)


refresh()
while True:
    subscription = subprocess.Popen(
        ["pactl", "subscribe"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        text=True, bufsize=1,
    )
    if subscription.stdout is not None:
        for event in subscription.stdout:
            if any(kind in event for kind in ("card", "sink", "server")):
                refresh()
    subscription.wait()
    time.sleep(1)
