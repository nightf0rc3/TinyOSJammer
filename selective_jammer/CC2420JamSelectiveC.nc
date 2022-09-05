/**
 * Configuration of the CC2420 Selective Jammer
 */
configuration CC2420JamSelectiveC {

  provides interface StdControl;

}

implementation {
  components MainC;
  components CC2420JamSelectiveP;

  components LocalTimeMicroC;
  CC2420JamSelectiveP.LocalTime -> LocalTimeMicroC;

  components CC2420PacketC;
  CC2420JamSelectiveP.CC2420Packet -> CC2420PacketC;
  CC2420JamSelectiveP.CC2420PacketBody -> CC2420PacketC;

  components AlarmMultiplexC as Alarm;
  CC2420JamSelectiveP.TurnOffTimer -> Alarm;
  
  components LedsC as Leds;
  CC2420JamSelectiveP.Leds -> Leds;

  StdControl = CC2420JamSelectiveP;

  MainC.SoftwareInit -> CC2420JamSelectiveP;
  
  components HplCC2420PinsC as Pins;
  CC2420JamSelectiveP.CSN -> Pins.CSN;
  CC2420JamSelectiveP.SFD -> Pins.SFD;
  CC2420JamSelectiveP.FIFO -> Pins.FIFO;
  CC2420JamSelectiveP.FIFOP -> Pins.FIFOP;

  components HplCC2420InterruptsC as InterruptsC;
  CC2420JamSelectiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  CC2420JamSelectiveP.CaptureSFD     -> InterruptsC.CaptureSFD;

  components new CC2420SpiC() as Spi;
  CC2420JamSelectiveP.SpiResource -> Spi;
  CC2420JamSelectiveP.RXFIFO -> Spi.RXFIFO;
  CC2420JamSelectiveP.SFLUSHRX -> Spi.SFLUSHRX;
  CC2420JamSelectiveP.STXON       -> Spi.STXON;
  CC2420JamSelectiveP.SRXON       -> Spi.SRXON;
  CC2420JamSelectiveP.SRFOFF      -> Spi.SRFOFF;

}
