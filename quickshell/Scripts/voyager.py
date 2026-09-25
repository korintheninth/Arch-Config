import hid
import sys

VID = 0x3297
PID = 0x1977
USAGE_PAGE = 0xFF60
WEBHID_USAGE = 0x61
RAW_EPSIZE = 32

ORYX_CMD_PAIRING_INIT = 0x01
ORYX_EVT_PAIRING_SUCCESS = 0x04
ORYX_EVT_LAYER = 0x05
ORYX_EVT_KEYDOWN = 0x06
ORYX_EVT_KEYUP = 0x07

def get_serial():
    for device in hid.enumerate(VID, PID):
        sn = device.get('serial_number') or ''
        if '/' in sn:
            return sn
    return None

def get_telemetry_path():
    for device in hid.enumerate(VID, PID):
        if device['usage_page'] == USAGE_PAGE:
            # Force it to grab the WebHID telemetry interface, not the QMK debug console.
            # hidraw sometimes hides the usage ID (reads as 0), so we fallback to interface_number 1
            if device.get('usage') == WEBHID_USAGE or device.get('interface_number') == 1:
                return device['path']
    return None

serial = get_serial()
if serial:
    print(f"serial {serial}", flush=True)

target_path = get_telemetry_path()

if not target_path:
    print("error telemetry_not_found", flush=True)
    sys.exit(1)

try:
    device = hid.Device(path=target_path)

    print(f"Connected to Voyager at {target_path}...", flush=True)

    packet = bytearray(RAW_EPSIZE + 1)  # report ID 0 + 32-byte payload
    packet[1] = ORYX_CMD_PAIRING_INIT
    device.write(bytes(packet))

    while True:
        data = device.read(RAW_EPSIZE, timeout=1000)
        if not data:
            continue

        event = data[0]
        if event == ORYX_EVT_PAIRING_SUCCESS:
            print("Paired. Press keys to see telemetry.", flush=True)
        elif event == ORYX_EVT_LAYER:
            print(f"layer {data[1]}", flush=True)
        elif event == ORYX_EVT_KEYDOWN:
            print(f"down col={data[1]} row={data[2]}", flush=True)
        elif event == ORYX_EVT_KEYUP:
            print(f"up   col={data[1]} row={data[2]}", flush=True)
        else:
            print([hex(b) for b in data], flush=True)

except KeyboardInterrupt:
    print("Disconnected.", flush=True)
except Exception as e:
    print(f"Connection lost or error: {e}", flush=True)
