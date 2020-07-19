#########################################################################################
# Copyright (c) Leet. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#
# Localized resources for Leet.Build.Help module.
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
Get_LeetBuildHelp_Buildstrapper_Synopsis = Provides buildstrapping for Leet.Build scripts. Use -ExtensionTopic, -TaskTopic or both to get more information about specified topic.
Get_LeetBuildHelp_HandlerNotFound_Target = No target hadler was found for '{0}' target.
Error_GetLeetBuildHelp_Reason = Could not get Leet.Build help: {0}
Reason_GraphPathNotFileSystem_GraphPath = Specified path to the graph file '{0}' is not a path of file system provider.
Reason_GraphPathToContainer_GraphPath = Specified path to the graph file '{0}' points to a directory.
Reason_GraphPathExists_GraphPath = File specified by graph path '{0}' already exists. Remove the file manually or use -Force switch to override an existing file.
###PSLOC
'@
