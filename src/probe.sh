#! env bash

set -u

function content_filter() {
cat <<END
def live(list): select(has("ip"));
def render(entry): { ip: .ip, ports: [.ports[] | .port] };
map(live(.) | render(.))
END
}

function extract_viable() {
  jq "$(content_filter)"
}

function extract_ips() {
  jq -r '.[] | .ip'
}

function fix_json() {
  echo '['
  sed -e 's/finished/"finished"/'
  echo ']'
}

function ensure_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    if [ -e "$dir" ]; then
      rm -r "$dir" || return 1
      mkdir "$dir" || return 2
    fi
  else
    mkdir "$dir" || return 2
  fi
  return 0
}

function probe_one() {
  local dir="$1"
  local host="$2"
  local out="${dir}/${host}.html"
  local hdr="${dir}/${host}.hdr"
  echo curl "$host" -o "$out" -D "$hdr" || return 1
  curl --header 'accept-encoding: gzip;q=0,deflate,sdch' \
    "$host" -o "$out" -D "$hdr" -m 5 || return 1
  return 0
}

function probe_all() {
  local dir="$1"
  local target
  ensure_dir "$dir"
  while read -r target || [ -n "$target" ]; do
    probe_one "$dir" "$target"
  done
}

fix_json | extract_viable | extract_ips | probe_all "$SCAN_OUTDIR"
