(***********************************************************
    PROJECTOR INTERFACE
    
    This file contains the code to interface with a fictitious
    projector controlled via RS232.  The projector needs to
    receive 'PON' and 'POFF' strings to turn its power on
    and off.
************************************************************)

PROGRAM_NAME='projector'
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

(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

/*
 *  The projector is mapped to a virtual device to keep its
 *  code portable and testable.  The virtual device allows the
 *  events to be captured and asserted in the test environment.
 *  It can be device-combined to the physical projector's port
 *  in the production system.
 */
vdvProjector = 33000:1:0;

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

define_function projectorOn()
{
    send_string vdvProjector, "'PON'";
}

define_function projectorOff()
{
    send_string vdvProjector, "'POFF'";
}

(***********************************************************)
(*                 STARTUP CODE GOES BELOW                 *)
(***********************************************************)
DEFINE_START

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
