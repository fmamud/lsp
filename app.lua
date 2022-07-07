local http = require('http.server')

http.get("/hello", function (request)
    return "It works!"
end)

http.start()