create schema data;
set search_path to data, public;

create sequence public.companies_seq start 100;
create table companies ( 
	id                   int primary key not null unique default nextval('companies_seq'),
	name                 text not null
);


create type user_type as enum ('administrator', 'employee');

create sequence public.users_seq start 100;
create table users ( 
	id                   int primary key not null unique default nextval('users_seq'),
	name                 text not null,
	email                text unique not null,
	"password"           text,
	user_type            user_type not null default 'employee',
	company_id           int references companies(id) default app_company_id()
);
create index users_company_id_index on users(company_id);


create sequence public.clients_seq start 100;
create table clients ( 
	id                   int primary key not null unique default nextval('clients_seq'),
	name                 text not null,
	address              text,
	company_id           int references companies(id) default app_company_id()
);
create index clients_company_id_index on clients(company_id);

create sequence public.projects_seq start 100;
create table projects ( 
	id                   int primary key not null unique default nextval('projects_seq'),
	name                 text not null,
	client_id            int references clients(id),
	company_id           int references companies(id) default app_company_id()
);
create index projects_company_id_index on projects(company_id);

create sequence public.tasks_seq start 100;
create table tasks ( 
	id                   int primary key not null unique default nextval('tasks_seq'),
	name                 text not null,
	project_id           int references projects(id),
	company_id           int references companies(id) default app_company_id()
);
create index tasks_company_id_index on tasks(company_id);

create sequence public.users_projects_seq start 100;
create table users_projects ( 
	project_id           int references projects(id),
	user_id              int references users(id),
	company_id           int references companies(id) default app_company_id(),
	primary key (project_id, user_id)
);
create index users_projects_company_id_index on users_projects(company_id);

create sequence public.users_tasks_seq start 100;
create table users_tasks ( 
	task_id              int references tasks(id),
	user_id              int references users(id),
	company_id           int references companies(id) default app_company_id(),
	primary key ( task_id, user_id )
);
create index users_tasks_company_id_index on users_tasks(company_id);

create table sessions ( 
	session_id           uuid primary key default gen_random_uuid(),
	user_id              int references users(id),
	company_id           int references companies(id)
);


create or replace function node_id(companies) returns text as $$
select encode(convert_to('company_' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on companies (node_id(companies.*));

create or replace function node_id(users) returns text as $$
select encode(convert_to('user_' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users (node_id(users.*));

create or replace function node_id(clients) returns text as $$
select encode(convert_to('client_' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on clients (node_id(clients.*));

create or replace function node_id(projects) returns text as $$
select encode(convert_to('project_' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on projects (node_id(projects.*));

create or replace function node_id(tasks) returns text as $$
select encode(convert_to('task_' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on tasks (node_id(tasks.*));

create or replace function node_id(users_projects) returns text as $$
select encode(convert_to('user_project_' || $1.user_id::text || '_' || $1.project_id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users_projects (node_id(users_projects.*));

create or replace function node_id(users_tasks) returns text as $$
select encode(convert_to('user_task_' || $1.user_id::text || '_' || $1.task_id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users_tasks (node_id(users_tasks.*));

