# fireutil

A simple CLI utility to push key-value pairs to Firestore. Useful for scripting, e.g. logging system data using crontab.

This application is based on [firedart](https://github.com/cachapa/firedart).

## Setup

To use, simply clone this repository:

``` bash
git clone https://github.com/cachapa/fireutil
```

You'll need to provide your Firebase credentials. Simply rename `config_EDIT.dart` to `config.dart` and edit the file.

To test if everything is working try logging some data:

``` bash
cd bin
dart main.dart update /test/log field1:content field2:more_content
```

For normal usage it's recommended that you compile an AOT binary:

``` bash
dart2aot bin/main.dart fireutil
```

To run it:

``` bash
dartaotruntime fireutil update /test/log field1:content field2:more_content
```

To check available commands simply run the command without arguments:

``` bash
dartaotruntime fireutil
```
