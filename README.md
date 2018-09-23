<div>
  <h1 align="center">Imageburner</h1>
  <h3 align="center"><img src="data/icons/com.github.artemanufrij.imageburner.svg"/><br>A simple imageburner inspired by Etcher's UI</h3>
  <p align="center">Designed for <a href="https://elementary.io">elementary OS</p>
</div>

[![Build Status](https://travis-ci.org/artemanufrij/imageburner.svg?branch=master)](https://travis-ci.org/artemanufrij/imageburner)

### Donate
<a href="https://www.paypal.me/ArtemAnufrij">PayPal</a> | <a href="https://liberapay.com/Artem/donate">LiberaPay</a> | <a href="https://www.patreon.com/ArtemAnufrij">Patreon</a>

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.artemanufrij.imageburner">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>
<p align="center">
  <img src="Screenshot.png"/>
</p>

## Install from Github.

As first you need elementary SDK
```
sudo apt install elementary-sdk
```

Clone repository and change directory
```
git clone https://github.com/artemanufrij/imageburner.git
cd imageburner
```

Compile, install and start Imageburner on your system
```
meson build --prefix=/usr
cd build
sudo ninja install
com.github.artemanufrij.imageburner
```