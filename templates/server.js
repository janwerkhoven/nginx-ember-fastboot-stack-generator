/*eslint-env node*/

const FastBootAppServer = require("fastboot-app-server");
const FastBootWatchNotifier = require("fastboot-watch-notifier");

const distPath = "/var/www/foo.com/current";

const notifier = new FastBootWatchNotifier({
  distPath,
  debounceDelay: 250,
  saneOptions: {
    poll: true
  }
});

const server = new FastBootAppServer({
  distPath,
  notifier,
  gzip: true,
  host: "0.0.0.0",
  port: 8001
});

server.start();
