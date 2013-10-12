#/bin/sh

carton exec -- plackup -s Starlet --max-workers 3 -p 5005 app.psgi
