(***********************************************************
    EVENT TEST EXAMPLE
    
    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
    An example of how to use an include file that was set up
    for event testing within the production environment.
************************************************************)

PROGRAM_NAME='event-test-example'
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    History:
*)
(***********************************************************)
(*                    INCLUDES GO BELOW                    *)
(***********************************************************)

#include 'projector'

(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

dvProjector = 5001:1:0;	// Fictitious projector attached to the RS232 port.

(***********************************************************)
(*              CONSTANT DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_CONSTANT

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*              VARIABLE DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_VARIABLE

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

combine_devices(vdvProjector, dvProjector); // Combine the projector virtual device to the physical device.

send_command vdvProjector, "'SET BAUD 9600,N,8,1 485 DISABLE'";

projectorOn();

(***********************************************************)
(*                   THE EVENTS GO BELOW                   *)
(***********************************************************)
DEFINE_EVENT

(***********************************************************)
(*                 THE MAINLINE GOES BELOW                 *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
