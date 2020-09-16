#!/usr/bin/env tarantool

local router        = require('http.router').new()
local kv_controller = require('cache_web.controller.kv')
local log           = require('log')

---- Set up routes

-- POST /kv
router:route(
    {
        path   = '/kv',
        method = 'POST',
    },
    kv_controller.post
)
-- PUT /kv/:key
router:route(
    {
        path   = '/kv/:key',
        method = 'PUT',
    },
    kv_controller.put
)
-- GET /kv/:key
router:route(
    {
        path   = '/kv/:key',
        method = 'GET',
    },
    kv_controller.get
)
-- DELETE /kv/:key
router:route(
    {
        path   = '/kv/:key',
        method = 'DELETE',
    },
    kv_controller.delete
)

----
-- Set up logging via a middleware
assert(
    router:use(
        function(req)
            local response = req:next()
            log.error('Calling "' .. req:method() .. ' ' .. req:path() .. '" returned ' .. (response.status or 200))
            return response
        end,
        {}
    )
)

---- Set up and run HTTP server
local server = require('http.server').new(
    'localhost',
    5000,
    {
        display_errors = true,
        log_requests   = true,
        log_errors     = true,
    }
)
server:set_router(router)
server:start()
