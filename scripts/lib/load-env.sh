# Shared .env loading, layered so cross-repo shared settings live in exactly
# one place instead of being duplicated in every repo's own .env. Later
# layers override earlier ones; every layer is optional except the root
# bootstrap. Missing files -> today's behavior, unchanged.
#
#   1. $REPO/.env                                  bootstrap (DATA_DIR)
#   2. $DATA_DIR/config/common/.env                cross-repo shared values
#   3. $DATA_DIR/config/DevOps.Scanner.SDK/.env     this repo's own overrides
#
# Requires $REPO to already be set by the caller. Source it, don't execute it:
#   . "$REPO/scripts/lib/load-env.sh"
[ -f "$REPO/.env" ] && { set -a; . "$REPO/.env"; set +a; }
if [ -n "${DATA_DIR:-}" ]; then
  [ -f "$DATA_DIR/config/common/.env" ] && { set -a; . "$DATA_DIR/config/common/.env"; set +a; }
  [ -f "$DATA_DIR/config/DevOps.Scanner.SDK/.env" ] && { set -a; . "$DATA_DIR/config/DevOps.Scanner.SDK/.env"; set +a; }
fi
