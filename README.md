# gitwatch
A simple bash script that is regularly watching all your git repositories for changes. When a change is detected, a link opening ungit overview is presented.

## Usage:
Run as:

    bash gitwatch.sh [<delay_local>  [<delay_remote> [<root_folder>]]]
    
where:
  - \<delay_local\> is local recheck delay in seconds, default is 15s.
  - \<delay_remote\> is remote recheck delay in seconds, default is 300s.
  - \<root_folder\> is folder root for searching for git repositories. Default is home folder of the current user.
