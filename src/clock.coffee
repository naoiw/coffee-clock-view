# ======================================
# Canvas Time Art with Exploding Seconds
# ======================================

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"

# ---- Resize ----
resize = ->
  canvas.width  = window.innerWidth
  canvas.height = window.innerHeight

window.addEventListener "resize", resize
resize()

center =
  x: -> canvas.width / 2
  y: -> canvas.height / 2

TAU = Math.PI * 2

# ---- 時刻由来の色 ----
timeColor = (h, m) ->
  hue = (h * 30 + m * 0.5) % 360
  "hsl(#{hue}, 80%, 60%)"

# ---- 背景フェード（残像用）----
fade = ->
  ctx.fillStyle = "rgba(14,14,17,0.25)"
  ctx.fillRect 0, 0, canvas.width, canvas.height

# ---- 円リング描画 ----
drawRing = (radius, ratio, color, width) ->
  ctx.beginPath()
  ctx.arc center.x(), center.y(),
    radius,
    -Math.PI / 2,
    TAU * ratio - Math.PI / 2
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.lineCap = "round"
  ctx.stroke()

# =========================
# 秒粒子（破裂用）
# =========================

class Particle
  constructor: (@x, @y, angle, @color) ->
    speed = 2 + Math.random() * 4
    spread = (Math.random() - 0.5) * 0.4
    a = angle + spread
    @vx = Math.cos(a) * speed
    @vy = Math.sin(a) * speed
    @life = 60

  update: ->
    @x += @vx
    @y += @vy
    @life--

  draw: ->
    alpha = @life / 60
    ctx.fillStyle = @color.replace(")", ", #{alpha})").replace("hsl", "hsla")
    ctx.beginPath()
    ctx.arc @x, @y, 2.5, 0, TAU
    ctx.fill()

  alive: ->
    @life > 0

particles = []
lastSec = null

# ---- 現在秒の粒子（通常表示）----
drawSecondDots = (sec) ->
  count = Math.floor sec
  for i in [0...count]
    angle = TAU * i / 60 - Math.PI / 2
    r = 220
    x = center.x() + Math.cos(angle) * r
    y = center.y() + Math.sin(angle) * r
    ctx.fillStyle = "rgba(255,255,255,0.6)"
    ctx.beginPath()
    ctx.arc x, y, 2, 0, TAU
    ctx.fill()

# ---- 00秒で破裂 ----
explodeSeconds = (color) ->
  for i in [0...60]
    angle = TAU * i / 60 - Math.PI / 2
    r = 220
    x = center.x() + Math.cos(angle) * r
    y = center.y() + Math.sin(angle) * r
    particles.push new Particle x, y, angle, color

# =========================
# メインループ
# =========================

draw = ->
  fade()

  now = new Date()
  h = now.getHours() % 12
  m = now.getMinutes()
  s = now.getSeconds() + now.getMilliseconds() / 1000

  baseColor = timeColor h, m

  # ---- リング ----
  drawRing 120, h / 12, baseColor, 10
  drawRing 160, m / 60, "rgba(255,255,255,0.7)", 6
  drawRing 200, s / 60, "rgba(255,255,255,0.4)", 3

  currentSec = Math.floor s

  # ---- 00秒検出 → 破裂 ----
  if lastSec? and lastSec isnt currentSec and currentSec is 0
    explodeSeconds baseColor

  # ---- 秒粒子（通常）----
  drawSecondDots s unless currentSec is 0

  # ---- 破裂粒子 ----
  for p in particles
    p.update()
    p.draw()

  particles = particles.filter (p) -> p.alive()

  lastSec = currentSec
  requestAnimationFrame draw

# ---- Start ----
draw()
