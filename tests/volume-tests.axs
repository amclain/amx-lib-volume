(***********************************************************
    AMX VOLUME CONTROL
    TESTS
    
    Website: https://sourceforge.net/projects/amx-lib-volume/
    
    
    These functions test the library's functionality.
************************************************************)

PROGRAM_NAME='volume-tests'
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
(*                    INCLUDES GO BELOW                    *)
(***********************************************************)

#include 'amx-test-suite'

// Include the volume control library.
#include 'amx-lib-volume'

(***********************************************************)
(*                TEST DEFINITIONS GO BELOW                *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

define_function testSuiteRun()
{
    // Single control tests.
    testVolInit();
    testVolGetLevel();
    testVolSetLevel();
    testVolSetMinMax();
    testVolMute();
    testVolStep();
    testVolIncDec();
    
    // Array tests.
    testVolInitArray();
    testVolArrayGetLevel();
    testVolArraySetLevel();
    testVolArrayMinMax();
    testVolArrayStep();
    testVolArrayMute();
    testVolArrayIncDec();
}

// Test volume control initialization.
define_function testVolInit()
{
    volume v;
    integer step;
    step = 5;
    
    // Normal initialization.
    volInit(v, 15000, VOL_MUTED, 10000, 30000, step);
    
    assert(v.lvl == 15000, 'Init volume level.');
    assert(v.mute == VOL_MUTED, 'Init volume mute.');
    assert(v.min == 10000, 'Init min limit.');
    assert(v.max == 30000, 'Init max limit.');
    assert(v.step == ((v.max - v.min) / step), 'Init volume steps.');
    
    // Level exceeds max limit.
    volInit(v, 30000, VOL_UNMUTED, 10000, 20000, step);
    
    assert(v.mute == VOL_UNMUTED, 'Init volume unmuted.');
    assert(v.lvl == 20000, 'Init hits max limit.');
    
    // Level below min limit.
    volInit(v, 5000, VOL_UNMUTED, 10000, 20000, step);
    
    assert(v.lvl == 10000, 'Init hits min limit.');
    
    // Zero step initialization.
    volInit(v, 15000, VOL_UNMUTED, 10000, 20000, 0);
    
    assert(v.step == 0, 'Zero step initialization.');
    
    // No min/max initialization.
    volInit(v, 45000, VOL_UNMUTED, 0, 0, 0);
    
    assert(v.lvl == 45000, 'Init level, no min/max.');
    assert(v.max == 0, 'Zero max initialization.');
    assert(v.min == 0, 'Zero min initialization.');
    
    // Min exceeds max.
    volInit(v, 30000, VOL_UNMUTED, 20000, 15000, 0);
    
    assert(v.min = 15000, 'Min exceeds max initialization: Min limit.');
    assert(v.max = 15000, 'Min exceeds max initialization: Max limit.');
    assert(v.lvl = 15000, 'Min exceeds max initialization: Level clamped.');
}

// Test volume return level.
define_function testVolGetLevel()
{
    volume v;
    v.lvl = 15000;
    v.mute = VOL_UNMUTED;
    v.min = 10000;
    v.max = 20000;
    
    // Normal level.
    assert(volGetLevel(v) == 15000, 'Get volume level.');
    assert(volGetLevelAsByte(v) == (15000 / 256), 'Get volume level as byte.');
    
    // Muted level.
    v.mute = VOL_MUTED;
    
    assert(volGetLevel(v) == 0, 'Get volume level muted.');
    assert(volGetLevelAsByte(v) == 0, 'Get volume level muted as byte.');
    
    v.mute = VOL_UNMUTED;
    
    // Exceed max level.
    v.lvl = 40000;
    
    assert(volGetLevel(v) == 20000, 'Get volume, max limit hit.');
    assert(volGetLevelAsByte(v) == (20000 / 256), 'Get volume as byte, max limit hit.');
    
    // Exceed min level.
    v.lvl = 1000;
    
    assert(volGetLevel(v) == 10000, 'Get volume, min limit hit.');
    assert(volGetLevelAsByte(v) == (10000 / 256), 'Get volume as byte, min limit hit.');
}

// Test setting volume level.
define_function testVolSetLevel()
{
    sinteger result; // Function return value.
    volume v;
    v.lvl = 0;
    v.min = 0;
    v.max = 0;
    
    // Normal level.
    result = $1000;
    
    result = volSetLevel(v, 10000);
    assert(v.lvl == 10000, 'Set normal level.');
    assert(result == VOL_SUCCESS, 'Set level returns success.');
    
    result = $1000;
    
    result = volSetLevelAsByte(v, 128);
    assert(v.lvl == (128*256), 'Set normal level as byte.');
    assert(result == VOL_SUCCESS, 'Set level returns success.');
    
    // Set level while muted (should be successful).
    result = $1000;
    v.mute = VOL_MUTED;
    
    result = volSetLevel(v, 1000);
    assert(v.lvl == 1000, 'Set level while muted.');
    assert(result == VOL_SUCCESS, 'Set level returns success.');
    
    v.mute = VOL_UNMUTED;
    
    // Max limit hit.
    v.max = 5000;
    result = $1000;
    
    result = volSetLevel(v, 10000);
    assert(v.lvl == 5000, 'Set level hits max limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Set level returns level limited.');
    
    v.max = 1000;
    result = $1000;
    
    result = volSetLevelAsByte(v, 200);
    assert(v.lvl == 1000, 'Set level as byte hits max limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Set level returns level limited.');
    
    v.max = 0;
    
    // Min limit hit.
    v.min = 20000;
    result = $1000;
    
    result = volSetLevel(v, 10000);
    assert(v.lvl == 20000, 'Set level hits min limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Set level returns level limited.');
    
    v.min = 40000;
    result = $1000;
    
    result = volSetLevelAsByte(v, 10);
    assert(v.lvl == 40000, 'Set level as byte hits min limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Set level returns level limited.');
}

// Test setting min/max limits.
define_function testVolSetMinMax()
{
    volume v;
    v.min = 0;
    v.max = 0;
    
    // Test max limit.
    volSetMax(v, 10000);
    assert(v.max == 10000, 'Set max limit.');
    
    volSetMaxAsByte(v, 128);
    assert(v.max == (128 * 256), 'Set max limit as byte.');
    
    // Test min limit.
    volSetMin(v, 40000);
    assert(v.min == 40000, 'Set min limit.');
    
    volSetMinAsByte(v, 40);
    assert(v.min == (40 * 256), 'Set min limit as byte.');
    
    // Test min set above max.
    v.lvl = 0;
    v.min = 0;
    v.max = 30000;
    
    volSetMin(v, 35000);
    assert(v.min = 35000, 'Set min limit above max: Min value.');
    assert(v.max = 35000, 'Set min limit above max: Max value.');
    assert(v.lvl = 35000, 'Set min limit above max: Level value.');
    
    // Test max set below min.
    v.lvl = 0;
    v.min = 30000;
    v.max = $FFFF;
    
    volSetMax(v, 25000);
    assert(v.min = 25000, 'Set max limit below min: Min value.');
    assert(v.max = 25000, 'Set max limit below min: Max value.');
    assert(v.lvl = 25000, 'Set max limit below min: Level value.');
}

// Test volume mute.
define_function testVolMute()
{
    volume v;
    v.mute = VOL_UNMUTED;
    
    // Mute.
    volMute(v);
    assert(v.mute == VOL_MUTED, 'Mute volume.');
    
    // Unmute.
    volUnmute(v);
    assert(v.mute == VOL_UNMUTED, 'Unmute volume.');
}

// Test setting volume step.
define_function testVolStep()
{
    volume v;
    v.step = 0;
    
    // Set step value.
    volSetStep(v, 200);
    assert(v.step == 200, 'Set step.');
    
    volSetStepAsByte(v, 128);
    assert(v.step == (128 * 256), 'Set step as byte.');
    
    // Set number of steps.
    v.min = 10000;
    v.max = 20000;
    
    volSetNumSteps(v, 5);
    assert(v.step = ((v.max - v.min) / 5), 'Set number of steps.');
}

// Test incrementing/decrementing volume level.
define_function testVolIncDec()
{
    sinteger result; // Function return value.
    volume v;
    v.lvl = 14000;
    v.min = 10000;
    v.max = 20000;
    v.step = 2000;
    
    // Normal increment.
    result = $1000;
    
    result = volIncrement(v);
    assert(v.lvl == 16000, 'Increment level.');
    assert(result == VOL_SUCCESS, 'Increment returns success.');
    
    // Normal decrement.
    result = $1000;
    
    result = volDecrement(v);
    assert(v.lvl = 14000, 'Decrement level.');
    assert(result == VOL_SUCCESS, 'Decrement returns success.');
    
    // Increment hits max limit.
    v.lvl = 19000;
    result = $1000;
    
    result = volIncrement(v);
    assert(v.lvl == 20000, 'Increment hits max limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Increment returns level limited.');
    
    // Decrement hits min limit.
    v.lvl = 11000;
    result = $1000;
    
    result = volDecrement(v);
    assert(v.lvl == 10000, 'Decrement hits min limit.');
    assert(result == VOL_LEVEL_LIMITED, 'Decrement returns level limited.');
    
    // Increment does not roll over integer.
    v.min = 0;
    v.max = 0;
    v.lvl = 65000;
    result = $1000;
    
    result = volIncrement(v);
    assert(v.lvl == $FFFF, 'Increment does not roll over integer.');
    assert(result == VOL_SUCCESS, 'Increment returns success.');
    
    // Decrement does not roll over integer.
    v.min = 0;
    v.max = 0;
    v.lvl = 1000;
    result = $1000;
    
    result = volDecrement(v);
    assert(v.lvl == $0000, 'Decrement does not roll over integer.');
    assert(result == VOL_SUCCESS, 'Decrement returns success.');
    
    // Increment is not affected by mute.
    v.mute = VOL_MUTED;
    v.lvl = 10000;
    result = $1000
    
    result = volIncrement(v);
    assert(v.lvl == 12000, 'Increment is not affected by mute.');
    assert(result == VOL_SUCCESS, 'Increment returns success.');
    
    v.mute = VOL_UNMUTED;
    
    // Decrement is not affected by mute.
    v.mute = VOL_MUTED;
    v.lvl = 10000;
    result = $1000
    
    result = volDecrement(v);
    assert(v.lvl == 8000, 'Decrement is not affected by mute.');
    assert(result == VOL_SUCCESS, 'Decrement returns success.');
    
    v.mute = VOL_UNMUTED;
    
    // Return error if step not set.
    v.lvl = 2000;
    v.step = 0;
    result = $1000;
    
    result = volIncrement(v);
    assert(result == VOL_PARAM_NOT_SET, 'Increment returns param not set.');
    assert(v.lvl == 2000, 'Volume not adjusted.');
    
    v.lvl = 4000;
    result = $1000;
    
    result = volDecrement(v);
    assert(result == VOL_PARAM_NOT_SET, 'Decrement returns param not set.');
    assert(v.lvl == 4000, 'Volume not adjusted.');
}

(***********************************************************)
(*                 TEST ARRAY FUNCTIONS                    *)
(***********************************************************)

// Test array initialization.
define_function testVolInitArray()
{
    volume v[8];
    
    // Initialize array and assert random indexes.
    volInitArray(v, 15000, VOL_MUTED, 10000, 20000, 5);
    
    assert(v[6].lvl == 15000, 'Init array level.');
    assert(v[5].mute == VOL_MUTED, 'Init array mute state.');
    assert(v[4].min == 10000, 'Init array min level.');
    assert(v[3].max == 20000, 'Init array max level.');
    assert(v[2].step == (20000 - 10000) / 5, 'Init array step.');
}

// Test array return levels.
define_function testVolArrayGetLevel()
{
    volume v[8];
    
    volInitArray(v, 15000, VOL_UNMUTED, 10000, 20000, 5);
    
    v[1].lvl = 11000;
    v[2].lvl = 12000;
    v[3].lvl = 13000;
    v[4].lvl = 14000;
    v[5].lvl = 15000;
    v[6].lvl = 16000;
    v[7].lvl = 17000;
    v[8].lvl = 18000;
    
    assert(volGetIndexLevel(v, 7) == 17000, 'Get index volume.');
    assert(volGetIndexLevelAsByte(v, 3) == (13000 / 256), 'Get index volume as byte.');
}

// Test array set levels.
define_function testVolArraySetLevel()
{
    volume v[8];
    
    volInitArray(v, 15000, VOL_UNMUTED, 10000, 20000, 5);
    
    volSetArrayLevel(v, 16000);
    assert(v[6].lvl == 16000, 'Set array levels.');
    
    volSetArrayLevelAsByte(v, 70);
    assert(v[3].lvl == (70 * 256), 'Set array levels as byte.');
}

// Test array set min/max limits.
define_function testVolArrayMinMax()
{
    volume v[8];
    
    volInitArray(v, 0, VOL_UNMUTED, 0, 0, 0);
    
    // Set max.
    volSetArrayMax(v, 40000);
    assert(v[5].max == 40000, 'Set array max limit.');
    
    // Set max as byte.
    volSetArrayMaxAsByte(v, 195);
    assert(v[8].max == (195 * 256), 'Set array max limit as byte.');
    
    // Set min.
    volSetArrayMin(v, 5000);
    assert(v[2].min == 5000, 'Set array min limit.');
    
    // Set min as byte.
    volSetArrayMinAsByte(v, 10);
    assert(v[1].min == (10 * 256), 'Set array min limit as byte.');
}

// Test array set step.
define_function testVolArrayStep()
{
    volume v[8];
    
    volInitArray(v, 0, VOL_UNMUTED, 10000, 20000, 0);
    
    // Set step.
    volSetArrayStep(v, 100);
    assert(v[7].step == 100, 'Set array step.');
    
    // Set step as byte.
    volSetArrayStepAsByte(v, 2);
    assert(v[3].step == (2 * 256), 'Set array step as byte.');
    
    // Set number of steps.
    volSetArrayNumSteps(v, 5);
    assert(v[5].step == 2000, 'Set array number of steps.');
}

// Test array mute.
define_function testVolArrayMute()
{
    volume v[8];
    
    volInitArray(v, 0, VOL_UNMUTED, 0, 0, 0);
    
    // Mute array.
    volMuteArray(v);
    assert(v[6].mute == VOL_MUTED, 'Mute array.');
    
    // Unmute array.
    volUnmuteArray(v);
    assert(v[4].mute == VOL_UNMUTED, 'Unmute array.');
}

// Test array increment/decrement.
define_function testVolArrayIncDec()
{
    volume v[8];
    
    volInitArray(v, 14000, VOL_UNMUTED, 10000, 20000, 5);
    
    // Increment.
    volIncrementArray(v);
    assert(v[8].lvl == 16000, 'Increment array.');
    
    // Decrement.
    volInitArray(v, 14000, VOL_UNMUTED, 10000, 20000, 5);
    
    volDecrementArray(v);
    assert(v[1].lvl == 12000, 'Decrement array.');
    
    // Increment hits max limit.
    volInitArray(v, 19000, VOL_UNMUTED, 10000, 20000, 5);
    
    volIncrementArray(v);
    assert(v[5].lvl == 20000, 'Increment array hits max limit.');
    
    // Decrement hits min limit.
    volInitArray(v, 11000, VOL_UNMUTED, 10000, 20000, 5);
    
    volDecrementArray(v);
    assert(v[4].lvl == 10000, 'Decrement array hits min limit.');
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*          DO NOT PUT ANY CODE BELOW THIS COMMENT         *)
(***********************************************************)
