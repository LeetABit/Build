# Project Resolvers

Project resolver is an extensibility point of the LeetABit.Build toolset which allows discovery of the project files inside repository source code.
It has a form of a script block that is provided when calling Register-BuildExtension cmdlet. This script block is executed by the toolset during
each build task execution.   Most important argument passed to project resolver is a value for `-ProjectPath` parameter. It could be a path to
a directory or file. Resolution begins with a path to repository source directory. To guarantee that the resolution ever finish resolver should return
no value if it does not find any supported projects inside passed `$ProjectPath`. Resolver job is to return set of paths that are recognized by its
extension or return set of paths as a hints for other extension for further resolution. Any returned path that is paired with the same extension name
as the resolver is considered as accepted by the extension. To mark returned path as accept by the extension a resolver amy also return a path with
no extension associated. For example an extension for dotnet may return a set of paths to all sln files found in the passed `$ProjectPath` with no
extension associated to end its resolution.
