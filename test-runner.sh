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

  # this timeout is for the overall test process
  ( sleep ${TEST_TIMEOUT} ) &
  pidwatcher=$!

  # browser #1
  ( /usr/bin/docker run --rm=true -m 3g -c 3 -p 80:80 -p 443:443 otalk/webrtc-tester "google-chrome" $TEST_HOST "${ROOM}" "${TEST_COND}" >> log1.log 2>&1 ; kill $pidwatcher 2> /dev/null ) 2>/dev/null &
  pidwatch=$!

  # browser #2
  ( /usr/bin/docker run --rm=true -m 3g -c 3 -p 80:80 -p 443:443 otalk/webrtc-tester "google-chrome" $TEST_HOST "${ROOM}" "${TEST_COND}" >> log2.log 2>&1 ; kill $pidwatcher 2> /dev/null ) 2>/dev/null &
  pidwatch2=$!

  #echo "${pidwatcher} watching ${pidwatch} ${pidwatch2}"

  if wait $pidwatcher 2>/dev/null; then
    echo "--- timedout"
    cat log1.log
    cat log2.log
  fi
  # do nothing in the case of success
) 200>/var/lock/webrtc-tester.exclusivelock
