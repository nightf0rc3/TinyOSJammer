#!/bin/bash
set -e
make telosb
make telosb reinstall bsl,/dev/tty.usbserial-6