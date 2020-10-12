# Extensibility

LeetABit.Build toolset by default does not load any modules to build projects. It allows user to declare which platforms
and languages the projects located in the repository to load. This loading mechanism is an extensibility point of the
LeetABit.Build toolset. An extension to the toolset is any piece of PowerShell code that registers itself in
LeetABit.Build.Extensibility module. The registration is performed via Register-BuildExtension cmdlet which allows extension to register
[project resolver](ProjectResolvers.md). In addition the extension may provide set of [Build Tasks](BuildTasks.md) for its projects. This may be achieved with use of Register-BuildTask cmdlet.
