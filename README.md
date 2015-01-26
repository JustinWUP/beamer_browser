beamer_browser
==============

Simple web based media manager for users of [Beamer](http://beamer-app.com/) and Apple TV.

## Features
* Browse your media library
* Artwork and description views from iTunes API with caching
* Launch Beamer with selected media from web
* See what's being played remotely
* Process polling and very basic caching (read: no database integration) for currently playing file name
* Somewhat responsive layout for mobile devices
* Webapp support for iOS 

## Getting started

* Configure the BEAMER and ROOT constants in index.rb to the location of your 
Beamer executable and the root of your media library respectively.
* Start the server by running:

        ruby index.rb

* Browse to localhost:4567
* Within ROOT folder, put your TV Shows in a folder called "TV Shows" and Movies in a folder called "Movies" for maximum enjoyment.

Personally, I run the server in an automator job so it starts whenever my computer boots.

Enjoy!
