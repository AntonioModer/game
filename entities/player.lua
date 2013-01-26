local player = class{name = "Player", inherits = Entity.BaseEntity,
	function (self, pos)
		Entity.BaseEntity.construct (self, pos, vector(32, 16))
		self.visual = Image.ambulance
		self.mass = 1
	end
}

function player:update(dt)
	self:updateFromPhysics()

	local heading = vector (math.cos(self.angle), math.sin(self.angle))

	self.velocity = vector (0, 0)

	if Input.isDown('up') then
		self.velocity = heading * 128
	elseif Input.isDown('down') then
		self.velocity = heading * -16
	end

	self.angle_velocity = 0

	if Input.isDown('left') then
		self.angle_velocity = -5
	elseif Input.isDown('right') then
		self.angle_velocity = 5
	end

	self:updateToPhysics()
end

function player:beginContact (other, coll)
end

function player:endContact (other, coll)
end


return player
