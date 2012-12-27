Alp - Curses frontend for offlineimap
=====================================

Alp is a text-mode frontend for offlineimap written in Ruby and curses.

Installation
------------

Dependencies:

To install offlineimap:

~~~ sh
$ yum install offlineimap
~~~

Example configuration file looks like this:

~~~ sh
$ cat $HOME/.offlineimaprc 
[general]
accounts = Personal

[Account Personal]
localrepository = localhost
remoterepository = remote

[Repository localhost]
type = Maildir
localfolders = ~/Mail

[Repository remote]
remotehost = mail.example.com
remoteuser = penberg
ssl = yes
type = IMAP
realdelete = no
~~~

To install required gems:

~~~ sh
$ bundle install
~~~

To fetch email from IMAP server:

~~~ sh
$ offlineimap
~~~

And finally, to launch the email client:

~~~ sh
$ ./bin/alp
~~~

Screenshots
-----------

![alt text](https://github.com/penberg/alp/raw/master/www/alp-inbox-screenshot.png "Inbox")
