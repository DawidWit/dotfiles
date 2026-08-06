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

pass 'tmux weather caches complete readings safely across concurrent refreshes'
