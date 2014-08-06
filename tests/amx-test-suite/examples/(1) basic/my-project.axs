(***********************************************************
    AMX NETLINX TEST SUITE
    EXAMPLE

    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
    The "production" system contains production code that
    would be loaded onto a master when the system is
    commissioned.
    
    See the "testing" system for an example of
    how automated tests are run on this project's functions.
************************************************************)

PROGRAM_NAME='my-project'
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(*                    INCLUDES GO BELOW                    *)
(***********************************************************)

#include 'my-project-functions'

(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

dvTP = 10001:1:0; // Touch panel.

(***********************************************************)
(*              CONSTANT DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_CONSTANT

BTN_VOL_UP = 1;   // Touch panel volume up button.
BTN_VOL_DN = 2;   // Touch panel volume down button.

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*              VARIABLE DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_VARIABLE

sinteger volumeLevelMic1;
sinteger volumeLevelMic2;

(***********************************************************)
(*              LATCHING DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*         MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW         *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*         SUBROUTINE/FUNCTION DEFINITIONS GO BELOW        *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(***********************************************************)
(*                 STARTUP CODE GOES BELOW                 *)
(***********************************************************)
DEFINE_START

volumeLevelMic1 = 0;
volumeLevelMic2 = 0;

(***********************************************************)
(*                   THE EVENTS GO BELOW                   *)
(***********************************************************)
DEFINE_EVENT

button_event[dvTP, BTN_VOL_UP]
button_event[dvTP, BTN_VOL_DN]
{
    push:
    {
	switch (button.input.channel)
	{
	    // Volume up button pressed.  Increase level.
	    case BTN_VOL_UP: add(volumeLevelMic1, 200);
	    
	    // Volume down button pressed.  Decrease level.
	    case BTN_VOL_DN: subtract(volumeLevelMic2, 200);
	    
	    default: {}
	}
    }
}

(***********************************************************)
(*                 THE MAINLINE GOES BELOW                 *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
