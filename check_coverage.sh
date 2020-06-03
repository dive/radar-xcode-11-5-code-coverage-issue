#!/bin/sh

set +e

INCREMENTAL_XCRESULT="./incremental.xcresult"
WHOLEMODULE_XCRESULT="./wholemodule.xcresult"

function bootstrap {
    if [ ! -d "CocoaLumberjack" ]; then
        git clone https://github.com/CocoaLumberjack/CocoaLumberjack.git
    fi
}

function cleanUp {
    rm -Rf "$INCREMENTAL_XCRESULT"
    rm -Rf "$WHOLEMODULE_XCRESULT"

    pushd CocoaLumberjack
    git checkout .
    popd
}

function produceCodeCoverage {
    rm -Rf build
    sed -i '' -E "s/^SWIFT_COMPILATION_MODE \= .*$/$2/g" CocoaLumberjack/Configs/Module-Debug.xcconfig
    xcodebuild test \
               -project CocoaLumberjack/Tests/Tests.xcodeproj \
               -scheme "Swift Tests" \
               -configuration Debug \
               -resultBundlePath "$1" \
               -quiet
}

function showCodeCoverage {
    printf "%s\n\n" "=== Coverage for $1 ==="
    xcrun xccov view --only-targets --report "$1"
}

function produceCoverageDiff {
    printf "%s\n\n" "=== Diff ==="
    xcrun xccov diff --json "$INCREMENTAL_XCRESULT" "$WHOLEMODULE_XCRESULT" | python -m json.tool
}

bootstrap
cleanUp
produceCodeCoverage "$INCREMENTAL_XCRESULT" "SWIFT_COMPILATION_MODE = incremental"
produceCodeCoverage "$WHOLEMODULE_XCRESULT" "SWIFT_COMPILATION_MODE = wholemodule"
showCodeCoverage $INCREMENTAL_XCRESULT
showCodeCoverage $WHOLEMODULE_XCRESULT
produceCoverageDiff
cleanUp

set -e

unset bootstrap;
unset cleanUp;
unset produceCodeCoverage;
unset showCodeCoverage;
unset produceCoverageDiff;
