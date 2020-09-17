#!/usr/bin/env tarantool

local router        = require('http.router').new()
local kv_controller = require('cache.web.controller.kv')
local log           = require('log')
local queue         = require('queue')

---- Configure tarantool
--
box.cfg {
    log = 'cache_web.log',
}

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
            log.info('Call to "' .. req:method() .. ' ' .. req:path() .. '" returned ' .. (response.status or 200))
            return response
        end,
        {}
    )
)

-- Set up rate limiting
-- Implemented using an in-memory queue with the limited amount of tasks, where
-- each task has a limited life time.
--
-- It might be worth to extract rate limiting logic into a separate module.
--
-- Allow up to RATE_LIMIT requests per second
local RATE_LIMIT = 2

-- Drop and recreate tube, if any
if queue.tube.rate_limit then
    queue.tube.rate_limit:drop()
end

local rate_limit_tube = queue.create_tube(
    'rate_limit',
    'limfifottl',
    {
        temporary = true,
        capacity  = RATE_LIMIT,
    }
)
assert(
    router:use(
        function(req)
            local task = rate_limit_tube:put('', { ttl = 1 });
            if task then
                return req:next()
            end
            log.info('Rate limit exceeded')
            return { status = 429 }
        end,
        {}
    )
)

---- Set up and run HTTP server
local server = require('http.server').new(
    '*',
    5000,
    {
        display_errors = true,
        log_requests   = false,
        log_errors     = true,
    }
)
server:set_router(router)
server:start()
