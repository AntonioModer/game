local car = class{name = "Car", inherits = Entity.BaseEntity,
	function (self, pos, angle, name)
		Entity.BaseEntity.construct (self, pos, vector(48, 22))
		self.visual = Image.carbig
		self.name = name
		self.angle = 0
		self.shape_offset = vector(9,0)
		self.targetPos = pos
		self.speed = 150
		self.state = 'drive'
		self.lastStateUpdate = love.timer.getMicroTime()
		self.mass = 1
		
		self.physics.shape = love.physics.newPolygonShape(
			-24 + 10,  8,
			-21 + 10,  11,
			 21 + 10,  11,
			 24 + 10,  8,
			 24 + 10, -8,
			 21 + 10, -11,
			-21 + 10, -11,
			-24 + 10, -8
		)
		self.direction = 'south'
		self.hitList = {}
		self.debug = false
	end
}

-- get collision lines
function car:getCollisionLines() 
	local lines = {}
	
	local headingSize = 45
	local headingAngle = 3.14159 / 36 * 2 -- 10°

	local headingLeft = self.pos + headingSize * vector (math.cos(self.angle - headingAngle), math.sin(self.angle - headingAngle))
	local headingRight = self.pos + headingSize * vector (math.cos(self.angle + headingAngle), math.sin(self.angle + headingAngle))

	table.insert(lines, {x1 = self.pos.x, y1 = self.pos.y, x2 = headingLeft.x, y2 = headingLeft.y })
	table.insert(lines, {x1 = self.pos.x, y1 = self.pos.y, x2 = headingRight.x, y2 = headingRight.y })
	table.insert(lines, {x1 = headingLeft.x, y1 = headingLeft.y, x2 = headingRight.x, y2 = headingRight.y })
	return lines
end

-- Add collition hit to own hit list
function car:collisionHitCallback(fixture, x, y, xn, yn, fraction)
	local hit = {}
	hit.fixture = fixture
	hit.x, hit.y = x, y
	hit.xn, hit.yn = xn, yn
	hit.fraction = fraction

	table.insert(self.hitList, hit)
	return 1 -- Continues with ray cast through all shapes.
end

-- detect any collision
function car:detectCollision()
	if self.state == 'reverse' then
		return
	end

	local lines = self:getCollisionLines()
	for i = 1,#lines do
		State.game.world:rayCast(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2, function (fixture, x, y, xn, yn, fraction)
			return self:collisionHitCallback(fixture, x, y, xn, yn, fraction)
		end )
	end
end

function car:setState(state)
	if self.state ~= state then
		self:log("Change state from " .. self.state .. " to " .. state)
		self.state = state
		self.lastStateUpdate = love.timer.getMicroTime()
	end
end

function car:updateStateMachine()
	if self.state == 'drive' then
		if #self.hitList > 0 then
			self:setState('pause')
		end
	elseif self.state == 'pause' then
		if #self.hitList == 0 then
			self:setState('drive')
		else 
			self:setState('reverse')
		end
	elseif self.state == 'reverse' then
		local now = love.timer.getMicroTime()
		if #self.hitList == 0 and now - self.lastStateUpdate > 3 then
			self:setState('pause')
		end
	end
end

-- Return angle between two points
function car:getAngle(p1, p2)
	local d = p2 - p1
	
	local angle = math.atan2(d.y, d.x)
	if angle < 0 then
		angle = angle + 2 * math.pi
	end
	return angle
end

function car:updatePosition(dt, angle) 
	local heading = vector (math.cos(angle), math.sin(angle))
	local angleD = angle - self.angle
	if (angleD > math.pi) then
		angleD = angleD - 2 * math.pi
	end
	--self:log("self:angle="..self.angle.." angle="..angle)
	
	if self.state == 'drive' then
		self.velocity = heading * self.speed
		self.pos = self.pos + dt * self.velocity
		self.angle_velocity = 0.2 * angleD / dt
	elseif self.state == 'pause' then
		self.velocity = self.velocity * 0.7
	elseif self.state == 'reverse' then
		self.velocity = heading * self.speed * 0.4
		self.pos = self.pos - dt * self.velocity
		self.angle_velocity = 0.2
	end
end

function car:targetVector()
	if self.direction == 'east' then
		return vector(1, 0)
	elseif self.direction == 'west' then
		return vector(-1, 0)
	elseif self.direction == 'south' then
		return vector(0, 1)
	else
		return vector(0, -1)
	end
end

function car:canDriveAhead(map, pos, v)
	local rV = v:rotated(math.pi / 2)
	
	local ahead = pos + v
	local right = pos + rV
	-- self:log("pos=" .. pos.x .. ","..pos.y.." v=" .. v.x .. ","..v.y.." ahead="..ahead.x..","..ahead.y.." right="..right.x..","..right.y)
	-- self:log("isStreet ahead " .. tostring(map:isStreet(ahead.x, ahead.y)) .. "right ahead " .. tostring(map:isStreet(right.x, right.y)))
	
	-- normal stret
	if map:isStreet(ahead.x, ahead.y) and not map:isStreet(right.x, right.y) then
		self:log("Hit ahead!")
		return true
	end
	return false
end

function car:needTrackChange(map, pos, v)
	local rV = v:rotated(math.pi / 2)

	local ahead = pos + v + rV
	local right = pos + 4 * rV
	if map:isStreet(ahead.x, ahead.y) and not map:isStreet(right.x, right.y) then
		self:log("Change track")
		return true
	end
	return false
end

function car:getLeftDirection()
	if self.direction == 'north' then
		return 'west'
	elseif self.direction == 'west' then
		return 'south'
	elseif self.direction == 'south' then
		return 'east'
	else
		return 'north'
	end
end

function car:getRightDirection()
	if self.direction == 'north' then
		return 'east'
	elseif self.direction == 'east' then
		return 'south'
	elseif self.direction == 'south' then
		return 'west'
	else
		return 'north'
	end
end

function car:findNextTarget(map, pos, v)
	local lV = v:rotated(- math.pi / 2)
	local rV = v:rotated(math.pi / 2)

	local ahead = pos + v
	local ahead4 = pos + 5 * v
	local right = pos + rV
	local right4 = pos + 5 * rV
	local left = pos + lV
	local left4 = pos + 5 * lV

	local changes = {}
	if map:isStreet(ahead.x, ahead.y) and map:isStreet(ahead4.x, ahead4.y) then
		self:log("Find next target: Can drive ahead")
		table.insert(changes, {name = 'ahead', target = ahead, direction = self.direction})
	end
	if map:isStreet(right.x, right.y) and map:isStreet(right4.x, right4.y) then
		self:log("Find next target: Can turn right")
		table.insert(changes, {name = 'right', target = right, direction = self:getRightDirection(self.direction)})
	end
	if map:isStreet(left.x, left.y) and map:isStreet(left4.x, left4.y) then
		self:log("Find next target: Can turn left")
		table.insert(changes, {name = 'left', target = left, direction = self:getLeftDirection(self.direction)})
	end
	if #changes == 0 then
		if map:isStreet(ahead4.x, ahead4.y) then
			self:log("Find next target: Faild but street ahead")
			return map:mapCoordsCenter(ahead4.x, ahead4.y)
		elseif map:isStreet(right4.x, right4.y) then
			self:log("Find next target: Faild but street right")
			return map:mapCoordsCenter(right4.x, right4.y)
		elseif map:isStreet(left4.x, left4.y) then
			self:log("Find next target: Faild but street left")
			return map:mapCoordsCenter(left4.x, left4.y)
		else 
			self:log("Find next target: Must return")
			self.direction = self:getLeftDirection(self:getLeftDirection(self.direction))
			local reverse = pos - v
			return map:mapCoordsCenter(reverse.x, reverse.y)
		end
	end
	local i = math.floor(math.random(0, #changes - 1)) + 1
	--self:log("length " .. #changes .. " i " .. i)
	if changes[i].direction ~= self.direction then
		self:log("Change direction from " .. self.direction .. " to " .. changes[i].direction)
		self.direction = changes[i].direction
	end
	return map:mapCoordsCenter(changes[i].target.x, changes[i].target.y)
end

-- Returns new direction. One of north, east, south, west, 
-- north-east, north-west, south-east, south-west directions
function car:getTargetPosition()
	local map = State.game.map
	local x, y = map:tileCoords(self.pos.x, self.pos.y)
	
	if self.state ~= 'drive' then
		self.targetPos = self.pos
		return self.pos
	end
	-- Check if we are in the target. If not we continue
	local targetX, targetY = map:tileCoords(self.targetPos.x, self.targetPos.y)
	if x ~= targetX or y ~= targetY then
		return self.targetPos
	end

	local pos = vector(x, y)
	local v = self:targetVector()

	if self:canDriveAhead(map, pos, v) then
		local ahead = pos + v
		return map:mapCoordsCenter(ahead.x, ahead.y)
	elseif self:needTrackChange(map, pos, v) then
		local ahead = pos + v + v:rotated(math.pi / 2)
		return map:mapCoordsCenter(ahead.x, ahead.y)
	else
		return self:findNextTarget(map, pos, v)
	end
end

function car:update(dt)
	self.hitList = {}
	self:updateFromPhysics()
	-- behavior
	self:detectCollision()
	self:updateStateMachine()
	self.targetPos = self:getTargetPosition()
	local angle = self:getAngle(self.pos, self.targetPos)
	--self:log("Target position is " .. self.targetPos.x .. ", " .. self.targetPos.y .. " with angle " .. angle)
	self:updatePosition(dt, angle)

	self:updateToPhysics()
end

function car:draw()
	Entity.BaseEntity.draw(self)

	if self.debug then
		local lines = self:getCollisionLines()
		for i = 1,#lines do
			love.graphics.line(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2)
		end	

		local crossSize = 5
		for i = 1,#self.hitList do
			local hit = self.hitList[i]
			love.graphics.line(hit.x-crossSize, hit.y-crossSize, hit.x+crossSize, hit.y+crossSize)
			love.graphics.line(hit.x-crossSize, hit.y+crossSize, hit.x+crossSize, hit.y-crossSize)
		end
		love.graphics.line(self.pos.x, self.pos.y, self.targetPos.x, self.targetPos.y)

		local heading = vector (math.cos(self.angle), math.sin(self.angle))
		local d = self.pos + 60 * heading
		love.graphics.line(self.pos.x, self.pos.y, d.x, d.y)
	end
end

function car:log(msg)
	if self.debug then
		local now = love.timer.getMicroTime()
		print(now .. " " .. self.name .. ": " .. msg)
	end
end

return car