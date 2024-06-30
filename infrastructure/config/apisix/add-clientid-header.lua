local jwt = require("resty.jwt")
local core = require("apisix.core")
local ngx_re = require("ngx.re")
local plugin_name = "add-clientid-header"
local ngx = ngx

local string = string

-- define the schema for the Plugin
local schema = {
    type = "object"
}

local _M = {
    version = 0.1,
    priority = 2596,
    name = plugin_name,
    schema = schema
}

function _M.check_schema(conf)
    return true
end

local function get_bearer_access_token(ctx)
    -- Get Authorization header, maybe.
    local auth_header = core.request.header(ctx, "Authorization")
    if not auth_header then
        -- No Authorization header, get X-Access-Token header, maybe.
        local access_token_header = core.request.header(ctx, "X-Access-Token")
        if not access_token_header then
            -- No X-Access-Token header neither.
            return false
        end

        -- Return extracted header value.
        return true, access_token_header, nil
    end

    -- Check format of Authorization header.
    local res, err = ngx_re.split(auth_header, " ", nil, nil, 2)

    if not res then
        -- No result was returned.
        return false, nil, err
    elseif #res < 2 then
        -- Header doesn't split into enough tokens.
        return false, nil, "Invalid Authorization header format."
    end

    if string.lower(res[1]) == "bearer" then
        -- Return extracted token.
        return true, res[2], nil
    end

    return false, nil, nil
end

local function isEmpty(s)
    return s == nil or s == ''
end

function _M.rewrite(plugin_conf, ctx)

    local clientIdHeader = plugin_conf.header_name and plugin_conf.header_name or "x-cell-client-id"

    core.log.debug("Custom Header name: ", clientIdHeader)


    if(core.request.header(ctx, clientIdHeader)) then
        core.log.debug("Header ", clientIdHeader, " already exists in the request")
        core.log.debug("Skipping add-client-id-header plugin execution")
        return
    end

    local has_token, jwt_token, err = get_bearer_access_token(ctx)
    core.log.debug("has_token: ", has_token, " err: ", err)

    if not (isEmpty(err) and has_token) then
        core.log.debug("No JWT token found in Authorization or X-Access-Token header")
        return
    end

    local jwt_obj, jwtErr = jwt:load_jwt(jwt_token)

    if jwt_obj and jwt_obj.payload then
        local client_id = jwt_obj.payload.client_id
        ngx.log(ngx.DEBUG, "JWT payload decoded")
        if client_id then
            -- Add the client_id as a custom header to the request
            core.request.set_header(ctx, clientIdHeader, client_id)
            core.log.debug("Added Custom Header",clientIdHeader, " with value: ", client_id)
        else
            core.log.debug("No client_id found in JWT payload")
        end
    else
        core.log.debug("Error decoding JWT: ", jwtErr)
    end
end

return _M
