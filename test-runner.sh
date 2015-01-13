#!/bin/bash
(
  flock -x -w 10 200 || exit 1

  [ -z "$TEST_TIMEOUT" ] && TEST_TIMEOUT="120"
  DISPLAY=
  [ -z "$TEST_HOST" ] && TEST_HOST=${1:-"talky.io"}
  ROOM="automatedtesting_${RANDOM}"
  [ -z "$TEST_COND" ] && TEST_COND=${2:-"P2P connected"} # talky
  #TEST_COND="data channel open" # talky pro
  #TEST_COND="ICE connection state changed to: connected" # apprtc
  #TEST_COND="onCallActive" # go
  #TEST_COND="Data channel opened" # meet

  echo "-- testing $TEST_HOST for condition $TEST_COND"

  # make sure we kill any Xvfb instances
  function cleanup() {
    exec 3>&2
    exec 2>/dev/null
    pkill Xvfb
    pkill -HUP -P $pidwatch
    pkill -HUP -P $pidwatch2
    exec 2>&3
    exec 3>&-
  }
  trap cleanup EXIT

  # this timeout is for the overall test process
  ( sleep ${TEST_TIMEOUT} ) &
  pidwatcher=$!

  # browser #1
  ( ./test-browser.sh google-chrome $TEST_HOST "${ROOM}" "${TEST_COND}" >> log1.log 2>&1 ; kill $pidwatcher 2> /dev/null ) 2>/dev/null &
  pidwatch=$!

  # browser #2
  ( ./test-browser.sh chromium-browser $TEST_HOST "${ROOM}" "${TEST_COND}" >> log2.log 2>&1 ; kill $pidwatcher 2> /dev/null ) 2>/dev/null &
  pidwatch2=$!

  #echo "${pidwatcher} watching ${pidwatch} ${pidwatch2}"

  if wait $pidwatcher 2>/dev/null; then
    echo "--- timedout"
    cat log1.log
    cat log2.log
  fi
  # do nothing in the case of success
) 200>/var/lock/webrtc-tester.exclusivelock
