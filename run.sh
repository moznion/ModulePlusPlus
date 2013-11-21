#!/bin/sh

carton exec -- plackup -s Starlet --port 5005 --max-workers 3 app.psgi
