# Accept Monero Donations with BTCPayServer and RINO.io

## Introduction

BTCPayServer is a free and open-source cryptocurrency payment processor which allows you to receive payments in Bitcoin and altcoins directly, with no fees, transaction cost or a middleman. BTCPayServer is secure, private, censorship-resistant and free.

RINO.io is an enterprise-grade multisig Monero wallet that also provides a software layer for more granular permissions.

This guide will show you how to accept Monero donations with BTCPayServer and RINO.io.

## Prerequisites

- **Root access** to a virtual machine or a dedicated server (self-hosted or a VPS) running a Debian-based GNU/Linux distribution (Debian, Ubuntu, etc).
	- Minimum Specifications:
		- **2** vCPUs
		- **4GiB** of RAM
		- **Two** disks: **8GB** for the operating system and **128GB (or more)** for the Monero blockchain.
			- The disk with the Monero blockchain should have high IOPS, usually achieved with SSDs/NVMe drives.

	- BTCPayServer can run on many different operating systems, but for simplicity, this guide will focus on Debian-based distributions.

- A domain/subdomain name with an `A` record pointing to your server's IP address.
	- In this guide, will use `btcpay.example.com` as an example.

## Installation

Firstly, get access to your server. This could be through SSH or a web-based console provided by your hosting provider.

Log in as root or a user with sudo privileges.

### Hardening

It is best to harden your bare server before installing any software on it. This makes it easier to troubleshoot any issues that may arise.

#### Update/Upgrade the System

Update the system to the latest packages:

```bash
apt update && apt upgrade -y
```

#### Install a Firewall

Install a firewall to restrict access to your server. This guide will use `ufw`:

```bash
apt install ufw -y
```

Use hardened defaults for `ufw`:

```bash
ufw default deny incoming
ufw default allow outgoing
```

Allow SSH and HTTP/HTTPS connections:

```bash
ufw allow ssh
ufw allow http
ufw allow https
```

Enable `ufw`:

```bash
ufw enable
```

#### Other Hardening Steps

As always, it is recommended to harden the kernel, encrypt disks, and take other steps to secure your server. This guide will not cover these steps.

Feel free to contact me if you would like to know more about securing your infrastructure.

### Install BTCPayServer

This guide will use Docker as the installation method for BTCPayServer. This is the easiest way to install BTCPayServer and is recommended for most users.

#### Make a Directory for BTCPayServer

```bash
mkdir -p /opt/btcpayserver
cd /opt/btcpayserver
```

#### Clone the BTCPayServer Repository

```bash
git clone git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker
```

#### Configure Environment Variables

Run the following commands to setup enivronment variables for BTCPayServer:

Remember to replace `btcpay.example.com` with your domain name.

```bash
export BTCPAY_HOST="btcpay.example.com"
export BTCPAYGEN_CRYPTO1="xmr"

# If you want Tor support
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-xs opt-add-tor"

# If you don't want Tor support
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-xs"

export BTCPAYGEN_REVERSEPROXY="nginx"
export BTCPAY_ENABLE_SSH=true
```

#### Run the Setup Script

Make sure you're in the `btcpayserver-docker` directory and run the setup script:

```bash
. ./btcpay-setup.sh -i
```

This will take a while (15min or more) to complete.

#### Create a BTCPayServer User and Store

Go to the web interface at `https://btcpay.example.com` and create a new user. Make sure to use a strong password.

After creating the user, you will be prompted to create a new store. You can name it whatever you want.

### Create the RINO.io Wallet

#### Create an Account

Go to [the RINO website](https://app.rino.io/register?business=true) and create an account. The `Company Name` and `Company Website` fields don't matter, so you can put whatever you want there.

After creating an account and verifying your email, you will be prompted to save your account recovery document. Make sure to store it in a safe and secure place, and **do not** lose it.

#### Create the Wallet

Click on the `Wallets` tab, and create a new wallet. You can name it whatever you want.

It will take a minute or so to create the wallet.

After this, you will be prompted to save your Wallet Recovery Document. Make sure to store it in a safe and secure place, and **do not** lose it.

Enter the confirmation code from the document and then click the button to confirm.

#### Make the Wallet Public

Click on the `Settings` tab in the wallet, and scroll down to the `Public Wallet` section.

Since this is a donation wallet, you can make it public. This will allow anyone to view the wallet's balance and transactions through the [private view key](https://www.getmonero.org/resources/moneropedia/viewkey.html).

Set a public wallet identifier so the wallet can be viewed publicly. This can be anything you want.

Click on `Save Changes`.

After that, you should see a public wallet address and the private view key.

#### Inviting Users

Click on the `Users` tab in the wallet, and click on `Add User`. You can enter their email address and choose a role for them.

### Adding the Wallet to BTCPayServer

Go back to the BTCPayServer web interface and click on `Wallets` -> `Monero` -> `Connect an existing wallet`.

Click on `Enter public address and view key` and enter the public wallet address and private view key from RINO.io.

### Creating the Crowdfunding Campaign

Go to the BTCPayServer web interface and click on `Plugins` -> `Crowdfund`. Enter the name of the campaign, and click create.

There, you can enter a title, tagline, description, goal, and more.

Make sure that the `Make Crowdfund Public` option is enabled.

---

That is it! You can now accept Monero donations with BTCPayServer and RINO.io.

Make sure to consult [the official documentation](https://docs.btcpayserver.org/Guide/) for more information.

If you have any questions, feel free to contact me.
