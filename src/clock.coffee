# ======================================
# Canvas Time Art with Exploding Seconds
# ======================================

TAU = Math.PI * 2

# ---- 純粋: 時間成分の抽出 ----
getTimeComponents = (date) ->
  h: date.getHours() % 12
  m: date.getMinutes()
  s: date.getSeconds() + date.getMilliseconds() / 1000
  currentSec: Math.floor(date.getSeconds() + date.getMilliseconds() / 1000)

# ---- 純粋: 時刻由来の色 ----
timeColor = (h, m) ->
  hue = (h * 30 + m * 0.5) % 360
  "hsl(#{hue}, 80%, 60%)"

# ---- 純粋: 中心座標（canvas から算出）----
center = (canvas) ->
  x: -> canvas.width  / 2
  y: -> canvas.height / 2

# ---- 副作用: リサイズ ----
resize = (canvas) ->
  canvas.width  = window.innerWidth
  canvas.height = window.innerHeight

# ---- 副作用: 背景フェード ----
fade = (ctx, w, h) ->
  ctx.fillStyle = "rgba(14,14,17,0.25)"
  ctx.fillRect(0, 0, w, h)

# ---- 副作用: 円リング描画（引数で依存を明示）----
drawRing = (ctx, cx, cy, radius, ratio, color, width) ->
  ctx.beginPath()
  ctx.arc(cx, cy, radius, -Math.PI / 2, TAU * ratio - Math.PI / 2)
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.lineCap = "round"
  ctx.stroke()

# =========================
# 秒粒子（不変データ + 純粋関数）
# =========================

# 純粋: 1 粒子の生成
createParticle = (x, y, angle, color) ->
  speed = 2 + Math.random() * 4
  spread = (Math.random() - 0.5) * 0.4
  a = angle + spread
  { x, y, color, life: 60,
    vx: Math.cos(a) * speed
    vy: Math.sin(a) * speed }

# 純粋: 1 粒子の 1 フレーム更新（新オブジェクトを返す）
updateParticle = (p) ->
  { x: p.x + p.vx, y: p.y + p.vy, vx: p.vx, vy: p.vy, color: p.color, life: p.life - 1 }

# 純粋: 生存判定
isAlive = (p) -> p.life > 0

# 副作用: 1 粒子の描画
drawParticle = (ctx, p) ->
  alpha = p.life / 60
  fill = p.color.replace(")", ", #{alpha})").replace("hsl", "hsla")
  ctx.fillStyle = fill
  ctx.beginPath()
  ctx.arc(p.x, p.y, 2.5, 0, TAU)
  ctx.fill()

# 純粋: 00秒用の破裂粒子リストを生成（中心・色から）
createExplosionParticles = (cx, cy, color) ->
  (createParticle(
    cx + Math.cos(TAU * i / 60 - Math.PI / 2) * 220,
    cy + Math.sin(TAU * i / 60 - Math.PI / 2) * 220,
    TAU * i / 60 - Math.PI / 2,
    color
  ) for i in [0...60])

# ---- 副作用: 現在秒のドット描画 ----
drawSecondDots = (ctx, cx, cy, sec) ->
  count = Math.floor(sec)
  for i in [0...count]
    angle = TAU * i / 60 - Math.PI / 2
    r = 220
    x = cx + Math.cos(angle) * r
    y = cy + Math.sin(angle) * r
    ctx.fillStyle = "rgba(255,255,255,0.6)"
    ctx.beginPath()
    ctx.arc(x, y, 2, 0, TAU)
    ctx.fill()

# ---- 純粋: 00秒になったか（前の秒から 0 に変わったか）----
shouldExplode = (prevSec, currentSec) ->
  prevSec? and prevSec isnt currentSec and currentSec is 0

# =========================
# メイン: 1 フレーム（state を受け取り新しい state を返す）
# =========================
tick = (ctx, canvas, state) ->
  { lastSec, particles } = state
  c = center(canvas)
  cx = c.x()
  cy = c.y()

  fade(ctx, canvas.width, canvas.height)

  tc = getTimeComponents(new Date())
  { h, m, s, currentSec } = tc
  baseColor = timeColor(h, m)

  drawRing(ctx, cx, cy, 120, h / 12, baseColor, 10)
  drawRing(ctx, cx, cy, 160, m / 60, "rgba(255,255,255,0.7)", 6)
  drawRing(ctx, cx, cy, 200, s / 60, "rgba(255,255,255,0.4)", 3)

  nextParticles = if shouldExplode(lastSec, currentSec)
    particles.concat createExplosionParticles(cx, cy, baseColor)
  else
    particles

  drawSecondDots(ctx, cx, cy, s) unless currentSec is 0

  updated = (updateParticle(p) for p in nextParticles)
  updated.forEach((p) -> drawParticle(ctx, p))
  aliveParticles = updated.filter(isAlive)

  { lastSec: currentSec, particles: aliveParticles }

# ---- 初期化・ループ（状態は閉包で保持）----
run = ->
  canvas = document.getElementById("canvas")
  ctx = canvas.getContext("2d")

  window.addEventListener("resize", -> resize(canvas))
  resize(canvas)

  state = { lastSec: null, particles: [] }

  animate = ->
    state = tick(ctx, canvas, state)
    requestAnimationFrame(animate)

  animate()

run()
