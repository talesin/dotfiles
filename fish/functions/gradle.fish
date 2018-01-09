function gradle
  set hasg $status
  if test -f ./gradlew
    ./gradlew $argv
  else if which -s gradle
    eval (which gradle) $argv
  else
    echo "gradle not available"
  end
end
