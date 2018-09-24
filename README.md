# Whitelist Cloudflare network IPs

After moving to [Cloudflare](https://www.cloudflare.com/) CDN service, all requests to your server will be proxied through Cloudflare. That's how Cloudflare protects your server from [DoS](https://en.wikipedia.org/wiki/DOS) and [DDoS](https://en.wikipedia.org/wiki/Denial-of-service_attack).

So after migrating to Cloudflare you need to change your server IP and keep it confidential. Most probably you won't change your data-center and attackers would scan data-center IP ranges to find your new server IP. Even if you use an IP from a completely different range, finding you is still feasible with the right tools in few days.

To protect your server you need to hide any fingerprint and be just visible to Cloudflare network. It means even SSH port should not be detectable via port scanning.

This bash script automatically Whitelists [official Cloudflare IP ranges](https://www.cloudflare.com/ips/) and hide your SSH port by [port knocking](https://en.wikipedia.org/wiki/Port_knocking).

**IMPORTANT:** Here port knocking is not used for securing your SSH connection, and you should do that by using strong password and [public key authentication](https://www.ssh.com/ssh/key/).

## Usage

```bash
bash wlcf.sh
```

Script will generate `client.sh` which you can use on client machine for stablishing SSH connections to your server.

Without knowing the right sequence of ports, you are completely invisible to outside world.

### Tested on Ubuntu server 16.04/18.04