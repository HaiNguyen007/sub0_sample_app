import chokidar from 'chokidar';
import express from 'express';
import path from 'path';
import webpack from 'webpack';
import WebpackDevServer from 'webpack-dev-server';
import {clean} from 'require-clean';
import {exec} from 'child_process';

const APP_PORT = 3001;
const GRAPHQL_ENDPOINT = 'http://localhost:8080/api/graphql/'

let appServer;

function startAppServer(callback) {
  // Serve the Relay app
  const compiler = webpack({
    entry: path.resolve(__dirname, 'js', 'app.js'),
    module: {
      loaders: [
        {
          exclude: /node_modules/,
          loader: 'babel',
          test: /\.js$/,
        }
      ]
    },
    output: {filename: '/app.js', path: '/', publicPath: '/js/'}
  });
  appServer = new WebpackDevServer(compiler, {
    contentBase: '/public/',
    proxy: {'/api/graphql': GRAPHQL_ENDPOINT},
    publicPath: '/',
    stats: {colors: true}
  });
  // Serve static resources
  appServer.use('/', express.static(path.resolve(__dirname, 'public')));
  appServer.listen(APP_PORT, () => {
    console.log(`App is now running on http://localhost:${APP_PORT}`);
    if (callback) {
      callback();
    }
  });
}


function startServers(callback) {
  // Shut down the servers
  if (appServer) {
    appServer.listeningApp.close();
  }

  // Compile the schema
  exec('npm run update-schema', (error, stdout) => {
    let doneTasks = 0;
    function handleTaskDone() {
      doneTasks++;
      if (doneTasks === 1 && callback) {
        callback();
      }
    }
    startAppServer(handleTaskDone);
  });
}

startServers();
