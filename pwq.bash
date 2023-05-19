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
	    $PROGRAM pwq score [--user user] pass-name
	        Check the quality of a password.
	        If provided, check similarity of the password to the username
	        (use the password file's basename if unspecified).
	        More information may be found in the pwscore(1) man page.
	    $PROGRAM pwq find-weak [--user user] [--min-score min-score] [subfolder]
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

case "$1" in
	help|--help) shift;		cmd_pwq_usage "$@" ;;
	version|--version) shift;	cmd_pwq_version "$@" ;;
	find-weak) shift;		cmd_pwq_find_weak "$@" ;;
	generate|make) shift;		cmd_pwq_generate "$@" ;;
	score) shift;			cmd_pwq_score "$@" ;;
	*)				cmd_pwq_usage "$@" ;;
esac
exit 0
