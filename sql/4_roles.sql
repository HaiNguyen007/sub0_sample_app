drop role if exists anonymous, administrator, employee;
drop role if exists authenticator;
create role authenticator with login password 'authenticator';
create role anonymous;
create role administrator;
create role employee;

grant anonymous  to authenticator;
grant administrator    to authenticator;
grant employee to authenticator;


grant usage on schema api to administrator, employee, anonymous;

set search_path to api;

grant select
on companies,users,clients,projects,tasks,users_projects,users_tasks
to administrator;

grant insert, update, delete
on users,clients,projects,tasks,users_projects,users_tasks
to administrator;

grant usage 
on public.companies_seq, public.users_seq, public.clients_seq, public.projects_seq, public.tasks_seq, public.users_projects_seq, public.users_tasks_seq
to administrator;

grant select
on companies,users,projects,tasks,users_projects,users_tasks
to employee;

grant select (id, name)
on clients
to employee;

grant execute on function
get_client(id int),
sum_n_product(x int, y int, out sum int, out product int),
new_client(),
sales_tax(subtotal real),
bang(clients)
to administrator;


-- this is needed for check_session_id to work without being a security definer
-- grant usage on schema data to anonymous;
-- grant select
-- on data.sessions, data.users
-- to anonymous;

grant execute on function
login_jwt(text,text),
login_session(text,text),
signup(text,text,text,text)
to anonymous;

