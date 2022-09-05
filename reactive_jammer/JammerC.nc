#include "../JammingExp.h"
#include "printf.h" 

#define CC2420_NO_ACKNOWLEDGEMENTS
#define CC2420_NO_ADDRESS_RECOGNITION

module JammerC @safe() {
	uses {
		interface Leds;
		interface Boot;
		interface SplitControl as AMControl;
	}
}

implementation {

	event void Boot.booted() {
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err != SUCCESS)
      call AMControl.start();
	}

	event void AMControl.stopDone(error_t err) { }
}
