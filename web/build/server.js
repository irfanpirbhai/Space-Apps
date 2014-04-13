(function() {
  var ABUNDANT_MINERALS, ABUNDANT_TOTAL, Asteroid, COMMON_MINERALS, COMMON_TOTAL, Game, MINERALS, Player, SCARCE_MINERALS, SCARCE_TOTAL, app, express, game, initGame, io, isAbundant, isCommon, isScarce, randomInt, server;

  ABUNDANT_TOTAL = 10000;

  COMMON_TOTAL = 5000;

  SCARCE_TOTAL = 1000;

  ABUNDANT_MINERALS = ['iron', 'carbon', 'silicon'];

  COMMON_MINERALS = ['water', 'nickel', 'cobalt', 'titanium', 'magnesium'];

  SCARCE_MINERALS = ['platinum', 'gold', 'silver'];

  MINERALS = ABUNDANT_MINERALS.concat(COMMON_MINERALS, SCARCE_MINERALS);

  Asteroid = function() {
    this.minerals = {
      iron: ABUNDANT_TOTAL,
      carbon: ABUNDANT_TOTAL,
      silicon: ABUNDANT_TOTAL,
      water: COMMON_TOTAL,
      nickel: COMMON_TOTAL,
      cobalt: COMMON_TOTAL,
      titanium: COMMON_TOTAL,
      magnesium: COMMON_TOTAL,
      platinum: SCARCE_TOTAL,
      gold: SCARCE_TOTAL,
      silver: SCARCE_TOTAL
    };
    this.totalSize = function() {
      var mineral, size, _i, _len;
      size = 0;
      for (_i = 0, _len = MINERALS.length; _i < _len; _i++) {
        mineral = MINERALS[_i];
        size += this.minerals[mineral];
      }
      return size;
    };
    this.isEmpty = function() {
      return this.totalSize() <= 0;
    };
    this.presentMinerals = function() {
      var mineral, minerals, _i, _len;
      minerals = [];
      for (_i = 0, _len = MINERALS.length; _i < _len; _i++) {
        mineral = MINERALS[_i];
        if (this.minerals[mineral] > 0) {
          minerals.push(mineral);
        }
      }
      return minerals;
    };
    this.loseMineral = function(mineral, amount) {
      return this.minerals[mineral] -= amount;
    };
  };

  Player = function() {
    this.minerals = {
      iron: 0,
      carbon: 0,
      silicon: 0,
      water: 0,
      nickel: 0,
      cobalt: 0,
      titanium: 0,
      magnesium: 0,
      platinum: 0,
      gold: 0,
      silver: 0
    };
    this.findMineral = function(mineral, amount) {
      return this.minerals[mineral] += amount;
    };
  };

  Game = function() {
    this.isOver = false;
    this.numPlayers = 0;
    this.asteroid = new Asteroid();
    this.players = {
      player1: new Player(),
      player2: new Player(),
      player3: new Player(),
      player4: new Player()
    };
    this.update = function(playerId, drillPower) {
      var amount, i, mineral, minerals;
      if (this.asteroid.isEmpty()) {
        return this.isOver = true;
      } else {
        minerals = game.asteroid.presentMinerals();
        mineral = minerals[randomInt(minerals.length - 1)];
        amount = drillPower * 10;
        i = 0;
        while (isCommon(mineral) && i < 2) {
          mineral = minerals[randomInt(minerals.length - 1)];
          i++;
        }
        i = 0;
        while (isScarce(mineral) && i < 3) {
          mineral = minerals[randomInt(minerals.length - 1)];
          i++;
        }
        if (game.asteroid.minerals[mineral] < amount) {
          amount = game.asteroid.minerals[mineral];
        }
        game.asteroid.loseMineral(mineral, amount);
        return game.players[playerId].findMineral(mineral, amount);
      }
    };
  };

  game = new Game();

  express = require("express");

  app = require("express")();

  server = require("http").createServer(app);

  io = require("socket.io").listen(server);

  app.use('/assets', express["static"](__dirname + '/assets'));

  server.listen(8000);

  app.get("/", function(req, res) {
    res.sendfile(__dirname + "/index.html");
  });

  io.sockets.on("connection", function(socket) {
    socket.on('start', function(data) {
      console.log("START");
      initGame();
      return socket.emit('updateGame', game);
    });
    socket.on('clientRegistered', function(data) {
      console.log("CLIENT REGISTERED ==> ", data);
      return socket.emit('updateGame', game);
    });
    socket.on('drill', function(data) {
      var drillPower, playerId;
      console.log("DRILL!");
      console.log(data);
      if (data) {
        playerId = data["playerID"];
        drillPower = parseInt(data["drillPower"]);
        if (playerId && drillPower) {
          game.update(playerId, drillPower);
          socket.emit('updateGame', game);
          return console.log("=====> ", JSON.stringify(game));
        }
      }
    });
    socket.on('time-up', function(data) {
      game.isOver = true;
      return socket.emit('update-game', game);
    });
  });

  initGame = function() {
    return game = new Game();
  };

  isScarce = function(mineral) {
    return SCARCE_MINERALS.indexOf(mineral) > -1;
  };

  isCommon = function(mineral) {
    return COMMON_MINERALS.indexOf(mineral) > -1;
  };

  isAbundant = function(mineral) {
    return ABUNDANT_MINERALS.indexOf(mineral) > -1;
  };

  randomInt = function(max) {
    return Math.floor(Math.random() * (max + 1));
  };

}).call(this);
