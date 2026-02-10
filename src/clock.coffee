# ============================
# Canvas Time Art (CoffeeScript)
# ============================

canvas = document.getElementById "canvas"
ctx = canvas.getContext "2d"

resize = ->
  canvas.width  = window.innerWidth
  canvas.height = window.innerHeight

window.addEventListener "resize", resize
resize()

center =
  x: -> canvas.width / 2
  y: -> canvas.height / 2

TAU = Math.PI * 2

# ---- 色生成（時間ベース） ----
timeColor = (h, m, s) ->
  hue = (h * 30 + m * 0.5) % 360
  "hsl(#{hue}, 80%, 60%)"

# ---- リング描画 ----
drawRing = (radius, ratio, color, width = 8) ->
  ctx.beginPath()
  ctx.arc center.x(), center.y(), radius, -Math.PI / 2, TAU * ratio - Math.PI / 2
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.lineCap = "round"
  ctx.stroke()

# ---- 秒の粒子 ----
drawParticles = (sec) ->
  count = sec
  for i in [0...count]
    angle = TAU * i / 60
    r = 220 + Math.sin(Date.now() / 300 + i) * 10
    x = center.x() + Math.cos(angle) * r
    y = center.y() + Math.sin(angle) * r
    ctx.fillStyle = "rgba(255,255,255,0.6)"
    ctx.beginPath()
    ctx.arc x, y, 2, 0, TAU
    ctx.fill()

# ---- 背景フェード ----
fade = ->
  ctx.fillStyle = "rgba(14,14,17,0.25)"
  ctx.fillRect 0, 0, canvas.width, canvas.height

# ---- メインループ ----
draw = ->
  fade()

  now = new Date()
  h = now.getHours() % 12
  m = now.getMinutes()
  s = now.getSeconds() + now.getMilliseconds() / 1000

  baseColor = timeColor h, m, s

  # 時リング
  drawRing 120, h / 12, baseColor, 10

  # 分リング
  drawRing 160, m / 60, "rgba(255,255,255,0.7)", 6

  # 秒リング
  drawRing 200, s / 60, "rgba(255,255,255,0.4)", 3

  # 秒の表現
  drawParticles Math.floor s

  requestAnimationFrame draw

# ---- 開始 ----
draw()
