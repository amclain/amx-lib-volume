


PROGRAM_NAME='volume control'
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/05/2006  AT: 09:00:25        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

UNMUTED	= 0;
MUTED	= 1;


// Return messages.
VOL_SUCCESS		= 0;
VOL_FAILED		= -1;
VOL_LEVEL_LIMITED	= -2;
VOL_PARAM_NOT_SET	= -3;

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

struct volume
{
    integer lvl;
    char mute;
    integer max;
    integer min;
    integer step;
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

define_function integer getLevel(volume v)
{
    if (v.mute == MUTED)
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

define_function char getLevelAsByte(volume v)
{
    integer x;
    x = getLevel(v);
    return type_cast (x / 256);
}

define_function sinteger setLevel(volume v, integer value)
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

define_function sinteger setLevelAsByte(volume v, char value)
{
    integer x;
    x = type_cast (value * 256);
    return setLevel(v, x);
}

define_function sinteger setMax(volume v, integer value)
{
    v.max = value;
    return VOL_SUCCESS;
}

define_function sinteger setMaxAsByte(volume v, char value)
{
    v.max = type_cast (value * 256);
    return VOL_SUCCESS;
}

define_function sinteger setMin(volume v, integer value)
{
    v.min = value;
    return VOL_SUCCESS;
}

define_function sinteger setMinAsByte(volume v, char value)
{
    v.min = type_cast (v.min * 256);
    return VOL_SUCCESS;
}

define_function sinteger mute(volume v)
{
    v.mute = MUTED;
    return VOL_SUCCESS;
}

define_function sinteger unmute(volume v)
{
    v.mute = UNMUTED;
    return VOL_SUCCESS;
}

define_function sinteger setStep(volume v, integer value)
{
    v.step = value;
    return VOL_SUCCESS;
}

define_function sinteger setStepAsByte(volume v, char value)
{
    integer x;
    x = type_cast (value * 256);
    v.step = x;
    return VOL_SUCCESS;
}

define_function sinteger setNumSteps(volume v, integer steps)
{
    if (steps == 0) return VOL_FAILED;
    
    v.step = $FFFF / steps;
    return VOL_SUCCESS;
}

define_function sinteger increment(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = getLevel(v) + v.step;
    
    // Compensate for integer boundry wrap.
    if (l < getLevel(v)) l = $FFFF;
    
    return setLevel(v, l);
}

define_function sinteger decrement(volume v)
{
    integer l;
    
    if (v.step <= 0) return VOL_PARAM_NOT_SET;
    
    l = getLevel(v) - v.step;
    
    // Compensate for integer boundry wrap.
    if (l > getLevel(v)) l = $0000;
    
    return setLevel(v, l);
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

