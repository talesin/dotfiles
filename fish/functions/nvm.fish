function nvm
	if not test -f ~/.nvm/nvm.sh
		if which brew >/dev/null 2>/dev/null
			brew update
			brew install nvm
		end
	end

	bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end
