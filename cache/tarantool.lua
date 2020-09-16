local _M = {};

local log = require('log');

local function _create_cache_space()
    local s = box.schema.create_space(
        'cache',
        {
            field_count = 2,
            format = {
                {
                    name = 'key',
                    type = 'string',
                },
                {
                    name = 'value',
                    type = 'string',
                },
            },
        }
    );
    s:create_index('key_pk', { parts = {'key'} })
    return s
end

local function _build_cache_space()
    box.cfg {}
    if not box.space.cache then
        return _create_cache_space()
    end
    return box.space.cache
end

function _M:_cache_space()
    self.cache_space = self.cache_space or _build_cache_space()
    return self.cache_space
end

function _M:exists(key)
    return self:get(key)
end

function _M:set(key, value)
    self:_cache_space():upsert({ key, value }, { { '=', 'key', key } })
end

function _M:get(key)
    log.debug('Cache: get ' .. key)
    local tuple = self:_cache_space():select(key)
    return tuple.value
end

function _M.new()
    return setmetatable({}, { __index = _M })
end

return _M;
