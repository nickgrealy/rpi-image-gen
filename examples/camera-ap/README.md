# camera-ap

Bare-minimum Raspberry Pi OS image with:
- **WiFi Access Point** (hostapd + WPA2) with DHCP (dnsmasq)
- **SSH server** with password authentication
- **rpicam-vid** for camera capture (`rpicam-apps` package)

The Pi becomes a standalone WiFi hotspot — no upstream router needed. Connect your laptop/phone to the AP and SSH straight in.

## Default credentials

| What | Value |
|---|---|
| WiFi SSID | `rpi-ap` |
| WiFi password | `raspberry123` |
| SSH user | `pi` |
| SSH password | `raspberry` |
| Pi IP (on AP) | `192.168.4.1` |

Change any of these in `config/camera-ap.yaml` under the `device:` and `env:` sections before building.

## Supported devices

The default config targets **Raspberry Pi Zero 2 W**. Change `device.layer` to match your hardware if needed:

| Hardware | Layer value |
|---|---|
| Raspberry Pi 5 | `rpi5` |
| Raspberry Pi 4 | `rpi4` |
| Raspberry Pi 3 | `rpi3` |
| Raspberry Pi Zero 2 W | `rpizero2w` |
| Compute Module 4 | `rpi-cm4` |
| Compute Module 5 | `rpi-cm5` |

## Building

### Prerequisites

Follow the rpi-image-gen [getting started guide](../../getting_started.adoc) to install host dependencies.
On macOS, use Docker as described in the [Docker tutorial](../../docs/) — the build runs inside a container.

### Build command

From the `rpi-image-gen` root directory:

```bash
./rpi-image-gen build -S ./examples/camera-ap/ -c camera-ap.yaml
```

The output image is written to `work/camera-ap-image/`.

### Customising AP settings

Edit `config/camera-ap.yaml` — the `env:` section controls the AP:

```yaml
env:
  AP_SSID: my-network-name
  AP_PASSPHRASE: mysecretpassword
  AP_CHANNEL: "6"         # 1–13 for 2.4 GHz; use iw list to see supported channels
  AP_IP: 192.168.4.1
  AP_DHCP_RANGE_START: 192.168.4.2
  AP_DHCP_RANGE_END: 192.168.4.20
  AP_DHCP_LEASE: 24h
```

## Flashing and connecting

1. Flash the `.img` to an SD card (e.g. with `rpi-imager` or `dd`).
2. Boot the Pi — it starts broadcasting `rpi-ap` within ~30 seconds.
3. Connect your machine to the `rpi-ap` WiFi network.
4. SSH in:
   ```bash
   ssh pi@192.168.4.1
   ```

## Using the camera

Once SSH'd in, test the camera with:

```bash
# Capture a 5-second H.264 video
rpicam-vid -o test.h264 -t 5000

# View a live preview (requires a display connected)
rpicam-vid -t 0

# List detected cameras
rpicam-hello --list-cameras
```

Camera detection is automatic — the default firmware `config.txt` includes `camera_auto_detect=1`.

## How it works

| Component | Package | Config |
|---|---|---|
| WiFi AP | `hostapd` | `/etc/hostapd/hostapd.conf` |
| DHCP server | `dnsmasq` | `/etc/dnsmasq.d/wlan0-ap.conf` |
| Static IP on wlan0 | systemd-networkd | `/etc/systemd/network/10-wlan0-ap.network` |
| SSH server | `openssh-server` | password auth enabled |
| Camera | `rpicam-apps` | auto-detected via firmware |

`iwd` (pulled in by the `trixie-minbase` suite) is masked at build time to prevent it from conflicting with `hostapd` on `wlan0`.

The `rpi-device-base` layer auto-generates `02-wlan0.network` (DHCP) via a build hook. The AP hook writes `01-wlan0-ap.network` (static IP) which sorts earlier and wins, then removes the DHCP file to avoid ambiguity.

## Project structure

```
examples/camera-ap/
├── config/
│   └── camera-ap.yaml          # main build config
├── bdebstrap/
│   └── customize90-wifi-ap     # configures hostapd, dnsmasq, static IP
└── README.md
```
