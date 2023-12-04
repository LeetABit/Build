#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
Error_SelectCommandArgumentSet_Reason = Could not select argument set for the command: {0}
Error_SetCommandArgument_Reason = Could not set command argument: {0}
Exception_NamedParameterValueMissing_ParameterName = Could not find value for parameter '{0}'.
Exception_PositionalParameterValueMissing_ParameterCount = Could not find value(s) for last {0} positional parameter(s).
Exception_IncorrectJsonFileFormat = File is not a correct JSON file.
Message_InitializingConfigurationFromFile_FilePath = Initializing configuration using '{0}' as fallback file.
Operation_Clear = Clear.
Operation_Overwrite = Overwrite.
Reason_ArgumentAlreadySet_ParameterName = Argument for parameter '{0}' has been already set. To override already assigned value use -Force switch.
Reason_MultipleParameterSetsMatch_FirstParameterSet_SecondParameterSet = Specified arguments may be used to run the command using two disjoint parameter sets: '{0}' and '{1}'.
Reason_NoMatchingParameterSetFound_NewLine_Errors = No matching parameter set has been found.{0}{1}
Resource_CurrentCommandArgumentSet = Current command argument collection.
###PSLOC
'@
