(***********************************************************
    EVENT TESTING EXAMPLE
    TESTS
    
    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
    This system tests string events sent to a fictitious
    projector.
    
    From the NetLinx Diagnostics Program, send the string
    "run -v" (no quotes) to watch all tests.  See the
    amx-test-suite include file or the website for more
    documentation.
************************************************************)

PROGRAM_NAME='event-test-example-tests'
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(*                    INCLUDES GO BELOW                    *)
(***********************************************************)

#include 'amx-test-suite'
#include 'projector'

(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*                TEST DEFINITIONS GO BELOW                *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

define_function testSuiteRun()
{
    // Projector power on.
    projectorOn();
    assertEventString(vdvProjector, 'PON', 'Projector power on.');
    
    // Projector power off.
    projectorOff();
    assertEventString(vdvProjector, 'POFF', 'Projector power off.');
}

(***********************************************************)
(*                   THE EVENTS GO BELOW                   *)
(***********************************************************)
DEFINE_EVENT

/*
 *  Set up an event handler to receive the projector events
 *  into the test suite event queue.
 */
data_event[vdvProjector]
{
    string:
    {
	testSuiteEvent e;
	
	e.device = vdvProjector;		// The device that triggered the event.
	e.type = TEST_SUITE_EVENT_STRING;	// The type of event.
	e.str = data.text;			// The event's data.
	
	testSuiteEventTriggered(e);
    }
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
