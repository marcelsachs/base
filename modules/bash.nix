{
  environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";
  environment.interactiveShellInit = ''
    PS1='\[\033[1;38;5;39m\]\w \[\033[1;38;5;226m\]$ \[\033[0m\]'
    HISTSIZE=50000
    HISTFILESIZE=100000
    HISTCONTROL=ignoreboth:erasedups
    shopt -s histappend
    PROMPT_COMMAND="history -a; history -n''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  '';
}
