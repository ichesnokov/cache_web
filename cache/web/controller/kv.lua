local _M = {};

local cache = require('cache/tarantool'):new()
local json  = require('json')

local function empty_response(status_code)
    return {
        status  = status_code,
        headers = { ['content-type'] = 'application/json; charset=utf8' },
        body    = '',
    }
end

_M.get = function(req)
    -- Get key from route
    local key = req:stash('key')

    if not cache:exists(key) then
        return empty_response(404)
    end

    return req:render({ json = { value = json.decode(cache:get(key)) } })
end

_M.post = function(req)

    local req_data = req:json()
    local key   = req_data.key
    local value = req_data.value

    -- Key and value must be defined
    if key == nil or value == nil then
        return empty_response(400)
    end

    if cache:exists(key) then
        return empty_response(409)
    end

    cache:set(key, json.encode(value))

    return req:render({ json = { success = true } })
end

_M.put = function(req)

    -- Value must be defined
    local req_data = req:json()
    local value = req_data.value
    if value == nil then
        return empty_response(400)
    end

    local key = req:stash('key')
    if not cache:exists(key) then
        return empty_response(404)
    end

    cache:set(key, json.encode(value))

    return req:render({ json = { success = true } })
end

_M.delete = function(req)
    local key = req:stash('key')
    if not cache:exists(key) then
        return empty_response(404)
    end

    cache:delete(key)

    return req:render({ json = { success = true } })
end

return _M;
