(***********************************************************
    AMX VOLUME CONTROL
    TESTS
    
    Website: https://sourceforge.net/projects/amx-lib-volume/
    
    
    These functions test the library's functionality.
************************************************************)

PROGRAM_NAME='volume-testes'
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
#include 'amx-test-suite'

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

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

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

// RUN TESTS
define_function testRun()
{
    // List tests here.
    testVolInit();
}

// Test initialization.
define_function testVolInit()
{
    volume v;
    integer step;
    
    // Normal initialization.
    step = 5;
    volInit(v, 15000, VOL_MUTED, 10000, 30000, step);
    
    assert(v.lvl == 15000, 'Init volume level.');
    assert(v.mute == VOL_MUTED, 'Init volume mute.');
    assert(v.min == 10000, 'Init min limit.');
    assert(v.max == 30000, 'Init max limit.');
    assert(v.step == ((v.max - v.min) / step), 'Init volume steps.');
    
    // Level exceeds max limit.
    
    // Level below min limit.
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

