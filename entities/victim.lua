local victim = class{name = 'Victim',
	function (self, pos)
		local img = Image.pedestriandead
		self.ox = img:getWidth()/2
		self.oy = img:getHeight()/2
		self.pos = pos:clone()
		self.rot = math.random(0,2*math.pi)
		self.color = {255, 255, 255, 255}

		self.heartrate = 100
		self.heartrate_delta = (math.abs(self.pos.x - State.game.player.pos.x)
			+ math.abs(self.pos.y - State.game.player.pos.y)
--			+ math.abs (self.pos.x - State.game.map.rescue_zone.x)
--			+ math.abs(self.pos.y - State.game.map.rescue_zone.y))
			)/ 400

		self.is_stabilized = false
		Entities.add(self)
	end
}

function victim:init_heartrate_delta()
	print ("innit heart rate")
		self.heartrate_delta = (math.abs(self.pos.x - State.game.player.pos.x)
			+ math.abs(self.pos.y - State.game.player.pos.y)
--			+ math.abs (self.pos.x - State.game.map.rescue_zone.x)
--			+ math.abs(self.pos.y - State.game.map.rescue_zone.y))
			)/ 400

end

function victim:draw()
	if not self.is_stabilized then
		love.graphics.draw(Image.pedestriandead_blood, self.pos.x, self.pos.y, self.rot, 1,1, self.ox, self.oy)

		old_color = {love.graphics.getColor() }
		love.graphics.setColor (self.color)
		love.graphics.draw(Image.pedestriandead_body, self.pos.x, self.pos.y, self.rot, 1,1, self.ox, self.oy)
		love.graphics.setColor(old_color)
	end
end

function victim:update(dt)
	if not self.is_stabilized then
		self.heartrate = self.heartrate - self.heartrate_delta * dt -- 15 seconds to flatline
		if self.heartrate <= 0 then
			Entities.remove(self)
			State.game.victims[self] = nil
			if State.game.current_target == self then
				Signal.emit('game-over', 'victim was not rescued')
			end
		end
	else
		-- FIXME: heartrate modification according to driving style
		self.heartrate = self.heartrate - self.heartrate_delta * dt -- 20 seconds to flatline
		if self.heartrate <= 0 or self.heartrate > 150 and State.game.current_target == self then
			Signal.emit('game-over', 'victim died in car')
		end
	end
end

function victim:stabilize()
	self.is_stabilized = true
	self.heartrate = 80
end

return victim
