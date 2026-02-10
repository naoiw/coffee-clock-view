# ======================================
# Canvas Time Art with Exploding Seconds
# ======================================

canvas = document.getElementById "c"
ctx = canvas.getContext "2d"

resize = ->
  canvas.width  = window.innerWidth
  canvas.height = window.innerHeight

window.addEventListener "resize", resize
resize()

TAU = Math.PI * 2
center =
  x: canvas.width / 2
  y: canvas.height / 2

# ----------------------------
# 背景フェード
# ----------------------------
fade = (strong = false) ->
  alpha = if strong then 0.6 else 0.25
  ctx.fillStyle = "rgba(14,14,17,#{alpha})"
  ctx.fillRect 0, 0, canvas.width, canvas.height

# ----------------------------
# 秒粒子（うねる）
# ----------------------------
class SecondParticle
  constructor: ->
    @angle = Math.random() * TAU
    @radius = 120
    @phase = Math.random() * TAU
    @speed = 0.015 + Math.random() * 0.01
    @pos = {x: 0, y: 0}
    @vel = {x: 0, y: 0}

  update: ->
    @phase += 0.05
    wobble = Math.sin(@phase) * 20

    prev = {x: @pos.x, y: @pos.y}

    @angle += @speed
    r = @radius + wobble

    @pos.x = center.x + Math.cos(@angle) * r
    @pos.y = center.y + Math.sin(@angle) * r

    @vel.x = @pos.x - prev.x
    @vel.y = @pos.y - prev.y

  draw: ->
    ctx.fillStyle = "#eaeaf0"
    ctx.beginPath()
    ctx.arc @pos.x, @pos.y, 2, 0, TAU
    ctx.fill()

  explode: ->
    fragments = []
    for i in [0...20]
      fragments.push new Fragment @pos, @vel
    fragments

# ----------------------------
# 破裂粒子
# ----------------------------
class Fragment
  constructor: (pos, baseVel) ->
    angle = Math.random() * TAU
    speed = Math.random() * 4 + 2

    @x = pos.x
    @y = pos.y

    @vx = baseVel.x * 0.5 + Math.cos(angle) * speed
    @vy = baseVel.y * 0.5 + Math.sin(angle) * speed

    @life = 60

  update: ->
    @x += @vx
    @y += @vy
    @vx *= 0.98
    @vy *= 0.98
    @life--

  draw: ->
    ctx.fillStyle = "rgba(234,234,240,0.8)"
    ctx.fillRect @x, @y, 2, 2

# ----------------------------
# 管理
# ----------------------------
secondParticles = []
fragments = []

spawnSecondParticles = ->
  secondParticles = []
  for i in [0...60]
    secondParticles.push new SecondParticle()

spawnSecondParticles()

lastSecond = null

# ----------------------------
# ループ
# ----------------------------
tick = ->
  now = new Date()
  sec = now.getSeconds()

  exploding = fragments.length > 0
  fade exploding

  # 秒が変わった瞬間
  if sec isnt lastSecond
    # 00秒で破裂
    if sec is 0
      for p in secondParticles
        fragments.push ...p.explode()
      secondParticles = []
    else
      spawnSecondParticles()

    lastSecond = sec

  # 通常秒粒子
  for p in secondParticles
    p.update()
    p.draw()

  # 破裂粒子
  fragments = fragments.filter (f) ->
    f.update()
    f.draw()
    f.life > 0

  requestAnimationFrame tick

tick()
