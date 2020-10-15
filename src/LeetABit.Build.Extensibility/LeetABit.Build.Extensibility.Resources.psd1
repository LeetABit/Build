#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#
# Localized resources for LeetABit.Build module.
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
Error_InvokeBuildTask_Reason = Could not invoke build task: {0}
Error_RegisterBuildTask_Reason = Could not register build task: {0}
Error_RegisterBuildExtension_Reason = Could not register build extension: {0}
Error_ResolveProject_Reason = Could not resolve project path: {0}
Error_UnregisterBuildTask_Reason = Could not unregister build task: {0}
Error_UnregisterBuildExtension_Reason = Could not unregister build extension: {0}
Exception_ExtensionNotFound_ExtensionName = Build extension '{0}' has not been registered. Please make sure that the extension name is specified correctly. To list all available build extensions use 'help' command.
Exception_TaskNotFound_ExtensionName_TaskName = Build extension '{0}' does not have task '{1}' registered. Please make sure that the task name is specified correctly. To list all available task for this extension use 'help -Extension {0}' command.
Exception_ChildTaskNotFound_ExtensionName_TaskName = Task being registered specifies task '{1}' as its child task, but build extension '{0}' does not have task such task registered. Please make sure that the child task name is specified correctly. To list all available task for this extension use 'help -Extension {0}' command.
Exception_DefaultTaskNotFound_ExtensionName = Build extension '{0}' does not have default task registered. Please make sure that the extension name is specified correctly. To list all available task for this extension use 'help -Extension {0}' command.
Exception_TaskAlreadyRegistered_ExtensionName_TaskName = Task '{1}' has been already registered for build extension '{0}'. To override already registered task specify -Force parameter.
Exception_ProjectResolverAlreadyRegistered_ExtensionName = Project resolver has been already registered for build extension '{0}'. To override already registered project resolver specify -Force parameter.
Exception_CouldNotDetectExtensionName = Could not detect name of the build extension being registered. Please specify build extension name manually when calling Register-BuildExtension of make sure that the registration is being made from within a module to use it's name as name of the extension.
Reason_ExtensionProjectResolverInvalidArray_ExtensionName_ArrayLength = Project resolver for extension '{0}' returned array of invalid length: {1}. Supported project resolver output is a single String as indication of resolved project path for the same extension or 2 items array as an indication of resolver project path and name of the extension that shall be used for further project resolution respectively. Please contact with extension development team for further instructions.
Reason_RepositoryProjectResolverInvalidArray_ArrayLength = Project resolver for repository returned array of invalid length: {0}. Supported project resolver output is a single String as indication of resolved project path for responsible extension detection or 2 items array as an indication of resolver project path and name of the extension that shall be used for further project resolution respectively. Please make sure that the repository project resolver returns data in compliance with this contract.
Reason_RepositoryProjectResolverInvalidType_TypeName = Project resolver for repository returned invalid data type: '{0}'. Supported project resolver output is a single String as indication of resolved project path for responsible extension detection or 2 items array as an indication of resolver project path and name of the extension that shall be used for further project resolution respectively. Please make sure that the repository project resolver returns data in compliance with this contract.
Reason_ExtensionProjectResolverInvalidType_ExtensionName_TypeName = Project resolver for extension '{0}' returned invalid data type: '{1}'. Supported project resolver output is a single String as indication of resolved project path for the same extension or 2 items array as an indication of resolver project path and name of the extension that shall be used for further project resolution respectively. Please contact with extension development team for further instructions.
Reason_NoExtensionForTask_TaskName = Could not find registered extension for task '{0}'. Please make sure that the provided task name is correct and that the required build extension is properly installed.
Reason_NoExtensionForDefaultTask = Name of the task has not been specified and an extension with default task registered could not be found. Please make sure that the required build extension is properly installed.
Invoke = Invoke
Unregister = Unregister
AllTasks_ExtensionName = All tasks from extension '{0}'.
BuildTask_ExtensionName_TaskName_ProjectPath = Build task '{1}' from extension '{0}' on project located at '{2}'.
BuildTask_ExtensionName_TaskName = Build task '{1}' from extension '{0}'.
BuildExtension_ExtensionName = Build extension '{0}'.
ProjectResolver_ExtensionName = Project resolver from extension '{0}'.
###PSLOC
'@
