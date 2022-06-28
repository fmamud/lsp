local http = require('http.server')

http.get("/jobs", function (request) 
    print("hi jobs get") 
end)

http.start()

