#include "../JammingExp.h"
#include "IEEE802154.h"
#include "message.h"
#include "CC2420.h"

#define NEW_PRINTF_SEMANTICS

configuration JammerAppC {  }

implementation {
	components MainC, JammerC as App, LedsC;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC;

  components PrintfC;
  components SerialStartC;

  components CC2420PowerMgmtC as IntLayerC;
  components CC2420JamControlC;

  App.AMControl -> IntLayerC;
}
