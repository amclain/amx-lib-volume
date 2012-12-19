(***********************************************************
    AMX VOLUME CONTROL LIBRARY
    v0.1.2

    Website: https://sourceforge.net/projects/amx-lib-volume/
    
    
 -- THIS IS A THIRD-PARTY LIBRARY AND IS NOT AFFILIATED WITH --
 --                   THE AMX ORGANIZATION                   --
    
    
    This library contains the code to set up and manipulate
    volume controls from within an AMX Netlinx project by
    including this file.  Source code and documentation can
    be obtained from the website listed above.
    
    CONVENTIONS
    
    "VOL_" prefixes all library constants, and "vol" prefixes all
    library functions (without quotes).
    
    Constants are snake case (underscores separate words) with all
    uppercase letters.
    
    Function names are camel case with the first letter being lowercase.
    
    Volume levels have a native resolution of 16 bits (integer).
    The "...AsByte" functions can be applied to convert these levels
    to 8 bit values.
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

PROGRAM_NAME='amx-lib-volume'
#if_not_defined AMX_LIB_VOLUME
#define AMX_LIB_VOLUME 1
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

(***********************************************************)
(*              CONSTANT DEFINITIONS GO BELOW              *)
(***********************************************************)
DEFINE_CONSTANT

// Volume control mute states.
VOL_UNMUTED	= 0;
VOL_MUTED	= 1;

// Volume dim states.
VOL_DIM_OFF	= 0;
VOL_DIM_ON	= 1;

// Function return messages.
VOL_SUCCESS		=  0;	// Operation succeded.
VOL_FAILED		= -1;	// Generic operation failure.
VOL_LEVEL_LIMITED	= -2;	// Input value was limited due to min/max limit.
VOL_PARAM_NOT_SET	= -3;	// Parameter was not set.
VOL_OUT_OF_BOUNDS	= -4;	// Index boundry exceeded.

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

// Volume control.
struct volume
{
    integer lvl;	// Volume level.
    char mute;		// Mute status (VOL_MUTED | VOL_UNMUTED).
    integer max;	// Max volume level limit.  Assumed full-on ($FFFF) if not set.
    integer min;	// Min volume level limit.  Assumed full-off ($0000) if not set.
    integer step;	// Amount to raise/lower the volume level when incremented or decremented.
    char dim;		// Level dim status (VOL_DIM_ON | VOL_DIM_OFF).
    integer dimAmount;	// Amount to reduce the level when dim is on.
}

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

/*
 *  Initialize volume control.
 *
 *  Parameters min, max, and numSteps can be set to 0 if not needed.
 */
define_function volInit(volume v, integer lvl, char muteState, integer min, integer max, integer numSteps)
{
    v.lvl = 0;
    v.mute = muteState;
    v.dim = VOL_DIM_OFF;
    v.dimAmount = 0;
    
    // Max limit takes priority.
    v.max = max;
    
    if (min <= v.max)
    {
	v.min = min;
    }
    else
    {
	v.min = v.max;
    }
    
    if (numSteps > 0) {
	volSetNumSteps(v, numSteps);
    }
    else
    {
	v.step = 0;
    }
    
    volSetLevel(v, lvl); // Will limit the volume to min/max range.
}

/*
 *  Get volume level.
 *  Returns integer: Current volume level.
 *
 *  This function takes into account mute status and min/max limits.
 */
define_function integer volGetLevel(volume v)
{
    if (v.mute == VOL_MUTED)
    {
	return 0;
    }
    else
    {
	return volGetLevelPreMute(v);
    }
}

/*
 *  Get pre-mute volume level.
 *  Returns integer: Current volume level.
 *
 *  This function ignores mute status but respects min/max limits.
 */
define_function integer volGetLevelPreMute(volume v)
{
    integer lvl;
    integer lvlDim;
    
    // Do min/max adjustments.
    if (v.max > 0 && v.lvl > v.max)
    {
	lvl = v.max;
    }
    else if (v.min > 0 && v.lvl < v.min)
    {
	lvl = v.min;
    }
    else {
	lvl = v.lvl;
    }
    
    // Do dim adjustments.
    if (v.dim == VOL_DIM_ON)
    {
	lvlDim = lvl - v.dimAmount;
	
	// Check for integer rollover.
	if (lvlDim > lvl)
	{
	    lvl = 0;
	}
	else
	{
	    lvl = lvlDim;
	}
    }
    
    return lvl;
}

/*
 *  Get volume level.
 *  Returns char: Current volume level.
 *
 *  This function takes into account mute status and min/max limits.
 *  Return value is scaled from an integer to a byte.
 */
define_function char volGetLevelAsByte(volume v)
{
    integer x;
    x = volGetLevel(v);
    return type_cast (x / 256);
}

/*
 *  Get pre-mute volume level.
 *  Returns char: Current volume level.
 *
 *  This function ignores mute status but respects min/max limits.
 */
define_function integer volGetLevelPreMuteAsByte(volume v)
{
    integer x;
    x = volGetLevelPreMute(v);
    return type_cast (x / 256);
}

/*
 *  Set volume level.
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED)
 *
 *  This function takes into account min/max limits.
 *  This function does not affect mute status.
 */
define_function sinteger volSetLevel(volume v, integer value)
{
    if (v.max > 0 && value > v.max)
    {
	v.lvl = v.max;
	return VOL_LEVEL_LIMITED;
    }
    else if (v.min > 0 && value < v.min)
    {
	v.lvl = v.min;
	return VOL_LEVEL_LIMITED;
    }
    else
    {
	v.lvl = value;
	return VOL_SUCCESS;
    }
}

/*
 *  Get the control's mute state.
 *  Returns sinteger:
 *  (VOL_MUTED | VOL_UNMUTED)
 */
define_function sinteger volGetMuteState(volume v)
{
    return v.mute;
}

/*
 *  Set volume level.
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED)
 *
 *  This function takes into account min/max limits.
 *  This function does not affect mute status.
 *  Input value is scaled from a byte to an integer.
 */
define_function sinteger volSetLevelAsByte(volume v, char value)
{
    integer x;
    x = type_cast (value * 256);
    return volSetLevel(v, x);
}

/*
 * Set max limit.
 * Input: value > 0 to enable, value = 0 to disable.
 */
define_function sinteger volSetMax(volume v, integer value)
{
    v.max = value;
    if (v.min > v.max) v.min = v.max;
    volSetLevel(v, v.lvl); // Set volume level to itself to check min/max boundries.
    return VOL_SUCCESS;
}

/*
 *  Set max limit.
 *  Input: value > 0 to enable, value = 0 to disable.
 *  
 *  Input value is scaled from a byte to an integer.
 */
define_function sinteger volSetMaxAsByte(volume v, char value)
{
    v.max = type_cast (value * 256);
    return VOL_SUCCESS;
}

/*
 *  Set minimum limit.
 *  Input: value > 0 to enable, value = 0 to disable.
 */
define_function sinteger volSetMin(volume v, integer value)
{
    v.min = value;
    if (v.max < v.min) v.max = v.min;
    volSetLevel(v, v.lvl); // Set volume level to itself to check min/max boundries.
    return VOL_SUCCESS;
}

/*
 *  Set minimum limit.
 *  Input: value > 0 to enable, value = 0 to disable.
 *  
 *  Input value is scaled from a byte to an integer.
 */
define_function sinteger volSetMinAsByte(volume v, char value)
{
    v.min = type_cast (value * 256);
    return VOL_SUCCESS;
}

/*
 *  Mute the channel.
 */
define_function volMute(volume v)
{
    v.mute = VOL_MUTED;
}

/*
 *  Unmute the channel.
 */
define_function volUnmute(volume v)
{
    v.mute = VOL_UNMUTED;
}

/*
 *  Toggle the channel's mute state.
 */
define_function volMuteToggle(volume v)
{
    if (v.mute == false)
    {
	v.mute = VOL_MUTED;
    }
    else
    {
	v.mute = VOL_UNMUTED;
    }
}

/*
 *  Set the amount that the level increaes/decreses when incremented.
 */
define_function volSetStep(volume v, integer value)
{
    v.step = value;
}

/*
 *  Set the amount that the level increaes/decreses when incremented.
 *
 *  Input value is scaled from a byte to an integer.
 */
define_function volSetStepAsByte(volume v, char value)
{
    integer x;
    x = type_cast (value * 256);
    v.step = x;
}

/*
 *  Set the number of steps the control can be incremented/decremented.
 *
 *  This is an alternative to defining the value of the step.
 */
define_function sinteger volSetNumSteps(volume v, integer steps)
{
    if (steps == 0) return VOL_FAILED;
    
    v.step = (v.max - v.min) / steps;
    return VOL_SUCCESS;
}

/*
 *  Increase the volume by incrementing the level by one step.
 *  Is not affected by mute state.
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED | VOL_PARAM_NOT_SET)
 */
define_function sinteger volIncrement(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = v.lvl + v.step;
    
    // Compensate for integer boundry wrap.
    if (l < v.lvl) l = $FFFF;
    
    return volSetLevel(v, l);
}

/*
 *  Decrease the volume by decrementing the level by one step.
 *  Is not affected by mute state.
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED | VOL_PARAM_NOT_SET)
 */
define_function sinteger volDecrement(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = v.lvl - v.step;
    
    // Compensate for integer boundry wrap.
    if (l > v.lvl) l = $0000;
    
    return volSetLevel(v, l);
}

/*
 *  Dim the volume level.
 */
define_function volDimOn(volume v)
{
    v.dim = VOL_DIM_ON;
}

/*
 *  Undim the volume level, returning it to its "normal" level.
 */
define_function volDimOff(volume v)
{
    v.dim = VOL_DIM_OFF;
}

/*
 *  Get volume dim state.
 *  Returns char: status.
 *  (VOL_DIM_ON | VOL_DIM_OFF)
 */
define_function char volGetDimState(volume v)
{
    return v.dim;
}

/*
 *  Get the amount that the level is dimmed when dim is on.
 */
define_function integer volGetDimAmount(volume v)
{
    return v.dimAmount;
}

/*
 *  Get the amount that the level is dimmed when dim is on.
 *
 *  Returns a byte scaled from an integer.
 */
define_function char volGetDimAmountAsByte(volume v)
{
    return type_cast(v.dimAmount / 256);
}

/*
 *  Set the amount that the level dims.
 */
define_function volSetDimAmount(volume v, integer amount)
{
    v.dimAmount = amount;
}

/*
 *  Set the amount that the level dims.
 *
 *  Input is scaled from a byte to an integer.
 */
define_function volSetDimAmountAsByte(volume v, char amount)
{
    v.dimAmount = amount * 256;
}

(***********************************************************)
(*                    ARRAY FUNCTIONS                      *)
(***********************************************************)

/*
 *  Initialize an array of volume controls.
 *  
 *  Parameters min, max, and numSteps can be set to 0 if not needed.
 */
define_function volInitArray(volume v[], integer lvl, char muteState, integer min, integer max, integer numSteps)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volInit(v[i], lvl, muteState, min, max, numSteps);
    }
}

/*
 *  Get the volume level for a control in an array at the given index.
 *  Returns integer: Current volume level.
 *
 *  This function takes into account mute status and min/max limits.
 */
define_function integer volGetIndexLevel(volume v[], integer index)
{
    if (index > max_length_array(v)) return 0;
    
    return volGetLevel(v[index]);
}

/*
 *  Get the volume level for a control in an array at the given index.
 *  Returns char: Current volume level.
 *
 *  This function takes into account mute status and min/max limits.
 *  Return value is scaled from an integer to a byte.
 */
define_function char volGetIndexLevelAsByte(volume v[], integer index)
{
    if (index > max_length_array(v)) return 0;
    
    return volGetLevelAsByte(v[index]);
}

/*
 *  Set the volume level for all controls in an array.
 */
define_function sinteger volSetArrayLevel(volume v[], integer value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetLevel(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the volume level for all controls in an array.
 */
define_function sinteger volSetArrayLevelAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetLevelAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the max volume limit for all controls in an array.
 */
define_function sinteger volSetArrayMax(volume v[], integer value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetMax(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the max volume limit for all controls in an array.
 */
define_function sinteger volSetArrayMaxAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetMaxAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the min volume limit for all controls in an array.
 */
define_function sinteger volSetArrayMin(volume v[], integer value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetMin(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the min volume limit for all controls in an array.
 */
define_function sinteger volSetArrayMinAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetMinAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Set the volume step amount for all controls in an array.
 */
define_function volSetArrayStep(volume v[], integer value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetStep(v[i], value);
    }
}

/*
 *  Set the volume step amount for all controls in an array.
 */
define_function volSetArrayStepAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetStepAsByte(v[i], value);
    }
}

/*
 *  Set the number of steps all controls in the array can be
 *  incremented or decremented.
 */
define_function sinteger volSetArrayNumSteps(volume v[], integer steps)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetNumSteps(v[i], steps);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Mute all of the controls in the array.
 */
define_function volMuteArray(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volMute(v[i]);
    }
}

/*
 *  Unmute all of the controls in the array.
 */
define_function volUnmuteArray(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volUnmute(v[i]);
    }
}

/*
 *  Increase the volume of all controls in the array
 *  by one step.
 */
define_function sinteger volIncrementArray(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volIncrement(v[i]);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Decrease the volume of all controls in the array
 *  by one step.
 */
define_function sinteger volDecrementArray(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volDecrement(v[i]);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

/*
 *  Dim the volume level of all controls in the array.
 */
define_function volArrayDimOn(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volDimOn(v[i]);
    }
}

/*
 *  Undim the volume level of all controls in the array,
 *  returning them to their "normal" level.
 */
define_function volArrayDimOff(volume v[])
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volDimOff(v[i]);
    }
}

/*
 *  Set the amount that the level dims for an array.
 */
define_function volSetArrayDimAmount(volume v[], integer amount)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetDimAmount(v[i], amount);
    }
}

/*
 *  Set the amount that the level dims for an array.
 *
 *  Input is scaled from a byte to an integer.
 */
define_function volSetArrayDimAmountAsByte(volume v[], char amount)
{
    integer i;
    
    for(i = 1; i <= max_length_array(v); i++)
    {
	volSetDimAmountAsByte(v[i], amount);
    }
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
#end_if
