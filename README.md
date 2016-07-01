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


This repo contains a sample app that demonstrates the capabilities of Sub0 platform.
To run this you need to have docker installed on your system and logged in with your dockerhub id.
At the moment, the images are private so you need to also request access on [Sub0 site](http://graphqlapi.com) for your dockerhub id.

```shellscript
git clone https://github.com/ruslantalpa/sub0_sample_app.git
cd sub0_sample_app
docker-compose up
```

In your browser navigate to `http://your.docker.machine.ip:8080/graphiql/`
Toggle the `Docs` panel (top right corner) to explore the types/endpoints

Use this JWT to run queries `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW5pc3RyYXRvciIsInVzZXJfaWQiOjEsImNvbXBhbnlfaWQiOjF9.ate5mETtGRu-mfGF4jFt7pP1b4W85r2uEXt603D7obc`

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
{
  projects {
    id
    name
    client {
      id
      name
    }
    tasks {
      id
      name
    }
  }
}
```

```graphql
mutation {
  insert {
    project(payload:{name: "New Project", client_id:1}){
      id
      name
      client {
        id
        name
      }
    }
  }
}
```

```graphql
mutation {
  update {
    project(id: 1, payload:{name: "Updated Name"}){
      id
      name
      client {
        id
        name
      }
    }
  }
}
```

Once you get a feel of how things work and feel adventurous,  try the system with your own schema. 

 - Stop the running containers `Ctrl + c` and remove them with `docker rm` command. (you can use `docker rm -v $(docker ps -a -q -f status=exited)` but be aware that it will remove all your other exited containers)
 - Place your files in the `sql` directory.
 - Start the system again with `docker-compose up`

Another thing to explore is the nginx configurations in the `nginx` directory. Try editing them then uncomment the matching line for that file in `docker-compose.yml` to have the container use your custom file.
