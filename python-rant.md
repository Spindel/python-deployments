# Deploying Python - Pain Pain Pain Pain
So, I recently had a discussion on Twitter, which also sidetracked to
[reddit/r/python](http://reddit.com/r/python/), where it originally started
back several (7 already?) years ago when we were first deploying our initial
python web applications.


So, lets set up requirements and wishes for "succesful" longterm deployments.
* No custom compiled code
* System packages or package repos
* All system services are managed by configuration management
(CFEngine, Puppet, ansible, pssh...)


* A failed deployment must not bring down other (web) applications
* No normal code run as root
* Developers do not have root access on servers
* Deployment is (semi) automatic, and does not have root access to servers


* All application configuration is kept in state from source control / deployment system
* Deployments can be reverted if necessary.




## No custom compiled code
This basically translates to "no tarballs" no
`./configure; make; make install` or other ways (`curl | sh`) of accessing
software. We aren't running LFS here, and there is no reason to have a compiler
installed on the application servers.

## System packages or package repos
It also means that deployment tools, management, webservers and such do not come
from a service without automatic upgrades & security updates. Anything that
isn't automated won't get done.

In CentOS case, this means we are limited to webservers & management tools that
are in epel, base or have a pre-packaged & up-to-date repository.


## All system services are managed by configuration management
This means that there should be a standard init (or systemd unit) file for each
service that runs. This goes for webservers, supervisord, and others. These
configs & scripts are in the hands of the CM tool. That includes the
per-application settings inside supervisord.


## A failed deployment must not bring down other (web) applications
When you have for example, FastCGI in Lighttpd, each FastCGI instance is started
by Lighttpd itself. This causes all applications to run in the same user
as your webserver (which is not root) which might be good.

But if one of those applications fail to start, because a SELinux label is wrong
or something else causes a failures, it means means _all_ webservices will fail
to start on that machine.  This leads to long outages while you manually debug,
or revert upgrades. Something that's a pain in the neck.


## No normal code run as root
The web applications itself are not run as root. Each application should
preferrably have it's own user, as to not be able to clobber the files of
another user.  Deployment (integration systems or developers, who are the ones
that deploy new code) should not need root permissions to perform an upgrade.
This also means that you must not need root in order to restart a service. Since
the CM system manages the services, deployment of code is orthogonal to the CM
system. ( However, creating a new app infrastructure should require the
CM/Sysadmin. Setting up CNAME, creating users, adding git keys to jenkins,
that sort.)

## Developers do not have root
Really, it's that simple. If we could trust developers, there would never be any
amazon keys or private TLS keys checked into github, and we'd never have
cleatext passwords in files or configurations.

Of course, in this case you can replace "developers" with "customers" (for
shared hosting) and be the same off. Though we trust developers more than
customers. After all, we need them.)

## Deployment is (semi) automatic (and does not have root access to servers)
Deployment is not initial server setup, but all times following that. This is
basically new revisions, versions or how you do your releases. In our case it
can be automatic from a tracking branch ("release") via jenkins, or time-based
from our regular release schedule, in combination with newsposts and beer.

Deployment _should_ involve getting a clean application checkout (no leftovers
from past times). If there is some state to be shared between deployments,
it should be explicit. (Think SSL keys, auth store, sqlite databases, etc. etc.)


## All application configuration is kept in state from source control
Configuration for which DB to talk to, which file to look for keys in,
are part of the application and should be version controlled. Authentication
tokens, ssl-keys and similar, are not configuration, and should not be version
controlled. However, their location is configuration (unless hardcoded or using
app-relative paths, which is the same)

For some frameworks, this means .ini files and similar. For others, it can be a
launcher shellscript or environment file.

## Deployments can be reverted if necessary
This one is important, and adds complexity. Python environments aren't well
known for
"[deterministic builds](https://blog.torproject.org/blog/deterministic-builds-part-two-technical-details)",
and it's not a situation that's likely to start now.

# Some words about security
The python infrastructure & deployment platforms we have today are
__inherently insecure__. There are no GPG keys or verification of code
downloaded via pip or easy_install, in many cases, it doesn't go over https
( because setup.py points at a random checkout/tree on someones github repo),
and up until recently, python by default didn't even check the SSL certificates.
( Pip has checked certificates since v1.3, if it could. )

Deploying python code is an exercise in leap of faith and misplaced trust.
You trust that noone fucked with your wifi connection while you were making a
virtualenv. You trust that you didn't have a modifying endpoint/malicious proxy
at the
[airport]/https://twitter.com/__apf__/status/551083956326920192/photo/1)
that modified packages in flight. ( Because that only happens to
[javascript and end-users](https://blog.haschek.at/post/fd9bc).
Developers are immune to such things.)

This habit of "only verifying that the provider is trusted at download time"
also makes it impossible to verify an installation afterwards. There are no
list of signed checksums to validate.

The habit of using
[pip freeze](https://pip.pypa.io/en/latest/reference/pip_freeze.html)
to pin old, ancient, or unmaintained packages into deployments aren't making
life easier.
Neither is the lack of security updates, or even notifications of upstream CVE's
in the cheese shop. You won't know at any moment if any of the dependencies in
your stack allow arbitary code execution via data in markdown fields, or if the
version of SQLAlchemy in your pylons app allowed arbitary SQL commands.  Since
there is no provision for security updates, only "update to latest", you either
take the security risk of not updating virtualenvs regularly, or take the
stability risk of updating.

This situation is by choice from the larger Python community, and solving it
is out of scope for this text. It's just something you have to be aware of when
working with python in deployments.

# What about Docker?
Yep, A lot of the wishes here would be pushed to be someone elses problem by
using docker. Except that they would basically allow arbitary code to run as
root on your system (root in container == root outside). Also, it means
maintaining even more of the software stack inside each container.

# So, what happens now?
Well, to start with we need something to deploy. And something to run it as.

Basics of our setup will be:
* Web server acting as proxy
* application server maintainance
* A couple of different web applications
* Both "Old" python and "Modern" python
* The same code may run several sites, differing in configuration
* Working lifecycle management that fulfill the requirements above

So, to go with this, and the requirements above, we have some  decisions to
make.

Each web application will run as it's own user, in a separate directory.
Each time you deploy, you will get a fresh application directory, and a fresh
virtualenv for it.

Rolling back an application will mean replacing the symbolic links that point to
the current virtualenv + application, with links pointing at the previous ones.

Shared state will not be rolled back, and will run in it's own directory.

It's expected that system services are managed with CM, but how you do that will
probably not be covered here.

Various scripts & tools to run & deploy will be found here.

# CentOS 6
starting from a minimal install:
yum distro-sync
yum install epel-release





