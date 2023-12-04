﻿#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
Write_Invocation_ExecutingCommandWithParameters_CommandName = Executing '{0}\\{1}' command with parameters:
Write_StepFinished_BuildFailed = Build task has failed.
Write_StepFinished_NoStepStarted = No build step has been started yet.
Write_StepFinished_Success = Success.
BreakingError = Build execution has been terminated due to breaking error.
###PSLOC
'@
