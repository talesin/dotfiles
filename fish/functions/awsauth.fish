function awsauth
  if test -d "$HOME/Documents/Projects/awssamlcliauth"
    alias unset=set
    bash $HOME/Documents/Projects/awssamlcliauth/auth.sh
    if test -r "$HOME/.aws/sessiontoken"
      . $HOME/.aws/sessiontoken
    end
  end
end
