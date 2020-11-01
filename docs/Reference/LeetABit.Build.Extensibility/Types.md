# ```class ExtensionDefinition```
Provides detailed information about the registered extension.

## Constructors
### ```ExtensionDefinition([String] $name)```
*Initializes a new instance of the ExtensionDefinition class.*

## Properties
### ```[String] $Name```
*Name of the registered extension.*

### ```[ScriptBlock] $Resolver```
*Name of the registered extension.*

### ```[Dictionary[String,TaskDefinition]] $Tasks```
*Name of the registered extension.*

## Methods
### ```[ExtensionDefinition] Clone()```
*Creates a new instance of the ExtensionDefinition class with all the data copied from this instance.*

# ```class TaskDefinition```
*Provides information about defined task.*

## Constructors
### ```TaskDefinition([String] $name, [Boolean] $isDefault, [Object] $condition, [Object[]] $jobs)```
*Initializes a new instance of the TaskDefinition class.*

### Properties
### ```[String] $Name```
*Name of the task.*

### ```[Boolean] $IsDefault```
*Describes whether the task represented by the current object is the default task or not.*

### ```[Object] $Condition```
*Condition for current task execution.*

### ```[Object[]] $Jobs```
*Array of a task's jobs.*

## Methods
### ```[TaskDefinition] Clone()```
*Creates a new instance of the TaskDefinition class with all the data copied from this instance.*
