-- df: offset=100
-- df: size=1

-- df nouns: word=./dictionaries/nouns.txt
-- df adjectives: word=./dictionaries/adjectives.txt
-- df verbs: word=./dictionaries/verbs.txt
-- df first: word=./dictionaries/first_names.txt
-- df last: word=./dictionaries/last_names.txt
-- df companies: word=./dictionaries/companies.txt
-- df pass: const=pass
-- df space: const=' '


create schema data;
set search_path to data, public;

create sequence public.companies_seq start 100;
create table companies (
	id                   int primary key not null unique default nextval('companies_seq'),
	name                 text not null check(length(name)>3 and length(name)<100) -- df: use=companies
);


create type user_type as enum ('administrator', 'employee');

create sequence public.users_seq start 100;
create table users (  -- df: mult=5.0
	id                   int primary key not null unique default nextval('users_seq'),
	name                 text not null check(length(name)>3), -- df: cat=first,space,last
	-- there should also be unique constraint on email but removed because of datafiller not supporting unique on pattern generator
	email                text not null check(email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'), -- df: pattern='[a-z]{3,8}\.[a-z]{3,8}@(gmail|yahoo)\.com'
	"password"           text, -- df: use=pass
	user_type            user_type not null default 'employee',
	company_id           int not null references companies(id) default current_company_id()
);
create index users_company_id_index on users(company_id);


create sequence public.clients_seq start 100;
create table clients (  -- df: mult=10.0
	id                   int primary key not null unique default nextval('clients_seq'),
	name                 text not null check(length(name)>3), -- df: use=companies
	address              text,
	company_id           int not null references companies(id) default current_company_id()
);
create index clients_company_id_index on clients(company_id);

create sequence public.projects_seq start 100;
create table projects (  -- df: mult=20.0
	id                   int primary key not null unique default nextval('projects_seq'),
	name                 text not null check(length(name)>=3), -- df: cat=adjectives,space,nouns
	client_id            int not null references clients(id),
	company_id           int not null references companies(id) default current_company_id()
);
create index projects_company_id_index on projects(company_id);

create sequence public.tasks_seq start 100;
create table tasks (  -- df: mult=200.0
	id                   int primary key not null unique default nextval('tasks_seq'),
	name                 text not null check(length(name)>3), -- df: cat=verbs,space,adjectives,space,nouns
	completed            bool not null default false,
	project_id           int not null references projects(id),
	company_id           int not null references companies(id) default current_company_id()
);
create index tasks_company_id_index on tasks(company_id);

create sequence public.users_projects_seq start 100;
create table users_projects ( -- df: nogen
	project_id           int not null references projects(id),
	user_id              int not null references users(id),
	company_id           int references companies(id) default current_company_id(),
	primary key (project_id, user_id)
);
create index users_projects_company_id_index on users_projects(company_id);

create sequence public.users_tasks_seq start 100;
create table users_tasks ( -- df: nogen
	task_id              int not null references tasks(id),
	user_id              int not null references users(id),
	company_id           int not null references companies(id) default current_company_id(),
	primary key (task_id, user_id)
);
create index users_tasks_company_id_index on users_tasks(company_id);

create table sessions ( -- df: nogen
	session_id           uuid primary key default gen_random_uuid(),
	user_id              int references users(id),
	company_id           int references companies(id)
);


-- these functions are used as virtual columns in views from the api schema which are needed to generate a globaly
-- unique row id used by Relay
create or replace function relay_id(companies) returns text as $$
select encode(convert_to('company:' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on companies (relay_id(companies.*));

create or replace function relay_id(users) returns text as $$
select encode(convert_to('user:' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users (relay_id(users.*));

create or replace function relay_id(clients) returns text as $$
select encode(convert_to('client:' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on clients (relay_id(clients.*));

create or replace function relay_id(projects) returns text as $$
select encode(convert_to('project:' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on projects (relay_id(projects.*));

create or replace function relay_id(tasks) returns text as $$
select encode(convert_to('task:' || $1.id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on tasks (relay_id(tasks.*));

create or replace function relay_id(users_projects) returns text as $$
select encode(convert_to('user_project:' || $1.user_id::text || ':' || $1.project_id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users_projects (relay_id(users_projects.*));

create or replace function relay_id(users_tasks) returns text as $$
select encode(convert_to('user_task:' || $1.user_id::text || ':' || $1.task_id::text, 'utf-8'), 'base64')
$$ immutable language sql;
create index on users_tasks (relay_id(users_tasks.*));



