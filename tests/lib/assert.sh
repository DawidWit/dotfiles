fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "expected [$1], got [$2]"; }
assert_contains() { case "$1" in *"$2"*) ;; *) fail "expected [$1] to contain [$2]" ;; esac; }
assert_success() { "$@" || fail "command failed: $*"; }
pass() { printf 'PASS: %s\n' "$1"; }
