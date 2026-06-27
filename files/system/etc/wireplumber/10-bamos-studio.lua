# BamOS WirePlumber Configuration — Professional Audio Routing
# Based on GLF-OS creation patterns for studio/low-latency audio

monitor.alsa.rules = [
    # ── ALSA devices — high priority for USB audio interfaces ──────────────────
    {
        matches = [
            { alsa.card_name = "*USB*" }
            { alsa.card_name = "*Focusrite*" }
            { alsa.card_name = "*Scarlett*" }
            { alsa.card_name = "*Steinberg*" }
            { alsa.card_name = "*RME*" }
            { alsa.card_name = "*Universal Audio*" }
            { alsa.card_name = "*Behringer*" }
            { alsa.card_name = "*Presonus*" }
            { alsa.card_name = "*Arturia*" }
        ]
        actions = {
            update-props = {
                priority.session  = 2000
                priority.driver   = 2000
                node.nick         = "Studio Interface"
                audio.format      = "S32LE"
                audio.rate        = [ 48000 96000 192000 44100 ]
                api.alsa.period-size   = 64
                api.alsa.headroom      = 1024
                api.alsa.disable-batch = true
                session.suspend-timeout-seconds = 0  # No suspend for recording
            }
        }
    }
    # ── Internal audio — lower priority ────────────────────────────────────────
    {
        matches = [
            { alsa.card_name = "*HDA*" }
            { alsa.card_name = "*hdmi*" }
        ]
        actions = {
            update-props = {
                priority.session  = 1000
                priority.driver   = 1000
                api.alsa.period-size   = 256
                api.alsa.headroom      = 2048
            }
        }
    }
]

# ── Default audio routing — route all audio through Echo Cancel ──────────────
# For noise-free recordings and voice chat while streaming

monitor.bluez.rules = [
    # ── Bluetooth audio — force high-quality codec for headsets ───────────────
    {
        matches = [
            { device.name = "~bluez_card.*" }
        ]
        actions = {
            update-props = {
                bluetooth.protocol = "a2dp_sink"
                bluetooth.codec    = "ldac"
                bluez5.reconnect   = true
                session.suspend-timeout-seconds = 30
            }
        }
    }
]
