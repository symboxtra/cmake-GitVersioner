##################################################################################
 # Copyright (C) 2018 Symboxtra Software
 # Copyright (C) 2016 Pascal Welsch
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #    http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #
##################################################################################

if (NOT DEFINED GIT_VERSIONER_DEFAULT_BRANCH)
    set (GIT_VERSIONER_DEFAULT_BRANCH "master")
endif ()
if (NOT DEFINED GIT_VERSIONER_STABLE_BRANCHES)
    set (GIT_VERSIONER_STABLE_BRANCHES "")
endif ()
if (NOT DEFINED GIT_VERSIONER_YEAR_FACTOR)
    set (GIT_VERSIONER_YEAR_FACTOR 1000)
endif ()
if (NOT DEFINED GIT_VERSIONER_SNAPSHOT_ENABLED)
    set (GIT_VERSIONER_SNAPSHOT_ENABLED false)
endif()
if (NOT DEFINED GIT_VERSIONER_LOCAL_CHANGES_ENABLED)
    set (GIT_VERSIONER_LOCAL_CHANGES_ENABLED false)
endif ()
# TODO: Not implemented yet
if (NOT DEFINED GIT_VERSIONER_SHORT_NAME)
    set (GIT_VERSIONER_SHORT_NAME "")
endif ()

function(check_git_error PROCESS_RESULT PROCESS_OUTPUT PROCESS_ERROR)

    if (PROCESS_RESULT GREATER 0)
        message (STATUS "Error Code:\t\t${PROCESS_RESULT}")
        message (STATUS "Standard Output:\t${PROCESS_OUTPUT}")
        message (STATUS "Error Output: \t${PROCESS_ERROR}")
        message (FATAL_ERROR "Git Error: See above.")
    endif ()

endfunction ()

function(lines_to_list LINES RESULT_VAR)

    string (LENGTH "${LINES}" OUTPUT_LENGTH)

    if (OUTPUT_LENGTH GREATER 0)
        string (REPLACE ";" "" LINES "${LINES}")
        string (REPLACE ":" "" LINES "${LINES}")

        # Turn lines into list by replacing newline with delimiter
        string (REPLACE "\n" ";" RESULT_LIST "${LINES}")
        set (${RESULT_VAR} ${RESULT_LIST} PARENT_SCOPE)
    else ()
        set (RESULT_LIST "")
    endif ()

endfunction()

# Get the SHA1 hash of the branch name
# Sadly, don't have access to base64 encoding
function(get_tiny_branch_name ORIGINAL_NAME LENGTH RESULT_VAR)

    string (SHA1 BRANCH_NAME_HASH "${ORIGINAL_NAME}")
    string (REGEX REPLACE "[0-9]+" "" ALPHA_ONLY_HASH "${BRANCH_NAME_HASH}")

    string (SUBSTRING "${ALPHA_ONLY_HASH}" 0 ${LENGTH} SHORT_NAME)

    set (${RESULT_VAR} ${SHORT_NAME} PARENT_SCOPE)

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")

endfunction ()

function (git_versioner_get_version RESULT_VAR)

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")

    find_package (Git)


    # Check that git works and that CMAKE_SOURCE_DIR is a git repository
    execute_process (
        COMMAND ${GIT_EXECUTABLE} status

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    if (PROCESS_RESULT EQUAL 69)
        message (STATUS "Error Code:\t\t${PROCESS_RESULT}")
        message (STATUS "Standard Output:\t${PROCESS_OUTPUT}")
        message (STATUS "Error Output: \t${PROCESS_ERROR}")
        message (FATAL_ERROR "git returned with error 69\nIf you are a Mac user, see the output above to fix this issue.")
    endif ()

    if (PROCESS_RESULT EQUAL 128)
        message (STATUS "Error Code:\t\t${PROCESS_RESULT}")
        message (STATUS "Standard Output:\t${PROCESS_OUTPUT}")
        message (STATUS "Error Output: \t${PROCESS_ERROR}")
        message (FATAL_ERROR "${CMAKE_SOURCE_DIR} is not a git repository.")
    endif ()

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get current branch
    execute_process (
        COMMAND ${GIT_EXECUTABLE} symbolic-ref --short -q HEAD

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")
    set (CURRENT_BRANCH ${PROCESS_OUTPUT})

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")

    if (CURRENT_BRANCH IN_LIST GIT_VERSIONER_STABLE_BRANCHES)
        set (GIT_VERSIONER_DEFAULT_BRANCH ${CURRENT_BRANCH})
    endif ()


    # Get current commit
    execute_process (
        COMMAND ${GIT_EXECUTABLE} rev-parse HEAD

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")
    set (CURRENT_COMMIT ${PROCESS_OUTPUT})

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get log
    execute_process (
        COMMAND ${GIT_EXECUTABLE} log --pretty=format:'%at' --reverse

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    # Replace ' from pretty format and create a list
    string (REPLACE "'" "" PROCESS_OUTPUT "${PROCESS_OUTPUT}")
    lines_to_list("${PROCESS_OUTPUT}" LOG)
    list (GET LOG 0 INITIAL_COMMIT_DATE)

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get local changes
    execute_process (
        COMMAND ${GIT_EXECUTABLE} diff-index HEAD

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    lines_to_list("${PROCESS_OUTPUT}" LOCAL_CHANGES)
    list (LENGTH LOCAL_CHANGES LOCAL_CHANGE_COUNT)

    set (HAS_LOCAL_CHANGES false)
    if (LOCAL_CHANGE_COUNT GREATER 0)
        set (HAS_LOCAL_CHANGES true)
    endif ()

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get commits since revision branch
    # .. limits commits to those reachable from the current branch but not GIT_VERSIONER_DEFAULT_BRANCH
    execute_process (
        COMMAND ${GIT_EXECUTABLE} rev-list ${GIT_VERSIONER_DEFAULT_BRANCH}..

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    # Try again with the remote tracking branch
    if (PROCESS_RESULT GREATER 0)
        execute_process (
            COMMAND ${GIT_EXECUTABLE} rev-list origin/${GIT_VERSIONER_DEFAULT_BRANCH}..

            RESULT_VARIABLE PROCESS_RESULT
            OUTPUT_VARIABLE PROCESS_OUTPUT
            ERROR_VARIABLE PROCESS_ERROR

            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )
    endif ()

    if (PROCESS_RESULT GREATER 0)
        message (STATUS "Could not find branch '${GIT_VERSIONER_DEFAULT_BRANCH}' or 'origin/${GIT_VERSIONER_DEFAULT_BRANCH}'.")
        message (STATUS "Try 'git fetch' to pull down remote branches.")
        message (FATAL_ERROR "\nBranch '${GIT_VERSIONER_DEFAULT_BRANCH}' not found.\n")
    endif ()

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    lines_to_list("${PROCESS_OUTPUT}" FEATURE_LINES)
    list (LENGTH FEATURE_LINES COMMITS_IN_FEATURE_BRANCH)

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get combined history of feature and default
    execute_process (
        COMMAND ${GIT_EXECUTABLE} rev-list ${CURRENT_COMMIT}

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    lines_to_list("${PROCESS_OUTPUT}" DEFAULT_AND_FEATURE_LINES)
    list (LENGTH DEFAULT_AND_FEATURE_LINES D_A_F_L_LENGTH)

    if (D_A_F_L_LENGTH EQUAL 1)
        list (GET DEFAULT_AND_FEATURE_LINES 0 LATEST_DEFAULT_BRANCH_COMMIT_SHA1)
    elseif (D_A_F_L_LENGTH GREATER 0)

        # Create a copy so that we can use REMOVE_ITEM
        # DEFAULT_AND_FEATURE_LINES_EXCEPT is the set DEFAULT_AND_FEATURE_LINES - FEATURE_LINES
        set (DEFAULT_AND_FEATURE_LINES_EXCEPT)
        list (APPEND DEFAULT_AND_FEATURE_LINES_EXCEPT ${DEFAULT_AND_FEATURE_LINES})

        if (NOT COMMITS_IN_FEATURE_BRANCH EQUAL 0)
            list (REMOVE_ITEM DEFAULT_AND_FEATURE_LINES_EXCEPT ${FEATURE_LINES})
        endif ()

        list (LENGTH DEFAULT_AND_FEATURE_LINES_EXCEPT EXCEPT_LENGTH)

        if (EXCEPT_LENGTH GREATER 0)
            list (GET DEFAULT_AND_FEATURE_LINES_EXCEPT 0 LATEST_DEFAULT_BRANCH_COMMIT_SHA1)
        else ()
            set (LATEST_DEFAULT_BRANCH_COMMIT_SHA1 ${CURRENT_COMMIT})
        endif ()

    else ()
        set (LATEST_DEFAULT_BRANCH_COMMIT_SHA1 ${CURRENT_COMMIT})
    endif ()

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Get defaultBranch dates
    execute_process (
        COMMAND ${GIT_EXECUTABLE} log ${LATEST_DEFAULT_BRANCH_COMMIT_SHA1} --pretty=format:'%at' -n 1

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    # Replace ' from pretty format
    string (REPLACE "'" "" PROCESS_OUTPUT "${PROCESS_OUTPUT}")

    # Check if output is numeric
    if (PROCESS_OUTPUT MATCHES "^[0-9]+$")
        set (LATEST_COMMIT_DATE ${PROCESS_OUTPUT})
    else ()
        set (LATEST_COMMIT_DATE ${INITIAL_COMMIT_DATE})
    endif ()

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")

    # Get defaultBranch commit count
    execute_process (
        COMMAND ${GIT_EXECUTABLE} rev-list ${LATEST_DEFAULT_BRANCH_COMMIT_SHA1} --count

        RESULT_VARIABLE PROCESS_RESULT
        OUTPUT_VARIABLE PROCESS_OUTPUT
        ERROR_VARIABLE PROCESS_ERROR

        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    check_git_error("${PROCESS_RESULT}" "${PROCESS_OUTPUT}" "${PROCESS_ERROR}")

    # Check if output is numeric
    if (PROCESS_OUTPUT MATCHES "^[0-9]+$")
        set (COMMIT_COUNT ${PROCESS_OUTPUT})
    else ()
        set (COMMIT_COUNT 0)
    endif ()

    set (PROCESS_RESULT  1)
    set (PROCESS_OUTPUT "")
    set (PROCESS_ERROR "")


    # Calculate time since last common ancestor in defaultBranch
    # CMake only supports integer math
    # Had to put everything in terms of hours to avoid overflow
    # The calculation will still overflow if the project was started ~24.5 years ago
    math (EXPR YEAR_IN_HOURS "24 * 365")
    math (EXPR DIFF "${LATEST_COMMIT_DATE} - ${INITIAL_COMMIT_DATE}")

    if (GIT_VERSIONER_YEAR_FACTOR LESS 0)
        set (TIME 0)
    else ()
        math (EXPR DIFF_HOURS "${DIFF} / 60 / 60")

        math (EXPR PRE_ROUND "${DIFF_HOURS} * ${GIT_VERSIONER_YEAR_FACTOR} * 10 / ${YEAR_IN_HOURS}")
        math (EXPR ROUND_UP "${PRE_ROUND} % 10")

        if (ROUND_UP GREATER 5)
            math (EXPR TIME "${PRE_ROUND} / 10 + 1")
        else ()
            math (EXPR TIME "${PRE_ROUND} / 10")
        endif ()

    endif ()

    math (EXPR COMBINED_VERSION "${COMMIT_COUNT} + ${TIME}")

    # Add (#)-SNAPSHOT if enabled
    set (EXTRA_TAGS "")
    if (GIT_VERSIONER_LOCAL_CHANGES_ENABLED AND HAS_LOCAL_CHANGES)
        set (EXTRA_TAGS "${EXTRA_TAGS}(${LOCAL_CHANGE_COUNT})")
    endif ()

    if (GIT_VERSIONER_SNAPSHOT_ENABLED AND HAS_LOCAL_CHANGES)
        set (EXTRA_TAGS "${EXTRA_TAGS}-SNAPSHOT")
    endif ()

    # Check if we are on a stable/default branch
    if (COMMITS_IN_FEATURE_BRANCH EQUAL 0)
        set (FINAL_NAME "${COMBINED_VERSION}${EXTRA_TAGS}")
    else ()

        if ("${CURRENT_BRANCH}" STREQUAL "")
            string (SUBSTRING "${CURRENT_COMMIT" 0 7 SHORT_BRANCH)
            set (SHORT_BRANCH "${SHORT_BRANCH}-")
        else ()
            get_tiny_branch_name("${CURRENT_BRANCH}" 2 SHORT_BRANCH)
        endif ()

        set (FINAL_NAME "${COMBINED_VERSION}-${SHORT_BRANCH}${FEATURE_BRANCH_COMMITS}${EXTRA_TAGS}")

    endif ()

    set (${RESULT_VAR} ${FINAL_NAME} PARENT_SCOPE)

endfunction ()



