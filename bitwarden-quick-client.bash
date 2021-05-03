# Bitwarden Quick Client
# https://github.com/wwalker/bitwarden-quick-client
# Released under the GPL v2

_bw_log(){
  # shellcheck disable=SC2059
  printf "$@" 1>&2
}

_bw_die(){
  printf "%s\n" "$*"
  printf "Exiting.\n"
  exit 1
}

bw_save_session_id(){
  export BW_SESSION="$1"
  # mkdir -p /run/user/$UID/bw
  mkdir -p /run/user/$UID/bw || { _bw_log "failed to mkdir a safe dir for the session id\n"; return; }
  printf "%s" "$1" > /run/user/$UID/bw/session_id
}

bw_load_session_id(){
  session_id_file=/run/user/$UID/bw/session_id
  [[ -s $session_id_file ]] || return 1
  BW_SESSION=$( cat $session_id_file )
  export BW_SESSION
}

bw_load_last_unlocked(){
  bw_last_unlocked=$( cat /run/user/$UID/bw/bw_last_unlocked )
}

bw_set_last_unlocked(){
  bw_last_unlocked=$EPOCHSECONDS
  printf "%s" "$EPOCHSECONDS" > /run/user/$UID/bw/bw_last_unlocked
}

bw_recently_unlocked(){
  [[ -z "$bw_last_unlocked" ]] && return 1
  local now
  now=$( date +%s )
  (( $(( now - bw_last_unlocked )) <= 300 ))
}

bw_login(){
  local session

  [[ -z "$BW_SESSION" ]] && bw_load_session_id
  bw_recently_unlocked || bw_load_last_unlocked
  bw_recently_unlocked && return 0

  bw=bw
  { [[ -z $(tty) ]] || [[ "not a tty" = "$(tty)" ]]; } && bw=xbw

  # if we are unlocked, then we are also logged in ... Nirvana
  bw unlock --check 1>&2 && bw_set_last_unlocked; return 0

  if bw login --check 1>&2
  then
    # We are logged in but locked; so, we have to manually unlock
    session=$( $bw unlock --raw ) || { _bw_log "Unlock failed: <%s>\n" "$session"; return 1; }
  else
    # We are not even logged in, get our login if it's not provided
    [[ -z "$BW_EMAIL" ]] && read -r -t 20 -p 'Enter your login to lastpass: ' BW_EMAIL
    [[ -z "$BW_EMAIL" ]] && return 1

    session=$( $bw login "$BW_EMAIL" --raw ) || { _bw_log "login failed"; return 1; }
  fi

  # We either unlocked or logged in, save the session
  bw_last_unlocked=$( date +%s );
  bw_save_session_id "$session"
}

bw_ls(){
  local a=.
  bw_login || return 1
  (( $# != 0 )) && a=$1
  bw list items | jq -r '.[]|"\(.id) \(.name) \(.login.username) \(.login.uris[0].uri)"' | egrep "$a"
}

bwshow(){
  #for i in $( bw_ls "$@" | sed -e 's/.*\[id: //' -e 's/\]//' )
  for i in $( bw_ls "$@" | awkcol 1 )
  do
    _bw_log "%s\n" "$i"
    bw get item "$i"
  done | jq .
}

bwus(){
  bwcopy Username: "$@"
}

bwpw(){
  bwcopy Password: "$@"
}

bwcopy(){
  field=$1
  id=$( bw_ls "$2" | egrep '^[0-9][0-9]+ ' )
  if [[ -z "$id" ]]
  then
    printf "No results for <%s>!\n" "$1"
    return 
  fi

  count=$( printf "%s\n" "$id" | wc -l )
  if [[ "$count" != "1" ]]
  then
    printf "Too many results: <%s>!\n%s\n" "$count" "$id"
    return 
  fi 

  if [[ "$( uname -o )" == "Darwin" ]]
  then
    bw show "${id%% *}" | grep "^$field" | awkcol 2 | tr -d '\r\n' | pbcopy
  else
    bw show "${id%% *}" | grep "^$field" | awkcol 2 | tr -d '\r\n' | xclip -i
    bw show "${id%% *}" | grep "^$field" | awkcol 2 | tr -d '\r\n' | xclip -i -selection clipboard
  fi
}

bw_main(){
  [[ -z "$lookingFor" ]] && _bw_die "Basename <%s> ain't right...."

  # shellcheck disable=SC1090
  [[ -e "$HOME/.bashrc.d/bw-func.bash" ]] && source "$HOME/.bashrc.d/bw-func.bash"

  bw_login
  echo

  pattern=${1:-.}
  ids=$( bw_ls "$pattern" )

  [[ -f /tmp/last-filter ]] && filter="-filter $( cat /tmp/last-filter )"
  # shellcheck disable=SC2086
  selection=$( printf "%s" "$ids" | rofi -matching regex -dmenu -format 'F:s' $filter )
  _bw_log "selection: <%s>\n" "$selection"

  filter=${selection%%\':*}
  _bw_log "filter: <%s>\n" "$filter"

  filter=${filter#\'}
  _bw_log "filter: <%s>\n" "$filter"

  printf "%s\n" "$filter" > /tmp/last-filter

  id=${selection#*:}
  _bw_log "id:\t<%s>\n" "$id"
  id=${id%% *}
  _bw_log "id:\t<%s>\n" "$id"

  env | grep BW
  if [[ "$id" ]]
  then
    local value
    value=$( bw get "$lookingFor" "$id" )

    printf "%s" "$value" | xclip -i -selection cliboard
    printf "%s" "$value" | xclip -i -selection primary
  fi
  clipboards
}

bwurl(){
  lookingFor=uri
  bw_main "$@"
}

bwuser(){
  lookingFor=username
  bw_main "$@"
}

bwpass(){
  lookingFor=password
  bw_main "$@"
}

bw_status(){
  local status

  status=$( bw status | jq -r .status ) || return 1

  case $status in
    unlocked)
      return 0
      ;;
    locked) 
      printf "locked\n"
      return 2
      ;;
    unauthenticated)
      printf "unauthenticated\n"
      return 3
      ;;
    *)
      printf "UNEXPECTED ERROR : %s\n" "$status"
      return 4
      ;;
  esac
}
