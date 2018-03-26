<div>
  <h1 align="center">Imageburner</h1>
  <h3 align="center"><img src="data/icons/com.github.artemanufrij.imageburner.svg"/><br>A simple imageburner inspired by Etcher's UI</h3>
  <p align="center">Designed for <a href="https://elementary.io">elementary OS</p>
</div>

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

## Installation
You'll need the following dependencies:
* cmake
* cmake-elementary
* debhelper
* libgranite-dev
* valac

Clone repository and change directory
```
git clone https://github.com/artemanufrij/imageburner.git
cd imageburner
```

Create **build** folder, compile and start application
```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
```

Install and start Imageburner on your system
```
sudo make install
com.github.artemanufrij.imageburner
