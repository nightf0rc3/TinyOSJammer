#include "CC2420.h"
#include "../JammingExp.h"

/**
 * Implementation of the CC2420 Reactive Jammer
 */
module CC2420JamReactiveP @safe() {

  provides interface Init;
  provides interface StdControl;

  uses interface GpioCapture as CaptureSFD;
  uses interface GpioInterrupt as InterruptFIFOP;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface ChipSpiResource;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;

  uses interface Leds;

  uses interface LocalTime<TMicro>;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_CANCEL,
  } cc2420_transmit_state_t;
  
  cc2420_transmit_state_t m_state = S_STOPPED;

  /** Byte reception/transmission indicator */
  bool m_receiving = FALSE;

  /** SFD reception/transmission indicator */
  bool sfdHigh;

  /** SFD reception interrupt time */
  uint32_t sfd_interrupt_time;

  /***************** Prototypes ****************/
  void preTX();
  void startTX();
  void stopTX();
  error_t acquireSpiResource();
  error_t releaseSpiResource();
  void signalDone( error_t err );
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call CaptureSFD.disable();
      call SpiResource.release();
      call CSN.set();
    }
    return SUCCESS;
  }

  /***************** Interrupts ****************/
  async event void InterruptFIFOP.fired() { }

  /**
   * The CaptureSFD event is actually an interrupt from the capture pin
   * which is connected to timing circuitry and timer modules.  This
   * type of interrupt allows us to see what time (being some relative value)
   * the event occurred, and lets us accurately timestamp our packets.  This
   * allows higher levels in our system to synchronize with other nodes.
   *
   * Because the SFD events can occur so quickly, and the interrupts go
   * in both directions, we set up the interrupt but check the SFD pin to
   * determine if that interrupt condition has already been met - meaning,
   * we should fall through and continue executing code where that interrupt
   * would have picked up and executed had our microcontroller been fast enough.
   */
  async event void CaptureSFD.captured( uint16_t time ) {
    uint32_t now = 0;
    if (JMR_DEBUG) {
      printf("SFD=%d;STATE=%d", call SFD.get(), m_state);
    }
    atomic {
      now = call LocalTime.get();
      switch( m_state ) {
        
      case S_SFD:
        m_state = S_EFD;
        sfdHigh = TRUE;
        // in case we got stuck in the receive SFD interrupts, we can reset
        // the state here since we know that we are not receiving anymore
        m_receiving = FALSE;
        call CaptureSFD.captureFallingEdge();
        
        stopTX();
        releaseSpiResource();

        if ( call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */

      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        m_state = S_STARTED;
        
        if ( !call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      default:
        /* this is the SFD for received messages */
        if ( !m_receiving && sfdHigh == FALSE ) {
          sfdHigh = TRUE;
          call CaptureSFD.captureFallingEdge();
          m_receiving = TRUE;
          sfd_interrupt_time = now;
          call Leds.led0Toggle();
          preTX();
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
          // if SFD.get() = 0, then an other interrupt happened since we
          // reconfigured CaptureSFD! Fall through
        }
        
        if ( sfdHigh == TRUE ) {
          sfdHigh = FALSE;
          call CaptureSFD.captureRisingEdge();
          m_receiving = FALSE;
          break;
        }
      }
    }
  }
      
  /***************** Functions ****************/

  /**
   * Acquire the SPI resource and transition to the S_BEGIN_TRANSMIT state
   */
  void preTX() {
    atomic {
      m_state = S_BEGIN_TRANSMIT;
      if ( acquireSpiResource() == SUCCESS ) {
        startTX();
      }
    }
  }

  /**
   * Transition to the S_SFD state and trigger a STXON strobe to activate the TX mode on the CC2420
   */
  void startTX() {
    atomic {
      call CSN.clr();
      m_state = S_SFD;
      call STXON.strobe();
      call CSN.set();
    }
  }

  /**
   * Trigger a SRFOFF strobe to deactivate the CC2420 radio and reactivate the RX mode by triggering a SRXON strobe
   * In debug: log the time between the received SFD interrupt and end of jamming transmition
   */
  void stopTX() {
    if (JMR_DEBUG) {
      unsigned long diff = 0;
      uint32_t now = 0;
      now = call LocalTime.get();
      diff = (unsigned long)now - (unsigned long)sfd_interrupt_time;
      printf("Diff:%lu \n", diff);
    }
    atomic {
      call CSN.clr();
      call SRFOFF.strobe();
      call SRXON.strobe();
      call CSN.set();
    }
  }

  /***************** SPI Resource ****************/
  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
  }

  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
    // never release
    call ChipSpiResource.abortRelease();
  }

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    uint8_t cur_state;
    atomic {
      cur_state = m_state;
    }

    switch( cur_state ) {
      case S_BEGIN_TRANSMIT:
        startTX();
        break;
        
      default:
        releaseSpiResource();
        break;
    }
  }

}
