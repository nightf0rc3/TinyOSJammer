/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Implementation for configuring a ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2008/05/14 21:33:07 $
 */

#include "CC2420.h"
#include "IEEE802154.h"

configuration CC2420JamControlC {

  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;
  
}

implementation {
  
  components CC2420JamControlP;
  Resource = CC2420JamControlP;
  CC2420Config = CC2420JamControlP;
  CC2420Power = CC2420JamControlP;
  ReadRssi = CC2420JamControlP;

  components MainC;
  MainC.SoftwareInit -> CC2420JamControlP;
  
  components AlarmMultiplexC as Alarm;
  CC2420JamControlP.StartupTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  CC2420JamControlP.CSN -> Pins.CSN;
  CC2420JamControlP.RSTN -> Pins.RSTN;
  CC2420JamControlP.VREN -> Pins.VREN;

  components HplCC2420InterruptsC as Interrupts;
  CC2420JamControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2420SpiC() as Spi;
  CC2420JamControlP.SpiResource -> Spi;
  CC2420JamControlP.SRXON -> Spi.SRXON;
  CC2420JamControlP.SRFOFF -> Spi.SRFOFF;
  CC2420JamControlP.SXOSCON -> Spi.SXOSCON;
  CC2420JamControlP.SXOSCOFF -> Spi.SXOSCOFF;
  CC2420JamControlP.FSCTRL -> Spi.FSCTRL;
  CC2420JamControlP.IOCFG0 -> Spi.IOCFG0;
  CC2420JamControlP.IOCFG1 -> Spi.IOCFG1;
  CC2420JamControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  CC2420JamControlP.MDMCTRL1 -> Spi.MDMCTRL1;
  CC2420JamControlP.PANID -> Spi.PANID;
  CC2420JamControlP.IEEEADR -> Spi.IEEEADR;
  CC2420JamControlP.RXCTRL1 -> Spi.RXCTRL1;
  CC2420JamControlP.RSSI  -> Spi.RSSI;
  CC2420JamControlP.TXCTRL  -> Spi.TXCTRL;

  CC2420JamControlP.DACTST  -> Spi.DACTST;

  components new CC2420SpiC() as SyncSpiC;
  CC2420JamControlP.SyncResource -> SyncSpiC;

  components new CC2420SpiC() as RssiResource;
  CC2420JamControlP.RssiResource -> RssiResource;

}

