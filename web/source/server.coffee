
#-----------------------------------------------------------------
# Setup
#-----------------------------------------------------------------

app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

#-----------------------------------------------------------------
# Configure
#-----------------------------------------------------------------

app.configure ()->
  app.set('view engine', 'jade')

#-----------------------------------------------------------------
# Connection
#-----------------------------------------------------------------

io.on 'connection', () ->
  console.log('.... serving')

app.get '/', (req, res) ->
  res.send('.... serving')

app.get '/socket/', (req, res) ->
  res.send('.... serving')

#-----------------------------------------------------------------
# Listener
#-----------------------------------------------------------------

server.listen(3000)