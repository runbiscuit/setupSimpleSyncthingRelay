Setup Simple Syncthing Relay
===

Got too much idling bandwidth on your servers? Why waste it! Run a Syncthing relay, instead of risking getting your servers suspended on some hosting providers when trying to run Tor relays! You're still doing good, anyway.

From the [Syncthing documentation](https://docs.syncthing.net/users/relaying.html):

> Syncthing can bounce traffic via a relay when it’s not possible to establish a direct connection between two devices. There are a number of public relays available for this purpose. The advantage is that it makes a connection possible where it would otherwise not be; the downside is that the transfer rate is much lower than a direct connection would allow.

If you have not checked out Syncthing, go [take a look](https://github.com/syncthing/syncthing), it's a great project.

By default, this script will join the `default` pool.

### Installation

Tested on:

- Ubuntu 14.04 LTS
- Ubuntu 16.04 LTS
- CentOS 6.8
- CentOS 7.2

Run below command on your ssh terminal and you're good to go :)
```
wget https://git.io/syncrelay -O syncrelay && bash syncrelay && rm -rf syncrelay
```

### Questions & Answers (Q&As)

#### How much bandwidth can I use up to?

It would actually depends on how well your server is connected, and many other factors :)

Check out the recommended specifications [here](https://docs.syncthing.net/users/relaysrv.html#custom-relaysrv)!

Personally, I have ran this on some 128MB RAM VPSes and they seem to work fine. Just not on 64MB RAM though, they crash within minutes after picking up connections. :P I have managed to reach about ~50GB/day at one point of time on a node.

#### According to the docuemntation, I could host my relay on port 443 to prevent getting blocked by corporate filters, but why aren't you doing so in your script?

This script sticks to port 22067 because of the fact that a webserver (e.g: Nginx, Apache, Caddy, etc) might be already running on port 443, so to not cause conflicts, that is not done.

You're free to modify the script to your liking, though! However, because of the fact that a new user is created to isolate things, the user would be unable to listen on that port, so I recommend installing [rinetd](https://www.howtoforge.com/port-forwarding-with-rinetd-on-debian-etch) to forward traffic, which is extremely easy to configure compared to using IPTables.

#### Am I compromising the security of the nodes I relay traffic from/to?

No. Everything is end-to-end encrypted :)

> The connection between two devices is still end to end encrypted, the relay only retransmits the encrypted data much like a router. However, a device must register with a relay in order to be reachable over that relay, so the relay knows your IP and device ID. In that respect it is similar to a discovery server. The relay operator can see the amount of traffic flowing between devices.

#### Hey, me want in!!! Where can I pick up a dirt cheap VPS for this?

I would highly encourage you to pick up a NAT VPS that costs a price of a meal per year, or maybe check out any one of my favourite hosting providers that have really affordable VPSes:

- [DeepNet Solutions (GestionDBI)](https://www.deepnetsolutions.com)
- [HostUS](https://hostus.us)
- [Inception Hosting](https://inceptionhosting.com)
- [DigitalOcean](https://www.digitalocean.com)
- [AlphaRacks](https://alpharacks.com/)

You can find cheap VPS deals on [LowEndBox](https://lowendbox.com/), but _please make sure you do enough research on the hosts you intend to buy from!_

#### Can I contribute, too?

Yes! Contributions are always welcome - if you have any code to contribute, simply fork this and submit a pull request! Otherwise, if you find any bugs or issues, please open an issue!

### Copyright

Copyright (C) 2016 [Edwin A.](https://theroyalstudent.com) <edwin@theroyalstudent.com>.

Credits to @sayem314 for CentOS/yum compatibility and many other hotfixes.

This work is licensed under the Creative Commons Attribution-ShareAlike 3.0

Unported License: http://creativecommons.org/licenses/by-sa/3.0/
