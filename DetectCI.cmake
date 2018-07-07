function(detect_ci)

    set (CI_FOUND false)
    set (CI_FOUND false PARENT_SCOPE)

    # Most of these conditions come from the codecov bash script
    # Apache License Version 2.0, January 2004
    # https://github.com/codecov/codecov-bash/blob/master/LICENSE
    if (NOT "$ENV{JENKINS_URL}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "Jenkins")
        set (CI_BUILD_NUMBER "$ENV{BUILD_NUMBER}")

    elseif ("$ENV{CI}" AND "$ENV{TRAVIS}" AND NOT "$ENV{SHIPPABLE}")
        set (CI_FOUND true)
        set (CI_NAME "Travis")
        set (CI_BUILD_NUMBER "$ENV{TRAVIS_JOB_NUMBER}")

        if ("$ENV{TRAVIS_JOB_ID}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{TRAVIS_JOB_ID}")
        endif ()

    elseif ("$ENV{CI}" AND "$ENV{CI_NAME}" STREQUAL "codeship")
        set (CI_FOUND true)
        set (CI_NAME "Codeship")
        set (CI_BUILD_NUMBER "$ENV{CI_BUILD_NUMBER}")

    elseif (NOT "$ENV{CF_BUILD_URL}" STREQUAL "" AND NOT "$ENV{CF_BUILD_ID}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "Codefresh")
        set (CI_BUILD_NUMBER "$ENV{CF_BUILD_ID}")

    elseif (NOT "$ENV{TEAMCITY_VERSION}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "TeamCity")
        set (CI_BUILD_NUMBER "$ENV{TEAMCITY_BUILD_ID}")

    elseif ("$ENV{CI}" AND "$ENV{CIRCLECI}")
        set (CI_FOUND true)
        set (CI_NAME "Circle")
        set (CI_BUILD_NUMBER "$ENV{CIRCLE_BUILD_NUM}")

        if ("$ENV{CIRCLE_NODE_INDEX}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{CIRCLE_NODE_INDEX}")
        endif ()

    elseif (NOT "$ENV{BUDDYBUILD_BRANCH}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "buddybuild")
        set (CI_BUILD_NUMBER "$ENV{BUDDYBUILD_BUILD_NUMBER}")

    elseif (NOT "$ENV{bamboo_planRepository_revision}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "Bamboo")
        set (CI_BUILD_NUMBER "$ENV{bamboo_buildNumber}")

    elseif ("$ENV{CI}" AND "$ENV{BITRISE_IO}")
        set (CI_FOUND true)
        set (CI_NAME "Bitrise")
        set (CI_BUILD_NUMBER "$ENV{BITRISE_BUILD_NUMBER}")

    elseif ("$ENV{CI}" AND "$ENV{SEMAPHORE}")
        set (CI_FOUND true)
        set (CI_NAME "Semaphore")
        set (CI_BUILD_NUMBER "$ENV{SEMAPHORE_BUILD_NUMBER}")

        if ("$ENV{SEMAPHORE_CURRENT_THREAD}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{SEMAPHORE_CURRENT_THREAD}")
        endif ()

    elseif ("$ENV{CI}" AND "$ENV{BUILDKITE}")
        set (CI_FOUND true)
        set (CI_NAME "Buildkite")
        set (CI_BUILD_NUMBER "$ENV{BUILDKITE_BUILD_NUMBER}")

        if ("$ENV{BUILDKITE_JOB_ID}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{BUILDKITE_JOB_ID}")
        endif ()

    elseif ("$ENV{CI}" STREQUAL "drone" OR "$ENV{DRONE}")
        set (CI_FOUND true)
        set (CI_NAME "Drone")
        set (CI_BUILD_NUMBER "$ENV{DRONE_BUILD_NUMBER}")

        if ("$ENV{DRONE_JOB_NUMBER}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{DRONE_JOB_NUMBER}")
        endif ()

    elseif (NOT "$ENV{HEROKU_TEST_RUN_BRANCH}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "Heroku")
        set (CI_BUILD_NUMBER "$ENV{HEROKU_TEST_RUN_ID}")

    elseif ("$ENV{CI}" AND "$ENV{APPVEYOR}")
        set (CI_FOUND true)
        set (CI_NAME "Appveyor")
        set (CI_BUILD_NUMBER "$ENV{APPVEYOR_BUILD_VERSION}")
        # APPVEYOR_BUILD_NUMBER?
        # APPVEYOR_JOB_ID?

    elseif ("$ENV{CI}" AND NOT "$ENV{WERCKER_GIT_BRANCH}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "Wercker")
        set (CI_BUILD_NUMBER "$ENV{WERCKER_MAIN_PIPELINE_STARTED}")

    elseif ("$ENV{CI}" AND "$ENV{MAGNUM}")
        set (CI_FOUND true)
        set (CI_NAME "Magnum")
        set (CI_BUILD_NUMBER "$ENV{CI_BUILD_NUMBER}")

    elseif ("$ENV{SHIPPABLE}")
        set (CI_FOUND true)
        set (CI_NAME "Shippable")
        set (CI_BUILD_NUMBER "$ENV{BUILD_NUMBER}")

    elseif ("$ENV{TDDIUM}")
        set (CI_FOUND true)
        set (CI_NAME "Solano")
        set (CI_BUILD_NUMBER "$ENV{TDDIUM_TID}")

    elseif ("$ENV{GREENHOUSE}")
        set (CI_FOUND true)
        set (CI_NAME "Greenhouse")
        set (CI_BUILD_NUMBER "$ENV{GREENHOUSE_BUILD_NUMBER}")

    elseif (NOT "$ENV{GITLAB_CI}" STREQUAL "")
        set (CI_FOUND true)
        set (CI_NAME "GitLab")
        set (CI_BUILD_NUMBER "$ENV{CI_BUILD_ID}")

        if ("$ENV{CI_JOB_ID}")
            set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}.$ENV{CI_JOB_ID}")
        endif ()

    endif ()

    set (CI_FOUND ${CI_FOUND} PARENT_SCOPE)
    set (CI_NAME "${CI_NAME}" PARENT_SCOPE)
    set (CI_BUILD_NUMBER "${CI_BUILD_NUMBER}" PARENT_SCOPE)

    if (CI_FOUND)
        message (STATUS "DetectCI: ${CI_NAME} CI detected.")
        message (STATUS "DetectCI: Build/Job # - ${CI_BUILD_NUMBER}")
    else ()
        message (STATUS "DetectCI: No CI service detected.")
    endif ()

endfunction ()
