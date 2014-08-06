(***********************************************************
    AMX NETLINX TEST SUITE
    TESTS
    
    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
    These functions test the application's functionality.
    
    >>  Run the tests in verbose mode (run -v) to verify  <<
    >>  that assertions pass and fail correctly.          <<
************************************************************)

PROGRAM_NAME='test-suite-tests'
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

#include 'amx-test-suite';

(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

vdvEventTester = 34000:1:0; // Virtual device for event asserts.

(***********************************************************)
(*                TEST DEFINITIONS GO BELOW                *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

define_function testSuiteRun()
{
    testBooleanAsserts();
    testComparisonAsserts();
    testStringAsserts();
    testEventAsserts();
}

define_function testBooleanAsserts()
{
    // Assert alias.
    assert(true, 'Assert alias.');
    assert(false, 'Assert alias (FAIL).');
    testSuiteExpectFail();
    
    // Assert true.
    assertTrue(true, 'Assert boolean true.');
    assertTrue(1, 'Assert integer 1.');
    assertTrue(2, 'Assert integer > 1.');
    assertTrue(0, 'Assert True = 0 (FAIL).');
    testSuiteExpectFail();
    
    // Assert false.
    assertFalse(false, 'Assert boolean false.');
    assertFalse(0, 'Assert integer 0.');
    assertFalse(-1, 'Assert integer < 0.');
    assertFalse(1, 'Assert False = 1 (FAIL).');
    testSuiteExpectFail();
}

define_function testComparisonAsserts()
{
    // Assert equal.
    assertEqual(1, 1, 'Assert equal.');
    assertEqual(2, 10, 'Assert equal (FAIL).');
    testSuiteExpectFail();
    
    // Assert not equal.
    assertNotEqual(3, 6, 'Assert not equal.');
    assertNotEqual(7, 7, 'Assert not equal (FAIL).');
    testSuiteExpectFail();
    
    // Assert greater than.
    assertGreater(8, 4, 'Assert greater.');
    assertGreater(1, 6, 'Assert greater (FAIL).');
    testSuiteExpectFail();
    assertGreater(5, 5, 'Assert greater (FAIL): equal.');
    testSuiteExpectFail();
    
    // Assert greater than or equal to.
    assertGreaterEqual(9, 2, 'Assert greater equal.');
    assertGreaterEqual(14, 14, 'Assert greater equal: equal.');
    assertGreaterEqual(11, 19, 'Assert greater equal (FAIL).');
    testSuiteExpectFail();
    
    // Assert less than.
    assertLess(6, 15, 'Assert less.');
    assertLess(23, 12, 'Assert less (FAIL).');
    testSuiteExpectFail();
    assertLess(8, 8, 'Assert less (FAIL): equal.');
    testSuiteExpectFail();
    
    // Assert less than or equal to.
    assertLessEqual(20, 31, 'Assert less equal.');
    assertLessEqual(23, 23, 'Assert less equal: equal.');
    assertLessEqual(87, 60, 'Assert less equal (FAIL).');
    testSuiteExpectFail();
}

define_function testStringAsserts()
{
    // String alias.
    assertString('abc def', 'abc def', 'String alias.');
    assertString('abc def', 'abc 123', 'String alias (FAIL).');
    testSuiteExpectFail();
    
    // String equal.
    assertStringEqual('abc def', 'abc def', 'Assert string equal.');
    assertStringEqual('abc def', 'abc 456', 'Assert string equal (FAIL).');
    testSuiteExpectFail();
    
    // String not equal.
    assertStringNotEqual('abc def', 'abc 456', 'Assert string not equal.');
    assertStringNotEqual('abc def', 'abc def', 'Assert string not equal (FAIL).');
    testSuiteExpectFail();
    
    // String contains.
    assertStringContains('abc def', 'def', 'Assert string contains.');
    assertStringContains('abc def', '123', 'Assert string contains (FAIL).');
    testSuiteExpectFail();
    
    // String does not contain.
    assertStringNotContains('abc def', '123', 'Assert string not contains.');
    assertStringNotContains('abc def', 'def', 'Assert string not contains (FAIL).');
    testSuiteExpectFail();
}

define_function testEventAsserts()
{
    // String event.
    send_string vdvEventTester, 'ABC123EVENT';
    assertEvent(vdvEventTester, 'ABC123EVENT', 'Assert string event.');
    
    // Command event.
    send_command vdvEventTester, 'ABC123COMMAND';
    assertEventCommand(vdvEventTester, 'ABC123COMMAND', 'Assert command event.');
    
    // Online data event.
    
    // Offline data event.
    
    // On-error data event.
    
    // Standby data event.
    
    // Awake data event.
    
    // Button push event.
    do_push(vdvEventTester, 1);
    assertEventPush(vdvEventTester, 1, 'Button push event.');
    
    // Button release event.
    do_release(vdvEventTester, 1);
    assertEventRelease(vdvEventTester, 1, 'Button release event.');
    
    // Button hold event.
    
    // Channel on event.
    on[vdvEventTester, 1];
    assertEventOn(vdvEventTester, 1, 'Assert channel on event.');
    
    // Channel off event.
    off[vdvEventTester, 1];
    assertEventOff(vdvEventTester, 1, 'Assert channel off event.');
    
    // Level event.
    // Have to set this off of the existing value or the test will fail
    // if the tests are run a second time.
    send_level vdvEventTester, 1, 2;
    assertEventLevel(vdvEventTester, 1, 2, 'Assert level event.');
    
    send_level vdvEventTester, 1, 127;
    assertEventLevel(vdvEventTester, 1, 127, 'Assert level event 2.');
    
    // String event returns incorrect data.
    send_string vdvEventTester, 'ABC456EVENT';
    assertEvent(vdvEventTester, '456', 'Assert event string invalid data (FAIL).');
    testSuiteExpectFail();
    
    // String event never triggered (don't handle event).
    assertEvent(vdvEventTester, 'This never happened.', 'Assert event never triggered (FAIL).');
    testSuiteExpectFail();
}

(***********************************************************)
(*                   THE EVENTS GO BELOW                   *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[vdvEventTester]
{
    STRING:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.type = TEST_SUITE_EVENT_STRING;
	e.str = data.text;
	
	testSuiteEventTriggered(e);
    }
    
    COMMAND:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.type = TEST_SUITE_EVENT_COMMAND;
	e.str = data.text;
	
	testSuiteEventTriggered(e);
    }
}

CHANNEL_EVENT[vdvEventTester, 1]
{
    ON:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.channel = channel.channel;
	e.type = TEST_SUITE_EVENT_ON;
	
	testSuiteEventTriggered(e);
    }
    
    OFF:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.channel = channel.channel;
	e.type = TEST_SUITE_EVENT_OFF;
	
	testSuiteEventTriggered(e);
    }
}

BUTTON_EVENT[vdvEventTester, 1]
{
    PUSH:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.channel = button.input.channel;
	e.type = TEST_SUITE_EVENT_PUSH;
	
	testSuiteEventTriggered(e);
    }
    
    RELEASE:
    {
	testSuiteEvent e;
	
	e.device = vdvEventTester;
	e.channel = button.input.channel;
	e.type = TEST_SUITE_EVENT_RELEASE;
	
	testSuiteEventTriggered(e);
    }
}

LEVEL_EVENT[vdvEventTester, 1]
{
    testSuiteEvent e;
    
    e.device = vdvEventTester;
    e.channel = level.input.level;
    e.value = level.value;
    e.type = TEST_SUITE_EVENT_LEVEL;
    
    testSuiteEventTriggered(e);
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
