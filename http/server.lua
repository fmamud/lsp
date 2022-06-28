local http = {}

local handlers = {}

local VERBS = {"GET", "POST"}

local function get_verb(target)
    for idx, verb in pairs(VERBS) do
        if verb:upper() == target then
            return target
        end
    end
end


local mt = {
    __index = function (t, target)
        if not target then
            error(string.format("Invalid HTTP verb: %s", verb), 2)
        end

        local target = target:upper()

        local verb = get_verb(target)
        
        if not verb then
            error(string.format("HTTP '%s' verb not available: [%s]", target, table.concat(VERBS, ", ")))
        end
        
        return function(path, fn)
            local path_found = rawget(handlers, path)
            if not path_found then
                handlers[path] = {[verb] = fn}
            else
                local verb_found = rawget(path_found, verb)
                if not verb_found then
                    path_found[verb] = fn
                else
                    error(string.format("%s %s already registered", verb, path), 2)
                end
            end
        end
    end
}

setmetatable(http, mt)

local function dump(o)
    if type(o) == "table" then
        if #o > 0 then
            return string.format("[%s]", table.concat(o, ","))
        else
            local s = {}
            for key, value in pairs(o) do
                table.insert(s, string.format("\"%s\":%s", key, dump(value)))
            end
            return string.format("{%s}", table.concat(s, ","))
        end
    end

    if type(o) == "string" then
        return string.format("\"%s\"", o)
    end

    return tostring(o)
end

local function get_request(input)
    local request, headers = {}, {}
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

local function get_handler(request)
    local path = rawget(handlers, request.path)
    if path then
        return rawget(path, request.verb)
    end
end

local function perform(request)
    local fn = get_handler(request)
    if fn then
        local ok, result = pcall(fn, request)

        local response = {
            request = request,
            status = 200,
            reason = "OK",
            headers = {["Content-Type"] = "text/plain"},
            version = request.version,
            body = result
        }

        if not ok then
            response.status = 500
            response.reason = "Internal Server Error"
        else
            if type(result) == "table" then
                response.headers["Content-Type"] = "application/json"
                response.body = dump(result)
            end
        end
        return response
    end
end


function http.start(host, port)
    local host = host or "localhost"
    local port = port or 1234
    
    print(string.format("Listening on %s:%d", host, port))

    local buffer = os.tmpname()
    local input <close> = io.popen(string.format("tail -f %s", buffer))

    while true do
        local nc <close> = io.popen(string.format("nc -lv %d >> %s 2>&1", port, buffer), "w")

        local request = get_request(input)

        local response = perform(request)

        local status = string.format("%s %d %s", request.version, response.status, response.reason)

        local headers = ""
        for name, value in pairs(response.headers) do
            headers = headers .. string.format("%s: %s\r\n", name, value)
        end

        local output = string.format("%s\r\n%s\r\n%s", status, headers, response.body)

        nc:write(output)
    end

    os.remove(buffer)
end

return http