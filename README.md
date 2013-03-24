# Piping-browser

There are already wrappers such as [brunch](https://github.com/brunch/brunch/) that offer to watch and rebuild all your client side files, and optionally launch a server for you. I wanted to launch my server and have it watch my client files and rebuild them (as well as itself, see [piping](http://github.com/mdlawson/piping))

Piping-browser uses [browserify](https://github.com/substack/node-browserify) to package up your client side modules using commonjs. Browserify also gives us sourcemaps and support for node modules for free!

## Installation
```
npm install piping-browser
```
## Usage

Piping-browser is not a binary, so you can continue using your current workflow for running your application ("wooo!"). Basic usage is as follows:

```javascript
require("piping-browser")({main:"./client/scripts/main.js",out:"./public/application.js"});
```
### Options

- __main__ _(path)_: The path to the entry point of your application. this file is automatically executed on load. Relative to the file where piping-browser was required
- __out__ _(path)_: The path to where you want your bundled code to be written to. Relative to the file where piping-browser was required
- __ignore__ _(regex)_: Files/paths matching this regex will not be watched. Defaults to `/(\/\.|~$)/`
- __watch__ _(boolean)_: Whether or not piping should rebuild on changes. Defaults to true, could be set to false for production
- __debug__ _(boolean)_: Whether browserify should run in debug mode or not. Debug mode turns on source maps. Defaults to true
- __minify__ _(boolean)_: Whether browserify should minify output with UglifyJS. Source maps for minified output are currently not working right, and are mostly disabled regardless of debug option.
- __vendor__ _(object)_: Specify configuration for building vendor files. Vendor files are concatenated in order and then minified if minify is true, and written to the given path.
  - __path__ _(string)_: Directory where vendor files are located, relative to file where piping-browser was required
  - __out__ _(string)_: Path where vendor ouput should be written, relative to the file where piping-browser was required
  - __files__ _(array)_: Array of vendor files, relative to vendor path.
- __build__ _(object)_: An object that maps file extensions, eg "coffee" to functions that take a filename and the files data and compiles it to javascript. By default can compile coffeescript files, with sourcemaps.


Piping-browser can also be used just by passing two strings. In this case, the strings are taken as the main and out options
```javascript
require("piping-browser")("./client/scripts/main.js","./public/application.js");
```

piping-browser plays nice with piping. To use it, ensure piping-browser is required when piping returns false:

```javascript
if(!require("piping")()){
  require("piping-browser")("./client/scripts/main.js","./public/application.js");
  return;
}
// application logic here
```