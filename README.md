# Icon cert 14

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE)

Simple tweak to lock Screen without button, just double tap from Home  
Super lightweight. No battery affect. Just install, no preferences

## Features

- Lock Screen without button, just double tap from Home
- Support iOS 12 - 14

## Cydia Repo

[https://haoict.github.io/cydia](https://haoict.github.io/cydia)

## Screenshot

N/A

## Building

[Theos](https://github.com/theos/theos) required.

```bash
make do
```

## Contributors

- [Bandar Helal](https://github.com/BandarHL/)

## License

Licensed under the [GPLv3 License](./LICENSE), Copyright © 2020-present Hao Nguyen <hao.ict56@gmail.com>

## [Note] Advanced thingy for development

<details>
  <summary>Set up SSH Key - Click to expand!</summary>

Add your device IP in `~/.bash_profile` or `~/.zprofile` or in project's `Makefile` for faster deployment
```bash
THEOS_DEVICE_IP = 192.168.1.12
```

Add SSH key for target deploy device so you don't have to enter ssh root password every time

```bash
cat ~/.ssh/id_rsa.pub | ssh -p 22 root@192.168.1.12 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Build the final package

```bash
FINALPACKAGE=1 make package
```

</details>

<details>
  <summary>Build with Simulator (simject) - Click to expand!</summary>

Set up simject: https://github.com/angelXwind/simject

Get 13.7 patched SDK from https://github.com/opa334/sdks, copy iPhoneSimulator13.7.sdk to $THEOS/sdks folder

Build and setup with simject
```bash
SIMULATOR=1 make

SIMULATOR=1 make setup
```

Respring simulator
```bash
./simject/bin/resim
```

</details>
