#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
weather="$repo/dot_local/bin/executable_tmux-weather"

rain_cache="$tmp_dir/rain-cache"
rain=$(XDG_CACHE_HOME="$rain_cache" TMUX_WEATHER_RAW='Light rain:+12°C' bash "$weather")
assert_eq '☂ 12°C' "$rain"

sun_cache="$tmp_dir/sun-cache"
sun=$(XDG_CACHE_HOME="$sun_cache" TMUX_WEATHER_RAW='Sunny:-3°C' bash "$weather")
assert_eq '☀ -3°C' "$sun"

invalid_cache="$tmp_dir/invalid-cache"
if invalid=$(XDG_CACHE_HOME="$invalid_cache" TMUX_WEATHER_RAW='Unknown location: weather unavailable' bash "$weather"); then
  :
fi
assert_eq '' "$invalid"

concurrent_cache="$tmp_dir/concurrent-cache"
XDG_CACHE_HOME="$concurrent_cache" TMUX_WEATHER_RAW='Sunny:+8°C' bash "$weather" >/dev/null
printf '0' >"$concurrent_cache/tmux-weather/last-attempt"

XDG_CACHE_HOME="$concurrent_cache" TMUX_WEATHER_RAW='Light rain:+12°C' TMUX_WEATHER_FETCH_DELAY=1 bash "$weather" >"$tmp_dir/first-output" &
first_pid=$!
XDG_CACHE_HOME="$concurrent_cache" TMUX_WEATHER_RAW='Light rain:+12°C' TMUX_WEATHER_FETCH_DELAY=1 bash "$weather" >"$tmp_dir/second-output" &
second_pid=$!

sleep 0.1
[ -d "$concurrent_cache/tmux-weather/lock" ] || fail 'expected an active weather cache lock during fetch'

wait "$first_pid"
wait "$second_pid"

assert_eq '☂ 12°C' "$(<"$concurrent_cache/tmux-weather/data")"
[ ! -d "$concurrent_cache/tmux-weather/lock" ] || fail 'weather cache lock was not removed'

orphan_cache="$tmp_dir/orphan-cache"
orphan_dir="$orphan_cache/tmux-weather"
orphan_reclaim="$orphan_dir/lock/reclaim"
mkdir -p "$orphan_reclaim"
printf '%s' "$(( $(date +%s) - 61 ))" >"$orphan_dir/lock/created"
printf '%s' "$(( $(date +%s) - 61 ))" >"$orphan_reclaim/created"
printf '%s' '☀ 8°C' >"$orphan_dir/data"

orphan_recovery=$(XDG_CACHE_HOME="$orphan_cache" TMUX_WEATHER_RAW='Light rain:+12°C' bash "$weather")
assert_eq '☂ 12°C' "$orphan_recovery"
[ ! -d "$orphan_dir/lock/reclaim" ] || fail 'orphaned reclaim gate was not removed'
[ ! -d "$orphan_dir/lock" ] || fail 'recovered weather lock was not removed'

wait_for_path() {
  local file attempts
  file="$1"
  attempts=0
  while [ ! -e "$file" ]; do
    attempts=$((attempts + 1))
    [ "$attempts" -le 100 ] || fail "timed out waiting for $file"
    "$system_sleep" 0.01
  done
}

reclaim_cache="$tmp_dir/reclaim-cache"
reclaim_dir="$reclaim_cache/tmux-weather"
reclaim_lock="$reclaim_dir/lock"
control_dir="$tmp_dir/reclaim-control"
mkdir -p "$reclaim_lock" "$control_dir"
printf '%s' "$(( $(date +%s) - 61 ))" >"$reclaim_lock/created"
printf '%s' '☀ 8°C' >"$reclaim_dir/data"

system_rm=$(command -v rm)
system_mv=$(command -v mv)
system_sleep=$(command -v sleep)
race_path="$repo/tests/fixtures/tmux-weather-reclaim-race"

PATH="$race_path:$PATH" TMUX_WEATHER_SYSTEM_RM="$system_rm" TMUX_WEATHER_SYSTEM_MV="$system_mv" TMUX_WEATHER_SYSTEM_SLEEP="$system_sleep" TMUX_WEATHER_RECLAIM_CONTROL_DIR="$control_dir" TMUX_WEATHER_TEST_LABEL=one TMUX_WEATHER_TEST_LOCK="$reclaim_lock" XDG_CACHE_HOME="$reclaim_cache" TMUX_WEATHER_RAW='Sunny:+8°C' TMUX_WEATHER_FETCH_DELAY=1 bash "$weather" >"$tmp_dir/reclaimer-one-output" &
reclaimer_one_pid=$!
wait_for_path "$control_dir/first-claim"

PATH="$race_path:$PATH" TMUX_WEATHER_SYSTEM_RM="$system_rm" TMUX_WEATHER_SYSTEM_MV="$system_mv" TMUX_WEATHER_SYSTEM_SLEEP="$system_sleep" TMUX_WEATHER_RECLAIM_CONTROL_DIR="$control_dir" TMUX_WEATHER_TEST_LABEL=two TMUX_WEATHER_TEST_LOCK="$reclaim_lock" XDG_CACHE_HOME="$reclaim_cache" TMUX_WEATHER_RAW='Sunny:+8°C' TMUX_WEATHER_FETCH_DELAY=1 bash "$weather" >"$tmp_dir/reclaimer-two-output" &
reclaimer_two_pid=$!
wait "$reclaimer_two_pid"
[ ! -f "$control_dir/fetch-two" ] || fail 'stale-lock reclaimer started a second active fetch'

: >"$control_dir/release-first-claim"
wait_for_path "$control_dir/fetch-one"
: >"$control_dir/release-fetch-one"
wait "$reclaimer_one_pid"

pass 'tmux weather caches complete readings safely across concurrent refreshes'
