This directory contains the the definition of your database schema, and in fact this is 95% of the backend code (the definitions of your tables and views with appropriate constraints)

By default the database will contain a small dataset (one company).
If you want to generate a bigger dataset, run these commands before bringing the docker containers up (adjust the size to the number of companies you want in the database, each company will have about 5 user, 10 clients, 20 projects, 200 tasks)
```
# download the datafiller script, run only once
curl -s https://raw.githubusercontent.com/memsql/datafiller/master/datafiller -o datafiller && chmod +x datafiller

# generate the dataset sql file based on the defined schema (for details of how this works check https://www.cri.ensmp.fr/people/coelho/datafiller.html)
{ echo "set search_path to data, public;" & ./datafiller --no-freeze --size=1000 2_data_schema.sql; } > 6_big_dataset.sql
```
