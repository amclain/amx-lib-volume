(***********************************************************
    AMX NETLINX TEST SUITE
    EXAMPLE

    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
    The "testing" system contains testing code
    that would be loaded onto a master to verify that
    functions in the production code return the correct
    values.
    
    See the "production" system for an example of the
    production setup.
    
    See the "amx-test-suite" include file and/or website
    documentation for help compiling and loading this
    example test on a master.
    
    From the NetLinx Diagnostics Program, send the string
    "run -v" (no quotes) to watch all tests.  See the
    amx-test-suite include file or the website for more
    documentation.
************************************************************)

PROGRAM_NAME='my-project-tests'
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(*                    INCLUDES GO BELOW                    *)
(***********************************************************)

#include 'amx-test-suite'
#include 'my-project-functions'

(***********************************************************)
(*                TEST DEFINITIONS GO BELOW                *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

/*
 *  This function is the user-defined entry point for the
 *  test harness.
 */
define_function testSuiteRun()
{
    // Test add() function.
    assert(add(1, 2) == 3, '1 + 2 = 3');
    
    // Test subtract() function.
    assert(subtract(5, 4) == 1, '5 - 4 = 1');
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
