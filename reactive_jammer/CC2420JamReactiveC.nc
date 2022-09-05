/**
 * Configuration of the CC2420 Reactive Jammer
 */
configuration CC2420JamReactiveC {

  provides {
    interface StdControl;
  }
}

implementation {

  components LocalTimeMicroC;
  CC2420JamReactiveP.LocalTime -> LocalTimeMicroC;

  components CC2420JamReactiveP;
  StdControl = CC2420JamReactiveP;

  components MainC;
  components AlarmMultiplexC as Alarm;
  MainC.SoftwareInit -> CC2420JamReactiveP;
  MainC.SoftwareInit -> Alarm;
  
  components HplCC2420PinsC as Pins;
  CC2420JamReactiveP.CSN -> Pins.CSN;
  CC2420JamReactiveP.SFD -> Pins.SFD;

  components HplCC2420InterruptsC as Interrupts;
  CC2420JamReactiveP.CaptureSFD     -> Interrupts.CaptureSFD;
  CC2420JamReactiveP.InterruptFIFOP -> Interrupts.InterruptFIFOP;

  components new CC2420SpiC() as Spi;
  CC2420JamReactiveP.SpiResource -> Spi;
  CC2420JamReactiveP.ChipSpiResource -> Spi;
  CC2420JamReactiveP.STXON       -> Spi.STXON;
  CC2420JamReactiveP.SRXON       -> Spi.SRXON;
  CC2420JamReactiveP.SRFOFF      -> Spi.SRFOFF;

  components LedsC;
  CC2420JamReactiveP.Leds -> LedsC;

}
