#!/bin/sh

read_env_var() {
  file=$1
  key=$2
  [ -f "$file" ] || return 0
  awk -F= -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      value = substr($0, index($0, "=") + 1)
      found = value
    }
    END {
      if (found != "") print found
    }
  ' "$file"
}

set_env_from_file_if_unset() {
  file=$1
  key=$2
  eval "current_value=\${$key-}"
  if [ -n "${current_value}" ]; then
    return 0
  fi
  value="$(read_env_var "$file" "$key")"
  [ -n "$value" ] || return 0
  export "$key=$value"
}
