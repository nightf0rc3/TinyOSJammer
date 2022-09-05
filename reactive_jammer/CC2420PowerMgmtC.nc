#include "CC2420.h"

/**
 * Configuration of the CC2420 Power Management
 */
configuration CC2420PowerMgmtC {

  provides interface SplitControl;

}

implementation {

  components CC2420PowerMgmtP as PowerMgmtP;
  SplitControl = PowerMgmtP;
  
  components CC2420JamControlC;
  PowerMgmtP.Resource -> CC2420JamControlC;
  PowerMgmtP.CC2420Power -> CC2420JamControlC;

  components CC2420JamReactiveC;
  PowerMgmtP.SubControl -> CC2420JamReactiveC;

  components new StateC();
  PowerMgmtP.SplitControlState -> StateC;
  
}
