vso_grabber
===========

a quick script to generate download links for http://sdac.virtualsolar.org/

      ruby ./vso_grabber.rb <year>

outputs curl commands to download images for the first minute of the first day of each month for the a preset range of spectral images

----
Installing dependencies (bundler!)

    > gem install bundler
    > bundle install

----
On a Mac? Don't already use homebrew? I bet your ruby is old!

Install Homebrew http://mxcl.github.com/homebrew/

Then

    > brew install ruby

