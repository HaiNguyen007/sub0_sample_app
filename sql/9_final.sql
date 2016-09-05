-- Fix the company_id fields on tables because datafiller does not know how to make the corellation
update data.projects p
set company_id = (select c.company_id from data.clients c where c.id = p.client_id);

update data.tasks t
set company_id = (select p.company_id from data.projects p where p.id = t.project_id);

