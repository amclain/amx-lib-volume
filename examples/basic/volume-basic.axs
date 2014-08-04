(***********************************************************
    AMX VOLUME CONTROL
    BASIC EXAMPLE PROGRAM
    
    Website: https://sourceforge.net/projects/amx-lib-volume/
    
    
    This application demonstrates a basic example of the
    amx-lib-volume library.  The project initializes a
    volume control and responds to level up/down commands
    initiated from the I/O port.
    
    Volume control operation can be viewed by watching the
    master's internal diagnostic output.
    
    I/O PORT CONNECTIONS:
    Ch 1: Volume Up Button
    Ch 2: Volume Down Button
************************************************************)

PROGRAM_NAME='volume basic'
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    History: See version control repository.
*)
(***********************************************************)
(*                   INCLUDES GO BELOW                     *)
(***********************************************************)

// Include the volume control library.
#include 'amx-lib-volume'

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvDebug = 0:0:0;        // For debug output.

dvIO    = 36000:1:0;    // Volume up/down button connections.

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

// Define a volume control.
volume mic1;

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

/*
 *  Initialize the volume control.
 *
 *  Parameters are: (Volume Control, Level, Mute State,
 *                   Min Level, Max Level, Number Of Steps)
 *
 *  In this case we're operating on the volume control
 *  variable "mic1".  The initial level is set to 0, but
 *  this will be overridden to 10000, our min value.  The
 *  control is initialized to an unmuted state with the
 *  VOL_UNMUTED constant, and min/max values are set to
 *  arbitrary values of 10000 and 20000, respectively.
 *  The number of steps between the min and max values is
 *  set to 5, meaning that there are five positions between
 *  the min and max values, which in this instance is a step
 *  value of 2000.  The volume level will move one step value
 *  up when volIncrement() is called, or one step down when
 *  volDecrement() is called, assuming the min/max limits
 *  have not been reached.
 */
volInit(mic1, 0, VOL_UNMUTED, 10000, 20000, 5);

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

// Volume Up
button_event[dvIO, 1]
{
    PUSH:
    {
        volIncrement(mic1); // Increment the volume up a step.
        send_string dvDebug, "'Volume Up: ', itoa(volGetLevel(mic1))";
    }
}

// Volume Down
button_event[dvIO, 2]
{
    PUSH:
    {
        volDecrement(mic1); // Decrement the volume down a step.
        send_string dvDebug, "'Volume Dn: ', itoa(volGetLevel(mic1))";
    }
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

