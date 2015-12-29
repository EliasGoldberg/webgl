planet
=====

This project depends on node.js.  I found instructions for installing node.js on OS X at the [Team Tree House blog](http://blog.teamtreehouse.com/install-node-js-npm-mac).  In a nutshell:
- Install XCode via the app store
- Install Homebrew via the terminal: `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
- Install Node via Homebrew: `brew install node`

Once node.js is installed:
- Get the planet source: `git clone https://github.com/EliasGoldberg/planet.git`
- Navigate to the newly created `planet` directory
- Install the dev dependencies: `npm install`

To compile the coffeescript into javascript whenever a .coffee file is changed:
- Install coffee-script globally: `npm install -g coffee-script`
- In a new terminal window, navigate to the project directory
- `coffee -wcm src/*.coffee spec/*.coffee`

To run unit tests:
- Install Firefox (Or change the karma.conf.js file to use Chrome or whatever.)
- `karma run`

To run unit tests whenever you save a file:
- Install a bunch of dependencies globally: `npm install -g jasmine karma karma-jasmine karma-firefox-launcher`
- In a new terminal window: `karma start`

To serve the project locally:
- Install the global dependencies: `npm install -g connect serve-static`
- In a new terminal window: `node server.js`
- In your favorite browser, navigate to `localhost:8080`

To reload the project in the browser whenever a file is saved:
- Install yet more global dependencies: `npm install -g supervisor reload`
- Start the file watcher: `reload` (you cannot have the `node server.js` command running while doing this.  Navigate to localhost:8080/src/index.html.  Using -d or -s to specify the index page seems to prevent the debugger from accessing the .coffee files.)

This project uses WebGL 2.0.  Right now, you need an daily build browser to run it.  I use [Google Chrome Canary](https://www.google.com/chrome/browser/canary.html).
- Download and install the browser
- Add `alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --enable-unsafe-es3-apis'` to your .bash_profile.
- In a new terminal window, type `canary` to open Chrome Canary
- Since this is the only thing I use Chrome Canary for, I have its homepage set to http://localhost:8080/src/index.html