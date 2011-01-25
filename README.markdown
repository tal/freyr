# freyr

Manage all your application's services.

Freyr will start any services you want in the background and capture stdout into a log file for you to view whenever you want.
Great for if you are working on an app which has peripheral services that need to be run.

## Basic use

    $ gem install freyr

Install freyr it'll also give you a binary named freyr.

To use it you can create a Freyrfile or .freyrrc. It will automatically look for those files in whatever your current
directory is. It will also look for a .freyrrc in your home directory. You can also specify a file manually.

The file has this basic structure:

    service :memcache do
      start 'memcached -vvv'
    end

That will allow you to start, stop, restart, and watch the STDOUT of a service.

Basic usage can be done like

    $ freyr start memcache

Just calling `freyr` or `freyr list` will output all of the services being tracked and their status.

## Some more options

A few more of the options for defining a service are:

* start/stop/restart - Commands to be run when you send any of those individual commands. If stop is not defined it will
default to sending a KILL signal, if restart is not defined it will run stop then start.
* dir - The directory to run the file in, defaults to '/' (considering defaulting to current directory)
* proc_match - a string or regular expression to check for after starting. This is useful if freyr can't capture the pid
from a normal launch, eg when launching though a shell script.
* ping - A url to ping to alert you when the service is up and running, will let you know if there's an error.
* group - assign this service to a group. Calling start/stop/restart on the group will run across all of the members

See a complete list of definition options [here](https://github.com/Talby/freyr/wiki/Service-Definition-Options)

These options also give you some more options with to use with the CLI

* `freyr update_pid [service]` - Updates the pid stored by checking for the proc_match. Useful if you started the service
by some method other than freyr or it restarted with a different pid.
* `freyr ping` - Tries to ping the service once
* `freyr -p` - Shows you all services and the status of pings for each.

To see a complete list of options type in `freyr help`.

## TODO

* Growl notifications
* Better error handling
* Service definition validation
* Plugin architecture

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Tal Atlas. See LICENSE for details.
