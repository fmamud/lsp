local postgresql = {}
local mapper = require("db.mapper")

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

local function execute(sql, mapper_fn)
    if not sql or sql:len() == 0 then
        error(string.format("Query must be not null and not empty", sql))
    end

    local sql = sql:gsub("\"", "")
    local resultset <close> = io.popen(string.format('%s -c "%s"', connection_url(), sql))

    local columns = {}
    for column in resultset:read("l"):gmatch("%w+") do
        table.insert(columns, column)
    end
    
    return mapper_fn(columns, resultset)
end

function postgresql.query(sql)
    return execute(sql, mapper.table)
end

function postgresql.count(sql)
    return execute(sql, mapper.count)
end

return postgresql