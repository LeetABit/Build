# Tasks

Build tasks are the key concept of LeetABit.Build toolset. They implement build actions for a particular extension. Basically a build task
is a sequence of script blocks. It may be also composed of a sequence of different tasks or of mix of other tasks and script blocks.
Execution of the task happens sequentially in the definition order. To prevent multiple executions of the same tasks a list of all tasks
already ran is maintained during the execution. Task may also define a condition that must hold true to make the task execution happen.
