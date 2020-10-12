# Overview

LeetABit.Build is a multi-platform, extensible and automated build toolset written in PowerShell. Its main goal is to make project build tasks
as simple as possible but with the possibility to manually tailor its workflow for many complex scenarios. The simplest way to start using it
is to include any of the toolset [buildstrapper](Buildstrappers.md) scripts in the repository and list any language or platform specific
extensions in a [repository configuration file](RepositoryConfigurationFile.md). This setup shall be sufficient for any single language
project supported by available [extension plugins](Plugins.md). Each plugin extends the toolset via [extensibility points](Extensibility.md)
defined in LeetABit.Build.Extensibility module. LeetABit.Build toolset comes with one extension plugin loaded by default. It is
LeetABit.Build.Help plugin that provides one build task - the help task. To run this or any other available task simply specify its name as
a parameter for the buildstrapper script.

For Linux:
```shell
> ./run.sh help
```

For Windows:
```shell
> .\run.cmd help
```

For PowerShell:
```shell
> ./run.ps1 help
```

Help task runs [`LeetABit.Build.Help\Get-BuildHelp`](../Reference/LeetABit.Build.Help/Get-BuildHelp.md) PowerShell cmdlet and may be invoked
using the same set of parameters via the buildstrapper script. It is used to discover loaded extension plugins and available build tasks. Other
plugins may extend toolset in two ways. Most often both ways are used to deliver full functionality of the target language or platform. First
way is to define [project resolver](ProjectResolver.md) and the second one is to provide [Build Tasks](BuildTasks.md).

Build task execution process consists of the following phases:

## Buildstrapping

This phase transfers control from a platform dependant script to a configured version of LeetABit.Build module in a pre-defined version of PowerShell.
More details about this phase can be found on the [Buildstrappers](Buildstrappers.md) page.

## Arguments initialization

Task execution in a LeetABit.Build module begins in [Build-Repository](../Reference/LeetABit.Build/Build-Repository.md) cmdlet by setting
arguments for task execution. More details about this phase can be found on the [Arguments](Arguments.md) page.

## Extension modules import

After setting up all specified arguments Build-Repository cmdlet tries to install and import configured extension modules. For list of all extension
modules see [Plugins](Plugins.md) page.

## Repository Extension Script

When all configured extension modules are imported Build-Repository tries to load any existing repository extension script to allow fine tuned
customization for the repository. More details about this phase may be found on [Repository Extension Script](Customization.md#repository-extension-script).

## Project resolution

After executing all repository extension scripts Build-Repository cmdlet runs project resolution phase. If any repository extension script registers
a project resolver it will be executed as a starting point. Otherwise all resolvers for extensions supporting specified task will be executed in no
particular order. If task name is not specified only extensions with default task are considered. Visit [Project Resolvers](ProjectResolvers.md) page
to learn how to implement them.

## Task execution

When all the resolvers are run and paths to the projects with associated extensions are gathered task execution phase is performed. During this phase the task
configured via `TaskName` parameter is executed for each resolved project. If no `TaskName` parameter is specified a default extension's task is executed. 
To learn more visit [Build Tasks](BuildTasks.md) page.
