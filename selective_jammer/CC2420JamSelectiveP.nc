#include "IEEE802154.h"
#include "message.h"
// #include "AM.h"

/**
 * Implementation of the CC2420 Selective Jammer
 */
module CC2420JamSelectiveP @safe() {

  provides interface Init;
  provides interface StdControl;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;
  uses interface GpioCapture as CaptureSFD;

  uses interface Alarm<T32khz,uint32_t> as TurnOffTimer;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Packet;
  uses interface CC2420PacketBody;

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
    S_RX_READ,
    S_JAM,
    S_EFD,
  } cc2420_receive_state_t;

  enum {
    JAM_TARGET_ADR = 0xffff,
  };

  cc2420_receive_state_t m_state;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;

  bool m_sfdHigh = FALSE;
  bool m_receiving = FALSE;
  
  norace message_t* ONE_NOK m_p_rx_buf;
  message_t m_rx_buf;

  uint32_t sfd_interrupt_time;

  /***************** Prototypes ****************/
  void beginReceive();
  void receive();
  void flush();
  void startTX();
  void stopTX();

  /***************** Init Commands ****************/
  command error_t Init.init() {
    m_p_rx_buf = &m_rx_buf;
    return SUCCESS;
  }

  /***************** StdControl ****************/
  command error_t StdControl.start() {
    atomic {
      m_state = S_STARTED;
      /* Note:
         We use the falling edge because the FIFOP polarity is reversed. 
         This is done in CC2420Power.startOscillator from CC2420ControlP.nc.
       */
      call InterruptFIFOP.enableFallingEdge();
      call CaptureSFD.captureRisingEdge();
    }
    return SUCCESS;
  }
  
  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call CSN.set();
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }
  
  /***************** InterruptFIFOP Events ****************/
  async event void InterruptFIFOP.fired() {
    call Leds.led2Toggle();
    m_state = S_RX_READ;
    beginReceive();
  }

  async event void TurnOffTimer.fired() {
    if ( m_state == S_JAM ) {
      stopTX();
    }
  }

  async event void CaptureSFD.captured( uint16_t time ) {
    uint32_t now = 0;
    if (JMR_DEBUG) {
      printf("SFD=%d;STATE=%d", call SFD.get(), m_state);
    }
    atomic {
      now = call LocalTime.get();
      if ( m_state == S_STARTED ) {
        if ( !m_receiving && !m_sfdHigh ) {
            m_sfdHigh = TRUE;
            call CaptureSFD.captureFallingEdge();
            m_receiving = TRUE;
            sfd_interrupt_time = now;

            if ( call SFD.get() ) {
              // wait for the next interrupt before moving on
              return;
            }
            // if SFD.get() = 0, then an other interrupt happened since we
            // reconfigured CaptureSFD! Fall through
          }
        
        if ( m_sfdHigh == TRUE ) {
          m_sfdHigh = FALSE;
          call CaptureSFD.captureRisingEdge();
          m_receiving = FALSE;
        }
      }
    }
  }

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    receive();
  }
  
  /***************** RXFIFO Events ****************/
  /**
   * We received hopefully 8 bytes from the SPI bus.
   * Using the two DST bytes we can determine if the packet should be jammed
   * 0x00 0x00 0x00 0x00 0xa7 | 0x21 | 0x41 0x88 | 0x2e || 0x22 0x00 | 0xff 0xff | 0x01 0x00 | 0x3f | 0x06 | 0x00 0x31
   *           SFD            |  LEN |    FCF    |  DSN ||    PAN    |    DST    |    SRC    |  NET | Client ID
   * RX FIFO starts at LEN
   * Addr bytes: 6,7
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_p_rx_buf );

    // if DST matches, init jamming target
    if ((uint16_t) header->dest == JAM_TARGET_ADR) {
      flush();
      startTX();
      call TurnOffTimer.start(1);
    } else {
      flush();
      m_state = S_STARTED;
    }
  }

  async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }
  
  /****************** Functions ****************/

  /**
   * Transition to the S_JAM state and trigger a STXON strobe to activate the TX mode on the CC2420
   */
  void startTX() {
    atomic {
      m_state = S_JAM;
      m_sfdHigh = TRUE;
      m_receiving = FALSE;
      call CSN.clr();
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
      m_state = S_STARTED;
      m_sfdHigh = FALSE;
      call CSN.clr();
      call SRFOFF.strobe();
      call SRXON.strobe();
      call CSN.set();
    }
  }

  /**
   * Flush out the Rx FIFO
   */
  void flush() {
    call CSN.set();
    call CSN.clr();
    call SFLUSHRX.strobe();
    call CSN.set();
  }

  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
  void beginReceive() { 
    m_state = S_RX_READ;
    if (call SpiResource.isOwner()) {
      receive();
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();
    } else {
      call SpiResource.request();
    }
  }
  
  /**
   * Read in the first 8 bytes of the packet, just enough to get the DST of the packet
   */
  void receive() {
    call CSN.clr();
    call RXFIFO.beginRead( (uint8_t*)(call CC2420PacketBody.getHeader( m_p_rx_buf )), 8 );
  }

}
