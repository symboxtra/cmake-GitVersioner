# Git Versioner for CMake

Version numbers are hard.

It was easier with SVN where the revision number got increased for every commit.
Revision `342` was clearly older than revision `401`.
But this is not feasible in git because branching is so common (and that's a good thing).
`342` commits could mean multiple commits on different branches.
Not even the latest common commit is clear in history.

This project is a derivative of Pascal Welsch's [gradle-GitVersioner](https://github.com/passsy/gradle-GitVersioner).
It aims to bring the SVN simplicity of build numbers and more back to git for your cross-platform CMake projects.

#### Read Pascal's story behind this on [Medium](https://medium.com/@passsy/use-different-build-numbers-for-every-build-automatically-using-a-gradle-script-35577cd31b19#.g8quoji2e).

## Idea

Just count the commits of the default branch (`master` or `develop` in most cases) as the base revision.
The commits on the feature branch are counted too, but are shown separately.

This technique is often used and far better than just a SHA1 of the latest commit.
But I think it gives too much insight into the project.
Once a client knows `commit count == version number` they start asking why the commit count is so high/low for the latest release.

That's why this versioner adds the project age (initial commit to latest commit) as seconds part to the revision.
By default, one year equals `1000` increments.
This means that the revision count increases approximately every `8.67` hours.
When you started your project half a year ago and you have `325` commits the revision is something around `825`.

When working on a feature branch, this versioner adds a two char identifier of the branch name and the commit count since branching.
When you are building and have uncommitted files, it adds the count of the uncommitted files and `-dirty`.


## Understanding the Version

#### Normal build number
```
1083
```

`1083` : number of commits + time component. This revision is in the `default` branch.

#### On a feature branch
```
1083-dm4
```

`-dm4` : `4` commits since branching from revision `1083`. First two `[a-z]` chars of the SHA-1 hashed branch name.
Clients don't have to know about your information and typos in branch names.
But you have to be able to distinguish between different builds of different branches.

#### Build with local changes
```
1083-dm4(6)-dirty
```

`(6)-dirty` : 6 uncommitted but changed files. Hopefully nothing a client will ever see. But you know that your version is a work in progress with some local changes.

#### Build with CI service detected
```
123.21CI-dm
```

`CI` : A CI service has been detected. 
Since many CI services only shallow clone git repositories, the CI build number will be used instead of the git based components.
Auto-detection will currently occur on ~20 different CI services.

`123` : Build number retrieved from the CI environment.

`21` : Optional job number retrieved from the CI environment. This is only applicable on some CI services.

## Usage

Configure the plugin in your top level `CMakeLists.txt`.

```CMake

# Top-level CMakeLists.txt where you can add configuration options common to all sub-projects/modules.

cmake_minimum_required (VERSION 3.5)

include (GitVersioner.cmake)

# Optional: configure the versioner
set (GIT_VERSIONER_DEFAULT_BRANCH "develop")                                # Default: "master"
set (GIT_VERSIONER_STABLE_BRANCHES "release" "next" "someOtherBranch")      # Default: []
set (GIT_VERSIONER_YEAR_FACTOR 1200)                                        # Default: 1000
set (GIT_VERSIONER_DIRTY_ENABLED true)                                      # Default: false
set (GIT_VERSIONER_LOCAL_CHANGES_ENABLED true)                              # Default: false
set (GIT_VERSIONER_AUTO_DETECT_CI false)                                    # Default: true; prevents issues with shallow clones

git_versioner_get_version(VERSION_RESULT)

message (STATUS "Build Number: ${VERSION_RESULT}")

```

## License

```
Copyright 2018 Symboxtra Software
Copyright 2016 Pascal Welsch

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
