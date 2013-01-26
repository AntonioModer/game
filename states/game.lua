local st = GS.new()

st.world = {}

function st:resetWorld()
	st.world = love.physics.newWorld()
	print ("resetting world")
end

function st:addObstacle(pos, dimensions)
	local obstacle = Entity.obstacle (pos, dimensions)
	obstacle:registerPhysics (self.world, 0.)
end

function st:init()
	print ("State.game.init()")
	self:resetWorld()

	self.player = Entity.player (vector(40, 100), vector(32, 32))
	self.player:registerPhysics (self.world, 1.)

        self.cars = {}
        for i = 1,30 do
            local pos = vector(math.random(0,SCREEN_WIDTH), math.random(0,SCREEN_HEIGHT)) 
            local car = Entity.car (pos, vector(32, 32))
            car.angle = math.random(0, 3.1415)
            table.insert(self.cars, car)
        end

	map, geometry = (require 'level-loader')('map.png', require'tileinfo', require 'tiledata')
	cam = Camera()

	for rect in pairs(geometry) do
		self:addObstacle (vector(rect.x + rect.w * 0.5, rect.y + rect.h * 0.5), vector (rect.w, rect.h))
	end
end

function st:leave()
end

function st:draw()
	cam:attach()

	love.graphics.setFont(Font[30])
	love.graphics.printf("GAME", 0,SCREEN_HEIGHT/4-Font[30]:getLineHeight(),SCREEN_WIDTH, 'center')

	map:draw(cam)

	Entities.draw()

	cam:detach()
end

function st:update(dt)
	cam:lookAt(self.player.pos:unpack())
	if self.world then
		self.world:update(dt)
	end

	Entities.update(dt)
end

return st
