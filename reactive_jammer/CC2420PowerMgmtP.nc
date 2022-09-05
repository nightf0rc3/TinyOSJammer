/**
 * Implementation of the CC2420 Power Management
 */
module CC2420PowerMgmtP @safe() {

  provides interface SplitControl;

  uses interface Resource;
  uses interface CC2420Power;
  uses interface StdControl as SubControl;
  uses interface State as SplitControlState;

}

implementation {

  enum {
    S_STOPPED,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
    S_TRANSMITTING,
  };

  message_t* ONE_NOK m_msg;
  
  error_t sendErr = SUCCESS;
  
  /****************** Prototypes ****************/
  task void startDone_task();
  task void stopDone_task();
  
  void shutdown();

  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
    if(call SplitControlState.requestState(S_STARTING) == SUCCESS) {
      call CC2420Power.startVReg();
      return SUCCESS;
    
    } else if(call SplitControlState.isState(S_STARTED)) {
      return EALREADY;
      
    } else if(call SplitControlState.isState(S_STARTING)) {
      return SUCCESS;
    }
    
    return EBUSY;
  }

  command error_t SplitControl.stop() {
    if (call SplitControlState.isState(S_STARTED)) {
      call SplitControlState.forceState(S_STOPPING);
      shutdown();
      return SUCCESS;
      
    } else if(call SplitControlState.isState(S_STOPPED)) {
      return EALREADY;
    
    } else if(call SplitControlState.isState(S_TRANSMITTING)) {
      call SplitControlState.forceState(S_STOPPING);
      // At sendDone, the radio will shut down
      return SUCCESS;
    
    } else if(call SplitControlState.isState(S_STOPPING)) {
      return SUCCESS;
    }
    
    return EBUSY;
  }

  async event void CC2420Power.startVRegDone() {
    call Resource.request();
  }
  
  event void Resource.granted() {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() {
    post startDone_task();
  }

  task void startDone_task() {
    call SubControl.start();
    call CC2420Power.rxOn();
    call Resource.release();
    call SplitControlState.forceState(S_STARTED);
    signal SplitControl.startDone( SUCCESS );
  }
  
  task void stopDone_task() {
    call SplitControlState.forceState(S_STOPPED);
    signal SplitControl.stopDone( SUCCESS );
  }
  
  
  /***************** Functions ****************/
  /**
   * Shut down all sub-components and turn off the radio
   */
  void shutdown() {
    call SubControl.stop();
    call CC2420Power.stopVReg();
    post stopDone_task();
  }

  /***************** Defaults ***************/
  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }
  
}

