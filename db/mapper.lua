local mapper = {}

function mapper.table(columns, resultset)
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

function mapper.count(columns, resultset)
    if #columns == 1 then
        return resultset:read("n")
    end

    error(string.format("Count query must return a single result. (expected: 1, actual: %d)", #columns), 3)
end

return mapper