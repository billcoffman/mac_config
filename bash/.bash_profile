export BASH_SILENCE_DEPRECATION_WARNING=1
export LANG="en_US.UTF-8"

[ -r "${HOME}/.bash_aliases" ] && . "${HOME}/.bash_aliases"
[ -r "${HOME}/.bash_paths" ] && . "${HOME}/.bash_paths"
[ -d "${HOME}/.bash_enabled" ] && \
	for rc in ${HOME}/.bash_enabled/*
	do
		echo "source ${rc}";
		. "${rc}"
	done


#echo Hello Bash_Profile\!

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"


# Setting PATH for Python 3.6
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/qt/bin:$PATH"
export PATH
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
