#include "../JammingExp.h"

#define NEW_PRINTF_SEMANTICS

configuration JammerAppC {  }

implementation {
	components MainC, JammerC as App, LedsC;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC;

  components PrintfC;
  components SerialStartC;

  components CC2420PowerMgmtC as PowerMgmtC;
  components CC2420JamControlC;

  App.AMControl -> PowerMgmtC;
}
