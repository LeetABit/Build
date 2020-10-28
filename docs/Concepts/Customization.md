# Customization

Out of the box LeetABit.Build toolset provides fully automated experience which works great for a simple projects with no complex
internal dependencies. By default LeetABit.Build loads minimal set of modules with no support for any specific build mechanism,
languages nor platforms. The only task it provides is "help" that gives information about all other available tasks and extensions.
To control the toolset or load additional extensions and tasks a build parameters may be used. To learn more about build parameters
see [Arguments](Arguments.md) page. To load additional extensions before task execution LeetABit.Build uses `-ExtensionModules`
parameter. To learn how to use this parameter take a look at [Build-Repository](../Reference/LeetABit.Build/Build-Repository.md)
To programmatically control loaded extensions and project resolution the Repository Extension Script may be used.

## Repository Extension Script

Repository Extension Script is any file inside repository root directory hierarchy with a name 'LeetABit.Build.Repository.ps1'.
LeetABit.Build module executes these script files before build command. Repository Extension Script may contain any PowerShell
code but most common use case is to define custom project resolver. In addition repository maintainer may override any build tasks
defined by toolset extensions and provide tasks that are better suited for their projects. To learn more about Extensibility
mechanism of LeetABit.Build toolset see [Extensibility](Extensibility.md) page. See [Build Tasks](BuildTasks.md) page to learn more about
build tasks.