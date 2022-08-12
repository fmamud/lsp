local postgresql = {}

local command = "PGPASSWORD=$password psql --csv -h $host -p $port -U $username $name"

local config = {
    name = os.getenv("DB_NAME") or "postgres",
    host = os.getenv("DB_HOST") or "localhost",
    port = os.getenv("DB_PORT") or "5432",
    username = os.getenv("DB_USERNAME") or "postgres",
    password = os.getenv("DB_PASSWORD") or "password",
}

local function connection_url()
    return string.gsub(command, "%$(%w+)", config)
end

local function execute(sql, mapper)
    if not sql or sql:len() == 0 then
        error(string.format("Query must be not null and not empty", sql))
    end

    local sql = sql:gsub("\"", "")
    local resultset <close> = io.popen(string.format('%s -c "%s"', connection_url(), sql))

    local columns = {}
    for column in resultset:read("l"):gmatch("%w+") do
        table.insert(columns, column)
    end
    
    return mapper(columns, resultset)
end

local function table_mapper(columns, resultset)
    local result = {}
    for line in resultset:lines() do
        local column = {}
        local counter = 1
        for value in line:gmatch("%w+") do
            column[columns[counter]] = value
            counter = counter + 1
        end
        table.insert(result, column)
    end

    return result
end

local function count_mapper(columns, resultset)
    if #columns == 1 then
        return resultset:read("n")
    end

    error(string.format("Count query must return a single result. (expected: 1, actual: %d)", #columns), 3)
end

function postgresql.query(sql)
    return execute(sql, table_mapper)
end

function postgresql.count(sql)
    return execute(sql, count_mapper)
end

return postgresql