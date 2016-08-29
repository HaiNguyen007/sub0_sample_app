#!/usr/bin/env babel-node --optional es7.asyncFunctions

const fetch = require('node-fetch');
const fs = require('fs');
const {
  buildClientSchema,
  introspectionQuery,
  printSchema,
} = require('graphql/utilities');
const path = require('path');
const schemaPath = path.join(__dirname, 'schema');

const SERVER = 'http://localhost:8080/api/graphql/schema.json';

// Save JSON of full schema introspection for Babel Relay Plugin to use
fetch(`${SERVER}`, {
  method: 'get',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  },
  //body: JSON.stringify({'query': introspectionQuery}),
}).then(res => res.json()).then(schemaJSON => {
  console.log('Fetched remote schema')
  fs.writeFileSync(
    path.join(__dirname, '../data/schema.json'),
    JSON.stringify(schemaJSON, null, 2)
  );

  // Save user readable type system shorthand of schema
  const graphQLSchema = buildClientSchema(schemaJSON.data);
  fs.writeFileSync(
    path.join(__dirname, '../data/schema.graphql'),
    printSchema(graphQLSchema)
  );
});