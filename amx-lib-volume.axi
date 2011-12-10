(***********************************************************
    AMX VOLUME CONTROL LIBRARY
    v0.1.0

    Website: https://sourceforge.net/projects/amx-lib-volume/
    
    
 -- THIS IS A THIRD-PARTY LIBRARY AND IS NOT AFFILIATED WITH AMX --
    
    This library contains the code to set up and manipulate
    volume controls from within an AMX Netlinx project by
    including this file.  Source code and documentation can
    be obtained from the website listed above.
    
    NOTE: For the sake of consistency, "calls" are not used.
    Instead, functions that would normally have no return
    value return VOL_SUCCESS.
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
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

// Volume control mute states.
VOL_UNMUTED	= 0;
VOL_MUTED	= 1;

// Function return messages.
VOL_SUCCESS		=  0;	// Operation succeded.
VOL_FAILED		= -1;	// Generic operation failure.
VOL_LEVEL_LIMITED	= -2;	// Input value was limited due to min/max limit.
VOL_PARAM_NOT_SET	= -3;	// Parameter was not set.

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
}

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

/*
 *  Initialize volume control.
 *
 *  Parameters min, max, and numSteps can be set to 0 if not needed.
 */
define_function sinteger volInit(volume v, integer lvl, char muteState, integer min, integer max, integer numSteps)
{
    v.lvl = 0;
    v.mute = muteState;
    v.min = min;
    v.max = max;
    
    if (numSteps > 0) volSetNumSteps(v, numSteps);
    
    volSetLevel(v, lvl); // Will limit the volume to min/max range.
    
    return VOL_SUCCESS;
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
	if (v.max > 0 && v.lvl > v.max)
	{
	    return v.max;
	}
	else if (v.min > 0 && v.lvl < v.min)
	{
	    return v.min;
	}
	else {
	    return v.lvl;
	}
    }
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
    v.min = type_cast (v.min * 256);
    return VOL_SUCCESS;
}

/*
 *  Mute the channel.
 */
define_function sinteger volMute(volume v)
{
    v.mute = VOL_MUTED;
    return VOL_SUCCESS;
}

/*
 *  Unmute the channel.
 */
define_function sinteger volUnmute(volume v)
{
    v.mute = VOL_UNMUTED;
    return VOL_SUCCESS;
}

/*
 *  Set the amount that the level increaes/decreses when incremented.
 */
define_function sinteger volSetStep(volume v, integer value)
{
    v.step = value;
    return VOL_SUCCESS;
}

/*
 *  Set the amount that the level increaes/decreses when incremented.
 *
 *  Input value is scaled from a byte to an integer.
 */
define_function sinteger volSetStepAsByte(volume v, char value)
{
    integer x;
    x = type_cast (value * 256);
    v.step = x;
    return VOL_SUCCESS;
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
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED | VOL_PARAM_NOT_SET)
 */
define_function sinteger volIncrement(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = volGetLevel(v) + v.step;
    
    // Compensate for integer boundry wrap.
    if (l < volGetLevel(v)) l = $FFFF;
    
    return volSetLevel(v, l);
}

/*
 *  Decrease the volume by decrementing the level by one step.
 *  Returns sinteger: Status message.
 *  (VOL_SUCCESS | VOL_LEVEL_LIMITED | VOL_PARAM_NOT_SET)
 */
define_function sinteger volDecrement(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = volGetLevel(v) - v.step;
    
    // Compensate for integer boundry wrap.
    if (l > volGetLevel(v)) l = $0000;
    
    return volSetLevel(v, l);
}

(***********************************************************)
(*                    ARRAY FUNCTIONS                      *)
(***********************************************************)

define_function sinteger volInitArray(volume v[], integer lvl, char muteState, integer min, integer max, integer numSteps)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volInit(v[i], lvl, muteState, min, max, numSteps);
    }
    
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayLevel(volume v[], integer value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetLevel(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayLevelAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetLevelAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayMax(volume v[], integer value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetMax(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayMaxAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetMaxAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayMin(volume v[], integer value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetMin(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayMinAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetMinAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayStep(volume v[], integer value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetStep(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayStepAsByte(volume v[], char value)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetStepAsByte(v[i], value);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volSetArrayNumSteps(volume v[], integer steps)
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volSetNumSteps(v[i], steps);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volMuteArray(volume v[])
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volMute(v[i]);
    }
    
    return VOL_SUCCESS;
}

define_function sinteger volUnmuteArray(volume v[])
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volUnmute(v[i]);
    }
    
    return VOL_SUCCESS;
}

define_function sinteger volIncrementArray(volume v[])
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volIncrement(v[i]);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

define_function sinteger volDecrementArray(volume v[])
{
    integer i;
    
    for(i = 0; i < length_array(v); i++)
    {
	volDecrement(v[i]);
    }
    
    // TODO: Handle return value.
    return VOL_SUCCESS;
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

