function byFps(t, f)
  ftime = ftime + love.timer.getDelta()
  if ftime >= t then
    ftime = 0
    love.timer.step()
    f()
  end
end

function toRad(degree)
  return degree * 0.017453
end

function rotated(rad, f)
  love.graphics.push()
  love.graphics.rotate(rad)
  f()
  love.graphics.pop()
end

function drawRect(x, y, w, h)
  -- love.graphics.push()

  -- love.graphics.rotate(toRad(50))

  love.graphics.rectangle("line", x, y, w, h)

  -- x2 = x - love.graphics.getWidth()
  -- y2 = y - love.graphics.getHeight()

  -- if x2 < 0 or y2 < 0 then
  --   drawRect(x2, y2, w, h)
  -- end

  -- love.graphics.pop()
end

function love.load()
  x = 100
  rect_width = 200
  fps_time = 1 / 25.0
  ftime = 0

  rect_distance_x = (love.graphics.getWidth() / 3)
end

function love.draw()
  drawRect(x, 50, rect_width, 150)
end

function love.update()
  x = (x + rect_distance_x * love.timer.getDelta()) % love.graphics.getWidth()
end
