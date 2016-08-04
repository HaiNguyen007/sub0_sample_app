-- For every GET request this function returns the cache key, tags and the ttl for the current request.
-- If you do not want the request to be cached, return a nil value for key.

-- Implementation specifics
-- For every PostgREST request (except RPC calls) we can figure out the tables involved at generating the response
-- by looking at the endpoint name and select parameter. We tag each request with the name of the tables involved
-- in generating that request for GET. 
local function get_cache_key(ngx_vars, uri_args, headers, get_ast)
    local function get_request_tags(ngx_vars, uri_args, headers, get_ast)
        local tags = {}
        local endpoint = ngx_vars.uri:gsub('/rest/', '')
        table.insert(tags, endpoint)
        local synonyms = { 
            client='clients', client_id='clients', 
            project='projects', project_='projects',
            user='users', user_='users',
            task='tasks', task_='tasks'
        }
        local matches = (uri_args.select or '*'):gsub(' ',''):gfind('([^,:]+){')
        for tag in matches do
            table.insert(tags, (synonyms[tag] or tag))
        end
        return unique(tags)
    end
    local key_parts = { ngx_vars.scheme, ngx_vars.host, ngx_vars.uri, ngx_vars.args or '', headers.Authorization }
    local key = table.concat(key_parts,':')
    local ttl = 60 -- seconds
    local tags = get_request_tags(ngx_vars, uri_args, headers, get_ast)
    return key, ttl, tags
end

-- For every (PATCH/POST/DELETE) this function is called and returned list represents the cache tags that must be invalidated by the current request.
local function get_cache_tags(ngx_vars, uri_args, headers, get_ast)
    local endpoint = ngx_vars.uri:gsub('/rest/', '')
    return {endpoint}
end

--[[
Hooks to rename the auto generated names of the types and entrypoints for each table
--]]

local function table_type_name(table_name)
    local overrides = {
        projects = 'MyProject'
    }
    return overrides[table_name]
end

local function entrypoint_name(table_name, single_item)
    local singular_overrides = {
        projects = 'my_project'
    }
    local plural_overrides = {
        projects = 'my_projects'
    }
    return single_item and singular_overrides[table_name] or plural_overrides[table_name]
end

return {
    get_cache_key  = get_cache_key,
    get_cache_tags = get_cache_tags,
    table_type_name = table_type_name,
    entrypoint_name = entrypoint_name
}
