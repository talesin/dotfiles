function nvm
	if not test -f ~/.nvm/nvm.sh
		curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
	end

	bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end
