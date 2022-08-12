local http = require('http.server')
local postgresql = require('db.postgresql')

http.get("/health", function (request)
    return "It works!"
end)

http.get("/data", function (request)
    return postgresql.count("select count(1) from mydata")
end)

http.start()