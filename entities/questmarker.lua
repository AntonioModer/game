local marker = class{name = 'QuestMarker', inherits = Entity.BaseEntity,
	function (self, pos, radius)
		Entity.BaseEntity.construct(self, pos:clone(), vector(128,128))
		--self.visual = Image.victim

		self.physics.shape = love.physics.newCircleShape(radius or 64)
	end
}

function marker:registerPhysics(...)
	Entity.BaseEntity.registerPhysics(self, ...)
	self.physics.fixture:setSensor(true)
end

function marker:beginContact(other)
	if other ~= State.game.player then return end
	self.playerInRange = true
	local t = 0
	self.countown_timer = Timer.do_for(2, function(dt)
		t = t + dt
		Signal.emit('victim-pickup-timer', t / 2)
	end, function()
		if self.playerInRange then
			Signal.emit('victim-picked-up')
		end
	end)
end

function marker:endContact(other)
	if other ~= State.game.player then return end
	self.playerInRange = false
	Timer.cancel(self.countown_timer)
	Signal.emit('victim-pickup-abort')
end

return marker
