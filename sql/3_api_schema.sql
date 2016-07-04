-- The following functions need to be in the public schema
set search_path to public;

create or replace function get_user_id(sess_id text) returns int as $$
	select user_id from data.sessions where session_id=sess_id::uuid;
$$ language sql stable security definer;

create or replace function get_user(usr_id int) returns table (user_id int, company_id int, user_role text) as $$
	select id, company_id, user_type::text as user_role from data.users where id=usr_id;
$$ language sql stable security definer;


create or replace function check_session_id() returns void as $$
declare
	sess_id text;
	usr_id int;
	usr record;
begin
	sess_id = nullif(current_setting('postgrest.claims.cookie.SESSIONID'),'');
	if sess_id <> '' then
		select get_user_id(sess_id) into usr_id;
    	if found then
			select get_user(usr_id) into usr;
			if found then
				execute 'set local postgrest.claims.user_id = ' || quote_literal(usr.id);
				execute 'set local postgrest.claims.company_id = ' || quote_literal(usr.company_id);
				execute 'set local role to ' || quote_ident(usr.user_role);
			end if;
		end if;
	end if;
end; $$ language plpgsql volatile;



create schema api;
set search_path to api, data, public;


create or replace view companies as
select c.node_id, id, name from data.companies as c
where 
	c.id = app_company_id() and -- filter only current company id
	(
		(app_user_type() = 'administrator') or
		(app_user_type() = 'employee')
	)
with local check option;
comment on view   companies is 'Company information';
comment on column companies.id is 'The primary key for the company';
comment on column companies.name is 'The company';
comment on column companies.node_id is 'System wide unique id for the company object';


create or replace view users as
select u.node_id, id, name, email, "password", user_type from data.users as u
where
	u.company_id = app_company_id() and -- filter only current company id
	(
		(app_user_type() = 'administrator') or
		(app_user_type() = 'employee')
	)
with local check option;
comment on view   users is 'Users information';
comment on column users.id is 'The primary key for the user';
comment on column users.name is 'The name of the user';
comment on column users.email is 'Email for the user';
comment on column users.password is 'Password for the user';
comment on column users.user_type is 'User type, can be employee of admin';
comment on column users.node_id is 'System wide unique id for the user object';



create or replace view clients as
select c.node_id, id, name, address from data.clients as c
where
	c.company_id = app_company_id() and -- filter only current company id
	(
		(app_user_type() = 'administrator') or -- admins can see all clients
		(
			app_user_type() = 'employee' and
			c.id in ( -- employees can see only clients from projects they are assgned to
				select client_id from data.projects as p
				where
					p.company_id = app_company_id() and
					p.id in ( -- a list of project ids the employee is assigned to
						select project_id from data.users_projects as up
						where up.company_id = app_company_id() and up.user_id = app_user_id()
					)
			)
		)
	)
with local check option;
comment on view   clients is 'Client information';
comment on column clients.id is 'The primary key for the client';
comment on column clients.name is 'The name of the client';
comment on column clients.address is 'The client address';
comment on column clients.node_id is 'System wide unique id for the client object';



create or replace view projects as
select p.node_id, id, name, client_id from data.projects as p
where
	p.company_id = app_company_id() and -- filter only current company id
	p.client_id in (select id from data.clients as c where c.company_id = app_company_id()) and -- allow client id only from current company (used in insert/update cases)
	(
		(app_user_type() = 'administrator') or -- admins can see all projects
		(
			app_user_type() = 'employee' and --employees can see only the projects they are assigned to
			p.id in ( -- a list of project ids the employee is assigned to
				select project_id from data.users_projects as up
				where up.company_id = app_company_id() and up.user_id = app_user_id()
			)
		)
	)
with local check option;
comment on view   projects is 'Project information';
comment on column projects.id is 'The primary key for the project';
comment on column projects.name is 'The name of the project';
comment on column projects.client_id is 'Foreign key reference to client';
comment on column projects.node_id is 'System wide unique id for the project object';


create or replace view tasks as
select t.node_id, id, name, project_id from data.tasks as t
where
	t.company_id = app_company_id() and -- filter only current company id
	t.project_id in (select id from data.projects as p where p.company_id = app_company_id()) and -- allow project id only from current company (used in insert/update cases)
	(
		(app_user_type() = 'administrator') or
		(
			app_user_type() = 'employee' and
			t.id in (
				select t.id from data.tasks as t
				left join data.users_tasks as ut on t.id = ut.task_id
				where 
					t.company_id = app_company_id() and -- filter tasks from current company
					t.project_id in ( -- filter tasks from projects the employee is assigned to
						select project_id from data.users_projects as up2
						where up2.company_id = app_company_id() and up2.user_id = app_user_id()
					) and
					(ut.user_id = app_user_id() or ut.user_id is null) -- filter tasks that are unassigend or directly assigned to the current employee
			)
		)
	)
with local check option;
comment on view   tasks is 'Task information';
comment on column tasks.id is 'The primary key for the task';
comment on column tasks.name is 'The name of the task';
comment on column tasks.project_id is 'Foreign key reference to project';
comment on column tasks.node_id is 'System wide unique id for the task object';



create or replace view users_projects as
select up.node_id, user_id, project_id from data.users_projects as up
where
	up.company_id = app_company_id() and -- filter only current company id
	up.project_id in (select id from data.projects as p where p.company_id = app_company_id()) and -- allow project id only from current company (used in insert/update cases)
	up.user_id in (select id from data.users as u where u.company_id = app_company_id()) and -- allow user id only from current company (used in insert/update cases)
	(
		(app_user_type() = 'administrator') or -- admins can see all associations
		(
			app_user_type() = 'employee' and
			up.project_id in ( -- employees can see only the assiciations for projects they are assigned to
				select project_id from data.users_projects as up2
				where up2.company_id = app_company_id() and up2.user_id = app_user_id()
			)
		)
	)
with local check option;
comment on view   users_projects is 'User - project assignaments';
comment on column users_projects.user_id is 'Foreign key reference to user';
comment on column users_projects.project_id is 'Foreign key reference to project';
comment on column users_projects.node_id is 'System wide unique id for the user_project object';



create or replace view users_tasks as
select ut.node_id, user_id, task_id from data.users_tasks as ut
where
	ut.company_id = app_company_id() and -- filter only current company id
	ut.user_id in (select id from data.users as u where u.company_id = app_company_id()) and -- allow user id only from current company (used in insert/update cases)
	ut.task_id in (select id from data.tasks as t where t.company_id = app_company_id()) and -- allow task id only from current company (used in insert/update cases)
	(
		(app_user_type() = 'administrator') or
		(app_user_type() = 'employee' and -- employees can see only thier own task assignaments
			ut.user_id = app_user_id()
		)
	)
with local check option;
comment on view   users_tasks is 'User - task assignaments';
comment on column users_tasks.user_id is 'Foreign key reference to user';
comment on column users_tasks.task_id is 'Foreign key reference to task';
comment on column users_tasks.node_id is 'System wide unique id for the user_project object';




drop type if exists jwt_claims cascade;
create type jwt_claims AS (role text, user_id int, company_id int);

create or replace function
login_jwt(email text, password text) returns api.jwt_claims
stable security definer
language plpgsql
as $$
declare
	result api.jwt_claims;
	eml text;
	pass text;
begin
	--assign to another name to prevent name ambiguity in relation to table names
	eml := email;
	pass := password;

    select user_type::text as role, id as user_id, company_id into result
    from data.users as u
    where u.email = eml and u.password = pass;
    if not found then
    	raise exception 'invalid email/password';
    end if;
    return result;
end
$$;
comment on function login_jwt(email text, password text) is 'Returns a jwt claims object';
revoke all privileges on function login_jwt(text, text) from public;

drop type if exists session_claims cascade;
create type session_claims AS (
  name text,
  value text,
  "path" text,
  expires integer,
  max_age integer,
  domain text,
  http_only boolean,
  secure boolean
);

create or replace function
login_session(email text, password text) returns api.session_claims
volatile security definer
language plpgsql
as $$
declare
	usr data.users;
	eml text;
	pass text;
	sess data.sessions;
begin
	--assign to another name to prevent name ambiguity in relation to table names
	eml := email;
	pass := password;

    select * into usr
    from data.users as u
    where u.email = eml and u.password = pass;
    if not found then
    	raise exception 'invalid email/password';
    else
    	insert into data.sessions (user_id, company_id)
    	values (usr.id, usr.company_id)
    	returning * into sess;
    	return (
		   	-- 'PGSESSID'::text as name,
		    -- sess.session_id::text as value,
		    -- null::text    as "path" --'/'::text as "path",
		    -- null::integer as expires --1000::integer as expires,
		    -- 300::integer  as max_age,
		    -- null::text    as domain, --'mydomain.com'::text as domain,
		    -- null::boolean as http_only, --true as http_only,
		    -- null::boolean as secure --true as secure
		    'SESSIONID'::text,
		    sess.session_id::text,
		    null::text,--'/'::text as "path",
		    null::integer, --1000::integer as expires,
		    3600::integer,
		    null::text, --'mydomain.com'::text as domain,
		    null::boolean, --true as http_only,
		    null::boolean --true as secure

		);

    end if;
end
$$;
comment on function login_session(email text, password text) is 'Returns a jwt claims object';
revoke all privileges on function login_session(text, text) from public;


create or replace function
signup(company_name text, user_name text, email text, password text) returns void
security definer
language plpgsql
as $$
declare
	company data.companies%rowtype;
	user data.users%rowtype;
begin
	insert into data.companies (name)
	values (company_name)
	returning * into company;

	insert into data.users (name, email, password, user_type, company_id)
	values (user_name, email, password, 'administrator', company.id)
	returning * into user;
end
$$;
comment on function signup(company_name text, user_name text, email text, password text) is 'Creates a new company and a user in that company';
revoke all privileges on function signup(text, text, text, text) from public;


create or replace function get_client(id int) returns api.clients as $$
   select * from api.clients where id = $1
$$ language sql immutable;
revoke all privileges on function get_client(int) from public;


create or replace function sum_n_product (x int, y int, out sum int, out product int) as $$
	select x + y, x * y
$$ language sql immutable;
revoke all privileges on function sum_n_product(int, int) from public;

create or replace function new_client() returns clients as $$
   select 'aaaa'::text, 10, 'new cleint'::text, 'address'::text
$$ language sql immutable;
revoke all privileges on function new_client() from public;


create or replace function bang(clients) returns text as $$
   select $1.name || '!' as name;
$$ language sql immutable;
revoke all privileges on function bang(clients) from public;

create or replace function sales_tax(subtotal real) returns double precision as $$
  select subtotal * 0.06;
$$ language sql immutable;
revoke all privileges on function sales_tax(real) from public;



