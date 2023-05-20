# Copyright (C) 2023 Listeria monocytogenes <listeria@disroot.org>
# Copyright (C) 2012 - 2018 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
# This file is licensed under the GPLv3+. Please see COPYING for more information.

GENERATED_STRENGTH="${PASSWORD_STORE_PWQ_GENERATED_STRENGTH:-96}"
MINIMUM_SCORE=${PASSWORD_STORE_PWQ_MINIMUM_SCORE:-50}

cmd_pwq_version() {
	cat <<-_EOF
	================================================
	= pass-pwq: the libpwquality extension to pass =
	=                                              =
	=                    v0.1.0                    =
	=                                              =
	=            Listeria monocytogenes            =
	=             listeria@disroot.org             =
	=                                              =
	=        http://www.passwordstore.org/         =
	================================================
	_EOF
}

cmd_pwq_usage() {
	cat <<-_EOF
	Usage:
	    $PROGRAM pwq generate [--clip,-c] [--in-place,-i | --force,-f] pass-name [entropy-bits]
	        Generate a new password of entropy-bits bits of entropy (or $GENERATED_STRENGTH if unspecified).
	        Optionally put it on the clipboard and clear board after $CLIP_TIME seconds.
	        Prompt before overwriting existing password unless forced.
	        Optionally replace only the first line of an existing file with a new password.
	        More information may be found in the pwmake(1) man page.
	    $PROGRAM pwq score [--user=user,-u user] [--line=line-number,-l line-number] pass-name
	        Check the quality of a password.
	        If provided, check similarity of the password to the username
	        (use the password file's basename if unspecified).
	        More information may be found in the pwscore(1) man page.
	    $PROGRAM pwq find-weak [--user=user,-u user] [--min-score=min-score,-m min-score] [subfolder]
	        Find passwords in this password storage which score lower than min-score
	        (or $MINIMUM_SCORE if unspecified).
	        The optional user argument is identical to that of the score sub-command.
	        Optionally only search the given subdirectory.
	    $PROGRAM pwq help
	        Show this text.
	    $PROGRAM pwq version
	        Show version information.

	More information may be found in the pass-pwq(1) man page.
	_EOF
}

cmd_pwq_generate() {
	local opts qrcode=0 clip=0 force=0 inplace=0 pass
	opts="$($GETOPT -o qcif -l qrcode,clip,in-place,force -n "$PROGRAM" -- "$@")"
	local err=$?
	eval set -- "$opts"
	while true; do case $1 in
		-q|--qrcode) qrcode=1; shift ;;
		-c|--clip) clip=1; shift ;;
		-f|--force) force=1; shift ;;
		-i|--in-place) inplace=1; shift ;;
		--) shift; break ;;
	esac done

	[[ $err -ne 0 || ( $# -ne 2 && $# -ne 1 ) || ( $force -eq 1 && $inplace -eq 1 ) || ( $qrcode -eq 1 && $clip -eq 1 ) ]] && die "Usage: $PROGRAM $COMMAND $SUBCOMMAND [--clip,-c] [--qrcode,-q] [--in-place,-i | --force,-f] pass-name [entropy-bits]"
	local path="$1"
	local bits="${2:-$GENERATED_STRENGTH}"
	check_sneaky_paths "$path"
	[[ $bits =~ ^[0-9]+$ ]] || die "Error: entropy-bits \"$bits\" must be a number."
	[[ $bits -ge 56 && $bits -le 256 ]] || die "Error: entropy-bits must be between 56 and 256."
	mkdir -p -v "$PREFIX/$(dirname -- "$path")"
	set_gpg_recipients "$(dirname -- "$path")"
	local passfile="$PREFIX/$path.gpg"
	set_git "$passfile"

	[[ $inplace -eq 0 && $force -eq 0 && -e $passfile ]] && yesno "An entry already exists for $path. Overwrite it?"

	read -r pass < <(pwmake $bits)
        [[ -n $pass ]] || die "Could not generate password with pwmake(1)."
	if [[ $inplace -eq 0 ]]; then
		echo "$pass" | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" || die "Password encryption aborted."
	else
		local passfile_temp="${passfile}.tmp.${RANDOM}.${RANDOM}.${RANDOM}.${RANDOM}.--"
		if { echo "$pass"; $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2; } | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}"; then
			mv "$passfile_temp" "$passfile"
		else
			rm -f "$passfile_temp"
			die "Could not reencrypt new password."
		fi
	fi
	local verb="Add"
	[[ $inplace -eq 1 ]] && verb="Replace"
	git_add_file "$passfile" "$verb generated password for ${path}."

	if [[ $clip -eq 1 ]]; then
		clip "$pass" "$path"
	elif [[ $qrcode -eq 1 ]]; then
		qrcode "$pass" "$path"
	else
		printf "\e[1mThe generated password for \e[4m%s\e[24m is:\e[0m\n\e[1m\e[93m%s\e[0m\n" "$path" "$pass"
	fi
}

cmd_pwq_score() {
	local opts user selected_line
	opts="$($GETOPT -o u:l: -l user:,line: -n "$PROGRAM" -- "$@")"
	local err=$?
	eval set -- "$opts"
	while true; do case $1 in
		-u|--user) user="$2"; shift 2 ;;
		-l|--line) selected_line="$2"; shift 2 ;;
		--) shift; break ;;
	esac done

	[[ $err -ne 0 ]] && die "Usage: $PROGRAM $COMMAND $SUBCOMMAND [--user=user,-u user] [--line=line-number,-l line-number] pass-name"

	local path="$1"
	local passfile="$PREFIX/$path.gpg"
	check_sneaky_paths "$path"
	if [[ -f $passfile ]]; then
		if [[ ${selected_line-1} -eq 1 ]]; then
			score="$($GPG -d "${GPG_OPTS[@]}" "$passfile" | pwscore "${user:-${path##*/}}")"
		else
			[[ $selected_line =~ ^[0-9]+$ ]] || die "Line number '$selected_line' is not a number."
			score="$($GPG -d "${GPG_OPTS[@]}" "$passfile" | sed -n ${selected_line}p | pwscore "${user:-${path##*/}}")"
		fi || exit $?
		echo "$path" "$score"
	elif [[ -d $PREFIX/$path ]]; then
		die "Error: $path is a directory."
	elif [[ -z $path ]]; then
		die "Error: password store is empty. Try \"pass init\"."
	else
		die "Error: $path is not in the password store."
	fi
}

SUBCOMMAND="$1"

case "$1" in
	help|--help) shift;		cmd_pwq_usage "$@" ;;
	version|--version) shift;	cmd_pwq_version "$@" ;;
	find-weak) shift;		cmd_pwq_find_weak "$@" ;;
	generate|make) shift;		cmd_pwq_generate "$@" ;;
	score) shift;			cmd_pwq_score "$@" ;;
	*)				cmd_pwq_usage "$@" ;;
esac
exit 0
