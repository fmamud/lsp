local request = {}

local verbs = {"GET", "POST"}

local command = "curl -i"

local mt = {
    __index = function (t, target)
        if not target then
            error(string.format("Invalid HTTP verb: %s", verb), 2)
        end

        local target = target:upper()
        
        return function(path)
            local response <close> = io.popen(string.format('%s -c "%s"', connection_url(), sql))
        end
    end
}

local show = {
    __tostring = function(t)
        local params = {}
        for param, value in pairs(t.params) do
            table.insert(params, string.format("%s=%s", param, value))
        end

        local params_show = #params > 0 and string.format("?%s", table.concat(params, "&")) or ""
        return string.format("%s %s %s %s %s", os.date(), t.version, t.verb, t.path, params_show)
    end
}

setmetatable(request, mt)

function request.verb(target)
    for idx, verb in pairs(verbs) do
        if verb:upper() == target then
            return target
        end
    end
    
    error(string.format("HTTP '%s' verb not available: [%s]", target, table.concat(verbs, ", ")))
end

function request.parse(input)
    local request, headers = setmetatable({}, show), {}
    for line in input:lines() do
        if line == "\r" then break end

        for verb, path, version in line:gmatch("(%u+) (/%g+) (HTTP/%g+)") do
            request.verb = verb

            local params = {}
            for name, value in path:gmatch("([^&=?]-)=([^&=?]+)") do
                params[name] = value
            end

            request.path = path:match("([^?]+)")
            request.params = params
            request.version = version
        end

        for name, value in line:gmatch("(%g+:) (%g+)") do
            headers[name] = value
        end
    end
    request.headers = headers
    return request
end

return request