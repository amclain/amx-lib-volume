(***********************************************************
    AMX NETLINX TEST SUITE
    v2.0.0

    Website: https://sourceforge.net/projects/amx-test-suite/
    
    
 -- THIS IS A THIRD-PARTY LIBRARY AND IS NOT AFFILIATED WITH --
 --                   THE AMX ORGANIZATION                   --
    
    
    This suite contains functionality to test code written for
    AMX NetLinx devices.
    
    Tests are created in a user-defined file with a call to
    function testSuiteRun().  Use the assert functions below
    to verify your code's behavior.
    
    NOTE:
    It is recommended NOT to test any files that contain code in the
    mainline due to the nature of when the mainline is run.  One way
    around this, which also makes for portable code, is to have the
    mainline call functions that are defined in include files and run tests
    on those include files.  See the following AMX tech note for more info:
    
    "When does DEFINE_PROGRAM run (or, why loops in mainline are bad)"
    http://www.amx.com/techsupport/techNote.asp?id=993
    
    
    TO START THE TESTS:
    Compile your test project and load it on a master device.
    Launch the NetLinx Diagnostics Program provided by AMX and
    connect to the master.  When connected, click the "Enable
    Internal System Diagnostics" button.  In the "Control
    Device" page, set the device to control as follows:
    
    Device 36000
    Port   1
    System 0
    
    In the message to send box, type "run" (no quotes), select
    string as the type, and send the string to the device.
    The test results will be displayed in the "Diagnostics"
    window.
*************************************************************
    Copyright 2011 Alex McLain
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
************************************************************)

PROGRAM_NAME='amx-test-suite'

#if_not_defined AMX_TEST_SUITE
#define AMX_TEST_SUITE 1
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    History: See changelog.txt or version control repository.
*)
(***********************************************************)
(*           DEVICE NUMBER DEFINITIONS GO BELOW            *)
(***********************************************************)
DEFINE_DEVICE

dvTestSuiteDebug	= 0:0:0;     // Console output.
vdvTestSuiteListener	= 36000:1:0; // User command listener.
vdvTestSuiteInternal	= 36001:1:0; // Internal trigger listener.

(***********************************************************)
(*              CONSTANT DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_CONSTANT

TEST_PASS	=  0;
TEST_FAIL	= -1;

TEST_SUITE_NULL	       = 0;
TEST_SUITE_NULL_STRING = '';

TEST_SUITE_TIMEOUT_DEFAULT = 1000; // Event timeout in ms.

// Test Suite Timelines //
TEST_SUITE_TIMELINE_TIMESTAMP = 1; // For timestamp (in ms).

// Test Suite Running States //
TEST_SUITE_IDLE	   = 0;
TEST_SUITE_RUNNING = 1;

// Test Suite Message Modes //
TEST_SUITE_MESSAGE_NORMAL  = 0; // Only print failed tests.
TEST_SUITE_MESSAGE_VERBOSE = 1; // Print all tests.

// Test Suite Event Types //
TEST_SUITE_EVENT_NULL		= 0;
    // Data Events
TEST_SUITE_EVENT_COMMAND	= 1;
TEST_SUITE_EVENT_STRING		= 2;
TEST_SUITE_EVENT_ONLINE		= 3;
TEST_SUITE_EVENT_OFFLINE	= 4;
TEST_SUITE_EVENT_ONERROR	= 5;
TEST_SUITE_EVENT_STANDBY	= 6;
TEST_SUITE_EVENT_AWAKE		= 7;
    // Button Events
TEST_SUITE_EVENT_PUSH		= 8;
TEST_SUITE_EVENT_RELEASE	= 9;
TEST_SUITE_EVENT_HOLD		= 10;
    // Channel Events
TEST_SUITE_EVENT_ON		= 11;
TEST_SUITE_EVENT_OFF		= 12;
    // Level Events
TEST_SUITE_EVENT_LEVEL		= 13;

// Test Suite Event Status //
TEST_SUITE_ESTAT_ASSERTED	=  2;
TEST_SUITE_ESTAT_PENDING	=  1;
TEST_SUITE_ESTAT_VACANT		=  0;	// Index can be overwritten.
TEST_SUITE_ESTAT_FAILED		= -1;
TEST_SUITE_ESTAT_EXPIRED	= -2;

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

// Used for testing events.
struct testSuiteEvent
{
    char name[255];	// Assertion name.
    dev device;		// Device triggering the event.
    integer channel;	// Device channel or level number, if applicable.
    sinteger status;	// See test suite event status constants.
    integer type;	// See test suite event type constants.
    char value;		// Data: Used for level value.
    char str[1024];	// Data: Used for strings.
    long timestamp;	// Time the event was created.
    long expiration;	// Timestamp value that the event expires on.
}

(***********************************************************)
(*              VARIABLE DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_VARIABLE

long testSuiteTimestamp = 0;		// Timestamp timer used for events.
long testSuiteTimestampResolution[] = {1};	// 1 ms resolution.

// Test statistic counters.
slong testsPass;
slong testsFail;
slong testsExpectedFail; // Tests that are expected or designed to fail.

char testSuiteRunning = TEST_SUITE_IDLE;		// See test suite runnning states.
char testSuiteMessageMode = TEST_SUITE_MESSAGE_NORMAL;	// See test suite message modes.

// These arrays take up a lot of memory (>500k).
// Store them in RAM instead of non-volatile.
volatile testSuiteEvent testSuiteEventAsserts[255];
volatile testSuiteEvent testSuiteEventQueue[255];

(***********************************************************)
(*         SUBROUTINE/FUNCTION DEFINITIONS GO BELOW        *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
DEFINE_MUTUALLY_EXCLUSIVE

/*
 *  Print a line to the NetLinx diagnostic window.
 */
define_function testSuitePrint(char line[])
{
    send_string dvTestSuiteDebug, "line";
}

/*
 *  Print the running test name.
 */
define_function testSuitePrintName(char name[])
{
    if (length_string(name) > 0) send_string dvTestSuiteDebug, "'Testing: ', name";
}

/*
 *  Print 'passed'.
 */
define_function sinteger testSuitePass(char name[])
{
    testsPass++;
    
    if (testSuiteMessageMode == TEST_SUITE_MESSAGE_VERBOSE)
    {
	testSuitePrintName(name);
	send_string dvTestSuiteDebug, "'Passed.'";
    }
    
    return TEST_PASS;
}

/*
 *  Print 'failed'.
 */
define_function sinteger testSuiteFail(char name[])
{
    testsFail++;
    
    testSuitePrintName(name);
    send_string dvTestSuiteDebug, "'--FAILED--'";
    return TEST_FAIL;
}

/*
 *  Increment the expected test failure counter.
 *  
 *  This is designed for rare situations when a test is expected or supposed
 *  to fail.  An example is designing tests that check a test suite's
 *  functionality.
 */
define_function testSuiteExpectFail()
{
    testsExpectedFail++;
}

/*
 *  Reset the test suite.
 */
define_function testSuiteReset()
{
    testSuiteEvent e;
    integer i;
    
    testsFail = 0;
    testsPass = 0;
    testsExpectedFail = 0;
    
    for (i = 1; i <= max_length_array(testSuiteEventAsserts); i++)
    {
	testSuiteEventAsserts[i] = e;
	testSuiteEventQueue[i] = e;
    }
}

/*
 *  Parse user command.
 */
define_function testSuiteParseUserCommand(char str[])
{
    if (testSuiteRunning == TEST_SUITE_RUNNING) return;
    
    if (find_string(str, 'help', 1) > 0 || find_string(str, '?', 1) > 0)
    {
	testSuitePrintCommands();
    }
    
    if (find_string(str, 'run', 1))
    {
	if (length_string(str) < 6)
	{
	    // No flags.  Run in normal mode.
	    testSuiteMessageMode = TEST_SUITE_MESSAGE_NORMAL;
	}
	else
	{
	    // Check for verbose mode.
	    if (find_string(str, 'v', 1))
	    {
		testSuiteMessageMode = TEST_SUITE_MESSAGE_VERBOSE;
	    }
	}
	
	testSuiteStartTests();
    }
}

/*
 *  Parse internal triggers.
 */
define_function testSuiteParseInternalCommand(char str[])
{
    // User tests are finished, but there may be event assertions in the queue.
    if (find_string(str, 'tests-complete', 1))
    {
	if (testSuiteAssertQueueIsEmpty() == false)
	{
	    // Put the completion event back in the AMX queue if the
	    // assert queue is not empty.  This prevents the test suite
	    // from finishing prematurely.
	    
	    wait 1;
	    testSuiteProcessEventAssertions();
	    send_string vdvTestSuiteInternal, 'tests-complete';
	    return;
	}
	
	testSuitePrint("'Total Tests: ', itoa(testsPass + testsFail), '   Tests Passed: ', itoa(testsPass), '   Tests Failed: ', itoa(testsFail)");
	
	if (testsExpectedFail > 0)
	{
	    testSuitePrint("'Expected Failures: ', itoa(testsExpectedFail)");
	}
	
	testSuitePrint('Done.');
	
	testSuiteRunning = TEST_SUITE_IDLE;
	
	return;
    }
}

/*
 *  Print the list of test suite commands.
 */
define_function testSuitePrintCommands()
{
    testSuitePrint('--------------------------------------------------');
    testSuitePrint('               TEST SUITE COMMANDS                ');
    testSuitePrint('--------------------------------------------------');
    testSuitePrint('help                                              ');
    testSuitePrint('   Display this list of test suite commands.      ');
    testSuitePrint('                                                  ');
    testSuitePrint('run [-v]                                          ');
    testSuitePrint('   Start the tests.                               ');
    testSuitePrint('   -v   Verbose mode: Show tests that pass.       ');
    testSuitePrint('--------------------------------------------------');
}

/*
 *  Run the tests.
 */
define_function testSuiteStartTests()
{
    if (testSuiteRunning == TEST_SUITE_RUNNING) return;
    
    testSuiteRunning = TEST_SUITE_RUNNING; // Flag tests as running.
    
    testSuiteReset();
    
    testSuitePrint('Running tests...');
    
    testSuiteRun(); // Call the user-defined function to start tests.
    
    // User tests have been run.  Throw a test completion event
    // in the AMX queue so that all of the event assertions have
    // time to finish.
    send_string vdvTestSuiteInternal, 'tests-complete';
}

/*
 *  Process any pending event assertions and garbage-collect the queues.
 */
define_function testSuiteProcessEventAssertions()
{
    integer i, j;
    
    if (testSuiteRunning != TEST_SUITE_RUNNING) return;
    
    for (i = 1; i <= max_length_array(testSuiteEventAsserts); i++)
    {
	// Check for pending assertions.
	if (testSuiteEventAsserts[i].status == TEST_SUITE_ESTAT_PENDING)
	{
	    for (j = 1; j <= max_length_array(testSuiteEventQueue); j++)
	    {
		// Check for event match.
		if (testSuiteEventAsserts[i].device == testSuiteEventQueue[j].device &&
		    testSuiteEventAsserts[i].channel == testSuiteEventQueue[j].channel &&
		    testSuiteEventAsserts[i].type == testSuiteEventQueue[j].type &&
		    testSuiteEventAsserts[i].value == testSuiteEventQueue[j].value &&
		    testSuiteEventAsserts[i].str == testSuiteEventQueue[j].str)
		{
		    testSuitePass(testSuiteEventAsserts[i].name);
		    
		    testSuiteEventAsserts[i].status = TEST_SUITE_ESTAT_ASSERTED;
		    testSuiteEventQueue[j].status = TEST_SUITE_ESTAT_ASSERTED;
		    
		    break;
		}
	    }
	}
    }
    
    // Do garbage collection.
    testSuiteGarbageCollectEventQueue(testSuiteEventAsserts);
    testSuiteGarbageCollectEventQueue(testSuiteEventQueue);
}

/*
 *  Performs garbage collection on the specified queue.
 */
define_function testSuiteGarbageCollectEventQueue(testSuiteEvent queue[])
{
    integer i;
    
    for (i = 1; i <= max_length_array(queue); i++)
    {
	// Check for empty slot.
	if (queue[i].status == TEST_SUITE_ESTAT_VACANT)
	{
	    continue; // Skip.
	}
	
	// Check for expired event.
	if (queue[i].expiration < testSuiteTimestamp)
	{
	    // Check if event was an assertion (name attached).
	    if (length_string(queue[i].name) > 0)
	    {
		// Fail the assertion.
		testSuiteFail(queue[i].name);
	    }
	    
	    queue[i].status = TEST_SUITE_ESTAT_EXPIRED;
	}
	
	// Check for pending slot.
	if (queue[i].status == TEST_SUITE_ESTAT_PENDING)
	{
	    continue; // Skip.
	}
	
	// Free the slot.
	queue[i].device = 0;
	queue[i].channel = 0;
	queue[i].expiration = 0;
	queue[i].value = 0;
	queue[i].name = '';
	queue[i].str = '';
	queue[i].timestamp = 0;
	queue[i].type = 0;
	
	queue[i].status = TEST_SUITE_ESTAT_VACANT;
    }
}

/*
 *  Check if the assertion queue is empty.
 *  Returns boolean: true if empty.
 */
define_function sinteger testSuiteAssertQueueIsEmpty()
{
    integer i;
    
    for (i = 1; i <= max_length_array(testSuiteEventAsserts); i++)
    {
	if (testSuiteEventAsserts[i].status != TEST_SUITE_ESTAT_VACANT)
	{
	    return false; // Queue is not empty.
	}
    }
    
    return true; // Queue is empty.
}

/*
 *  A device event was triggered.  Add the event to the queue.
 */
define_function testSuiteEventTriggered(testSuiteEvent e)
{
    integer i;
    i = 1;
    
    if (testSuiteRunning == TEST_SUITE_IDLE) return;
    
    // Make sure event slot isn't occupied before writing.
    while (testSuiteEventQueue[i].status != TEST_SUITE_ESTAT_VACANT)
    {
	i++;
	
	// Break if buffer is full to prevent endless loop.
	if (i > max_length_array(testSuiteEventQueue))
	{
	    testSuitePrint('--EVENT QUEUE OVERFLOW--');
	    return;
	}
    }

    testSuiteEventQueue[i].timestamp = testSuiteTimestamp;
    testSuiteEventQueue[i].expiration = testSuiteTimestamp + TEST_SUITE_TIMEOUT_DEFAULT;
    testSuiteEventQueue[i].status = TEST_SUITE_ESTAT_PENDING;
    testSuiteEventQueue[i].type = e.type;
    testSuiteEventQueue[i].device = e.device;
    testSuiteEventQueue[i].channel = e.channel;
    testSuiteEventQueue[i].str = e.str;
    testSuiteEventQueue[i].value = e.value;
}

(***********************************************************)
(*                 TEST SUITE ASSERTIONS                   *)
(***********************************************************)

/*
 *  Alias of assertTrue().
 */
define_function sinteger assert(slong x, char name[])
{
    return assertTrue(x, name);
}

/*
 *  Passes if x is true (x > 0).  This means success codes
 *  can be defined as positive numbers. x can also be an
 *  expression, for example:
 *  assertTrue(myVariable == 10, 'Test my variable.');
 */
define_function sinteger assertTrue(slong x, char name[])
{
    if (x > 0)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x is false (x <= 0).  If error codes are defined
 *  as negative numbers, this test will also pass.  x can also
 *  be an expression (see assertTrue() function).
 */
define_function sinteger assertFalse(slong x, char name[])
{
    if (x <= 0)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x and y are equal.
 *  x == y
 */
define_function sinteger assertEqual(slong x, slong y, char name[])
{
    if (x == y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x and y are not equal.
 *  x != y
 */
define_function sinteger assertNotEqual(slong x, slong y, char name[])
{
    if (x != y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x is greater than y.
 *  x > y
 */
define_function sinteger assertGreater(slong x, slong y, char name[])
{
    if (x > y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x is greater than or equal to y.
 *  x >= y
 */
define_function sinteger assertGreaterEqual(slong x, slong y, char name[])
{
    if (x >= y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x is less than y.
 *  x < y
 */
define_function sinteger assertLess(slong x, slong y, char name[])
{
    if (x < y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if x is less than or equal to y.
 *  x <= y
 */
define_function sinteger assertLessEqual(slong x, slong y, char name[])
{
    if (x <= y)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Alias of assertStringEqual().
 */
define_function sinteger assertString(char x[], char y[], char name[])
{
    return assertStringEqual(x, y, name);
}

/*
 *  Passes if string x[] is identical to string y[].
 *  x[] == y[]
 */
define_function sinteger assertStringEqual(char x[], char y[], char name[])
{
    if (compare_string(x, y) == 1)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if string x[] is not identical to string y[].
 *  x[] != y[]
 */
define_function sinteger assertStringNotEqual(char x[], char y[], char name[])
{
    if (compare_string(x, y) == 0)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if string x[] contains string y[].
 *  y[] is in x[]
 */
define_function sinteger assertStringContains(char x[], char y[], char name[])
{
    if (find_string(x, y, 1) >= 1)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Passes if string x[] does not contain string y[].
 *  y[] not in x[]
 */
define_function sinteger assertStringNotContains(char x[], char y[], char name[])
{
    if (find_string(x, y, 1) == 0)
    {
	return testSuitePass(name);
    }
    else
    {
	return testSuiteFail(name);
    }
}

/*
 *  Adds an event to the assertion queue.
 *  This is a generic function.  It is recommended to use one of the more
 *  specific event assertions.
 */
define_function assertEventGeneric(testSuiteEvent e)
{
    integer i;
    i = 1;
    
    // Make sure event slot isn't occupied before writing.
    while (testSuiteEventAsserts[i].status != TEST_SUITE_ESTAT_VACANT)
    {
	i++;
	
	// Break if buffer is full to prevent endless loop.
	if (i > max_length_array(testSuiteEventAsserts))
	{
	    testSuitePrint('--ASSERT QUEUE OVERFLOW--');
	    return;
	}
    }

    testSuiteEventAsserts[i].timestamp = testSuiteTimestamp;
    testSuiteEventAsserts[i].expiration = testSuiteTimestamp + TEST_SUITE_TIMEOUT_DEFAULT;
    testSuiteEventAsserts[i].name = e.name;
    testSuiteEventAsserts[i].status = TEST_SUITE_ESTAT_PENDING;
    testSuiteEventAsserts[i].type = e.type;
    testSuiteEventAsserts[i].device = e.device;
    testSuiteEventAsserts[i].channel = e.channel;
    testSuiteEventAsserts[i].str = e.str;
    testSuiteEventAsserts[i].value = e.value;
}

/*
 *  Alias of assertEventString().
 */
define_function assertEvent(dev device, char str[], char name[]) {
    assertEventString(device, str, name);
}

/*
 *  Assert a data event.
 */
define_function assertEventData(dev device, integer type, char str[], char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.type = type;
    e.str = str;
    e.name = name;
    
    assertEventGeneric(e);
}

/*
 *  Assert a command data event.
 */
define_function assertEventCommand(dev device, char str[], char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_COMMAND, str, name);
}

/*
 *  Assert a string data event.
 */
define_function assertEventString(dev device, char str[], char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_STRING, str, name);
}

/*
 *  Assert an online data event.
 */
define_function assertEventOnline(dev device, char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_ONLINE, TEST_SUITE_NULL_STRING, name);
}

/*
 *  Assert an offline data event.
 */
define_function assertEventOffline(dev device, char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_OFFLINE, TEST_SUITE_NULL_STRING, name);
}

/*
 *  Assert an on-error data event.
 */
define_function assertEventOnError(dev device, char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_ONERROR, TEST_SUITE_NULL_STRING, name);
}

/*
 *  Assert a standby data event.
 */
define_function assertEventStandby(dev device, char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_STANDBY, TEST_SUITE_NULL_STRING, name);
}

/*
 *  Assert an awake data event.
 */
define_function assertEventAwake(dev device, char name[])
{
    assertEventData(device, TEST_SUITE_EVENT_AWAKE, TEST_SUITE_NULL_STRING, name);
}

/*
 *  Assert a button push event.
 */
define_function assertEventPush(dev device, integer chan, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = chan
    e.type = TEST_SUITE_EVENT_PUSH;
    e.name = name;

    assertEventGeneric(e);
}

/*
 *  Assert a button release event.
 */
define_function assertEventRelease(dev device, integer chan, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = chan
    e.type = TEST_SUITE_EVENT_RELEASE;
    e.name = name;

    assertEventGeneric(e);
}

/*
 *  Assert a button hold event.
 */
define_function assertEventHold(dev device, integer chan, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = chan
    e.type = TEST_SUITE_EVENT_HOLD;
    e.name = name;

    assertEventGeneric(e);
}

/*
 *  Assert a channel on event.
 */
define_function assertEventOn(dev device, integer chan, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = chan
    e.type = TEST_SUITE_EVENT_ON;
    e.name = name;

    assertEventGeneric(e);
}

/*
 *  Assert a channel off event.
 */
define_function assertEventOff(dev device, integer chan, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = chan
    e.type = TEST_SUITE_EVENT_OFF;
    e.name = name;

    assertEventGeneric(e);
}

/*
 *  Assert a level event.
 */
define_function assertEventLevel(dev device, integer level, char value, char name[])
{
    testSuiteEvent e;
    
    e.device = device;
    e.channel = level
    e.value = value;
    e.type = TEST_SUITE_EVENT_LEVEL;
    e.name = name;

    assertEventGeneric(e);
}

(***********************************************************)
(*                 STARTUP CODE GOES BELOW                 *)
(***********************************************************)
DEFINE_START

testSuiteReset();

timeline_create(TEST_SUITE_TIMELINE_TIMESTAMP, testSuiteTimestampResolution, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT); // Setup the timestamp timer.

(***********************************************************)
(*                   THE EVENTS GO BELOW                   *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvTestSuiteListener]
{
    string:
    {
	testSuiteParseUserCommand(data.text);
    }
}

data_event[vdvTestSuiteInternal]
{
    string:
    {
	testSuiteParseInternalCommand(data.text);
    }
}

timeline_event[TEST_SUITE_TIMELINE_TIMESTAMP]
{
    testSuiteTimestamp++;
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
#end_if
