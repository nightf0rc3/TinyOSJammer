#include "Timer.h"
#include "../JammingExp.h"
#include "message.h"
#include "CC2420TimeSyncMessage.h"

module JSenderC @safe() {
	uses {
		interface Leds;
		interface Boot;
		interface AMSend;
		interface CC2420Packet;	
		interface Timer<TMilli> as MilliTimer;
		interface SplitControl as AMControl;
		interface Packet;

    interface RadioBackoff as CcaOverride;
	}
}

implementation {

	message_t pkt;
	bool lock;
	uint16_t counter = 0;
	
	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS)
			call MilliTimer.startPeriodic(NORMAL_INTERVAL);
		else 
			call AMControl.start();
	}
	event void AMControl.stopDone(error_t err) { }
	
	event void MilliTimer.fired() {
    if (counter < PACKETS_COUNT) {
      atomic {
        regular_msg_t* rmsg = (regular_msg_t*) call Packet.getPayload(&pkt, sizeof(regular_msg_t));
        counter++;
        rmsg->packet_num = counter;
        rmsg->packet_num2 = counter;
        rmsg->packet_num3 = counter;
        rmsg->packet_num4 = counter;
        rmsg->packet_num5 = counter;
        rmsg->packet_num6 = counter;
        rmsg->packet_num7 = counter;
        rmsg->packet_num8 = counter;
        rmsg->packet_num9 = counter;
        rmsg->packet_num10 = counter;
        
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(regular_msg_t)) == SUCCESS) {
          call Leds.led1Toggle();
          lock = TRUE;
        }
      }
    } else {
      call MilliTimer.stop();
      call Leds.led2Toggle();
    }
	}
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&pkt == bufPtr)
			lock = FALSE;
	}

  async event void CcaOverride.requestCca(message_t *msg) {
		call CcaOverride.setCca(USE_CCA);
	}
	async event void CcaOverride.requestInitialBackoff(message_t *msg) { }
	async event void CcaOverride.requestCongestionBackoff(message_t *msg) { }
}
