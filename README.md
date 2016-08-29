[![Gitter](https://badges.gitter.im/ruslantalpa/sub0_sample_app.svg)](https://gitter.im/ruslantalpa/sub0_sample_app?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Sub0 Platfrom
-------------
Sub0 is a collection of docker containers working together to provide an automated REST/GraphQL API over an existing PostgreSQL database.
The platform is built on top of PostgREST and OpenResty (Nginx).
In addition to "stock PostgREST" this system provides

 - GraphQL schema (soon to be Relay compatible)
 - Everything is in docker for easy install/extension
 - PostgREST runs behind the nginx proxy to provide security/ssl/flexibility
 - Built-in cache capabilities
 - Ability to manipulate/validate request inflight before they reaches PostgREST using a precomputed AST (eg. enforce at least one filter on the endpoint)
 - An in-browser IDE for exploring your GraphQL schema (complete with documentation generated based on comments you add to the tables/views/columns in PostgreSQL)
 - &select and filters work on /rpc path, classic `session` login mechanism, custom sql function can be executed on each request (these will be merged upstream soon)


This repo contains a sample app that demonstrates the capabilities of Sub0 platform.
To run this you need to have docker installed on your system and logged in with your dockerhub id.
At the moment, the images are private so you need to also <b>request access on [Sub0 site](http://graphqlapi.com) for your dockerhub id</b>.

```shellscript
git clone https://github.com/ruslantalpa/sub0_sample_app.git
cd sub0_sample_app
docker-compose up
```

In your browser navigate to `http://localhost:8080/graphiql/` (if your docker version is older then v1.12.0 you might need to replace `localhost` with the ip of the docker VM).
Toggle the `Docs` panel (top right corner) to explore the types/endpoints

Use this JWT to run queries 
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW5pc3RyYXRvciIsInVzZXJfaWQiOjEsImNvbXBhbnlfaWQiOjF9.ate5mETtGRu-mfGF4jFt7pP1b4W85r2uEXt603D7obc
```

You can also use `rpc/signup` and `rpc/login_jwt` to get your own jwt of you can use the `session` authentication method by running

```graphql
{
  rpc {
    login_session(email:"michael@dundermifflin.com",password:"pass"){
      name
      value
      max_age
    }
  }
}
```


After you are logged in (by envoking login_session or by using a JWT value), try these queries

```graphql
# Copy/Paste this entire block, everything will be executed in a single round trip
{
  # basic request
  basic: clients {
    edges {
      node {
        id t_id name
        projects {
          edges {
            node {
              id t_id name
              tasks {
                edges {
                  node {
                    id t_id name
                  }
                }
              }
              users {
                edges {
                  node {
                    id t_id name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  
  # filtering on different levels
  filtering: projects(name: {op: like, val: "Windows*"}) {
    edges {
      node {
        t_id name
        client {
          t_id name
        }
        tasks(completed: {op: eq, val: false}) {
          edges {
            node {
              t_id name completed
            }
          }
        }
      }
    }
  }
  
  # relay node interface
  microsoft: node(id: "Y2xpZW50OjE=") {
    ... on Client {
      __typename id name
    }
  }
  
  # relay connections interface
  win7: node(id: "cHJvamVjdDox") {
    ... on Project {
      __typename id name
      tasks {
        pageInfo {
          count hasNextPage hasPreviousPage
        }
        edges {
          cursor
          node {
            t_id id name
          }
        }
      }
    }
  }
  
  # use of fragments
  fragments: clients {
    edges {
      node {
        ...clientInfo
        projects: projects {
          edges {
            cursor
            node {
              ...projectInfo
            }
          }
        }
      }
    }
  }
}

fragment clientInfo on Client {
  id t_id name
}

fragment projectInfo on Project {
  id t_id name
}
```

```graphql
mutation {
  insert {
    project(payload:{name: "New Project", client_id:1}){
      id
      name
      client {
        id t_id name
      }
    }
  }
}
```

```graphql
mutation {
  update {
    project(t_id: 1, payload:{name: "Updated Name"}){
      id
      name
      client {
        t_id id name
      }
    }
  }
}
```

Once you get a feel of how things work and feel adventurous,  try the system with your own schema. 

 - Stop the running containers `Ctrl + c` and remove them with `docker rm` command. (you can use `docker rm -v $(docker ps -a -q -f name=sampleapp_,status=exited)` to remove just the containers started as part of this docker-compose sample.)
 - Place your files in the `sql` directory.
 - comment the line `- RELAY_ID_COLUMN=id` to disable relay interface deneration
 - Start the system again with `docker-compose up`

Alternatively you could just have the containers connecting directly to your database. Edit `docker-compose-external-db.yml`  and then start the containers with `docker-compose -f docker-compose-external-db.yml up`

Another thing to explore is the nginx configurations in the `nginx` directory. Try editing them then uncomment the matching line for that file in `docker-compose.yml` to have the container use your custom file.
