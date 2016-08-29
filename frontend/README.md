This is a React+Relay app that used https://github.com/relayjs/relay-starter-kit as a starting point.
The entire logic of the app is in the ~200 LOC in `js/app.js`, everything else in this folder is just tooling.

The docker containers use the compiled version from the dist/ folder.
If you want to play arround with the frontend, you can recompile it by running
`npm run build` (remember to run `npm install` before doing that for the first time)

You can also run `npm start` and webpack to serve the app at http://localhost:3000/
When you database schema changes, you need to run `npm run update-schema`

While the setup of this frontend app works reasonably well, you should not use it as a starting point for your frontend.
There are much more complex/better staring setups with hot code reload and other tools already setup that will help you a lot
with your frontend dev process.
