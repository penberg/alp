# Alp, a text-mode email client

Alp is a text-mode email client.  It is written in Ruby and it uses the
standard Ruby Curses API for text rendering.  Alp works on mailboxes on
the local filesystem for speed.  Use offlineimap, for example, to
synchronize your local mailbox with an IMAP server.

## Installation

You need Ruby and RubyGems to run Alp. You can either use your operating
system specific Ruby package or install rbenv on your machine:

https://github.com/sstephenson/rbenv#installation

To install offlineimap:

~~~ sh
$ yum install offlineimap
~~~

Example offlineimap configuration file looks like this:

~~~ sh
$ cat $HOME/.offlineimaprc 
[general]
accounts = Personal

[Account Personal]
localrepository = localhost
remoterepository = remote

[Repository localhost]
type = Maildir
localfolders = ~/Mail/Personal

[Repository remote]
remotehost = mail.example.com
remoteuser = penberg
ssl = yes
type = IMAP
realdelete = no
~~~

To install msmtp:

~~~ sh
$ yum install msmtp
~~~

Example msmtp configuration file looks like this:

~~~ sh
$ cat $HOME/.msmtprc 
account default
host smtp.gmail.com
port 587
tls on
tls_trust_file /etc/pki/tls/cert.pem
auth on
user joe@gmail.com
from joe@example.com
~~~

To install required gems:

~~~ sh
$ bundle install
~~~

To fetch email from IMAP server:

~~~ sh
$ offlineimap
~~~

To launch the email client:

~~~ sh
$ ./bin/alp Personal
~~~

To send email:

~~~ sh
$ cat mail | msmtp -t
~~~

# Screenshots

![alt text](https://github.com/penberg/alp/raw/master/www/alp-inbox-screenshot.png "Inbox")

# License

Copyright © 2012-2014 Pekka Enberg

Alp is distributed under the MIT license.
