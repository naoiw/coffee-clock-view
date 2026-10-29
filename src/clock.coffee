# Coffee Clock — CoffeeScript application logic and Canvas rendering.
TAU = Math.PI * 2
BACKGROUND = '#0b0f18'
PARTICLE_COUNT = 60

# Pure time calculations: a Date is passed in for deterministic tests.
getTimeComponents = (date) ->
  hours = date.getHours()
  minutes = date.getMinutes()
  seconds = date.getSeconds()
  smoothSeconds = seconds + date.getMilliseconds() / 1000
  smoothMinutes = minutes + smoothSeconds / 60
  smoothHours = hours % 12 + smoothMinutes / 60
  { hours, minutes, seconds, smoothSeconds, smoothMinutes, smoothHours, minuteKey: Math.floor(date.getTime() / 60000) }

formatTime = (date) ->
  pad = (n) -> String(n).padStart(2, '0')
  "#{pad(date.getHours())}:#{pad(date.getMinutes())}"

formatDate = (date) ->
  date.toLocaleDateString('ja-JP',
    year: 'numeric'
    month: 'long'
    day: 'numeric'
    weekday: 'long'
  )

timeHue = (hours, minutes) ->
  (hours * 60 + minutes) / 1440 * 360

shouldExplode = (previousMinute, currentMinute) ->
  previousMinute? and previousMinute isnt currentMinute

# Geometry is measured in CSS pixels, not Canvas backing-store pixels.
clockGeometry = (width, height) ->
  x: width / 2
  y: height / 2
  radius: Math.min(width * 0.42, height * 0.34, 214)

createExplosionParticles = (cx, cy, radius, hue, random = Math.random) ->
  for i in [0...PARTICLE_COUNT]
    angle = TAU * i / PARTICLE_COUNT - Math.PI / 2
    angle += (random() - 0.5) * 0.28
    speed = 55 + random() * 115
    {
      x: cx + Math.cos(angle) * radius
      y: cy + Math.sin(angle) * radius
      vx: Math.cos(angle) * speed
      vy: Math.sin(angle) * speed
      hue
      age: 0
      life: 650 + random() * 550
    }

advanceParticle = (particle, elapsedMs) ->
  dt = elapsedMs / 1000
  {
    ...particle
    x: particle.x + particle.vx * dt
    y: particle.y + particle.vy * dt
    age: particle.age + elapsedMs
  }

# The functions below have Canvas/DOM side effects.
resizeCanvas = (canvas, ctx) ->
  width = window.innerWidth
  height = window.innerHeight
  pixelRatio = Math.min(window.devicePixelRatio or 1, 2)
  canvas.style.width = "#{width}px"
  canvas.style.height = "#{height}px"
  canvas.width = Math.max(1, Math.round(width * pixelRatio))
  canvas.height = Math.max(1, Math.round(height * pixelRatio))
  ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0)
  ctx.fillStyle = BACKGROUND
  ctx.fillRect(0, 0, width, height)
  { width, height }

drawRing = (ctx, x, y, radius, ratio, color, lineWidth) ->
  return unless ratio > 0
  ctx.beginPath()
  ctx.arc(x, y, radius, -Math.PI / 2, TAU * ratio - Math.PI / 2)
  ctx.strokeStyle = color
  ctx.lineWidth = lineWidth
  ctx.lineCap = 'round'
  ctx.stroke()

drawFace = (ctx, viewport, geometry, time, hue, reducedMotion) ->
  { width, height } = viewport
  { x, y, radius } = geometry
  ctx.fillStyle = if reducedMotion then BACKGROUND else 'rgba(11, 15, 24, 0.28)'
  ctx.fillRect(0, 0, width, height)

  hourRadius = radius * 0.65
  minuteRadius = radius * 0.83
  secondRadius = radius

  for r in [hourRadius, minuteRadius, secondRadius]
    drawRing(ctx, x, y, r, 1, 'rgba(235, 240, 255, 0.085)', Math.max(2, radius * 0.016))

  hourProgress = time.smoothHours / 12
  minuteProgress = time.smoothMinutes / 60
  secondProgress = if reducedMotion then time.seconds / 60 else time.smoothSeconds / 60

  drawRing(ctx, x, y, hourRadius, hourProgress, "hsl(#{hue}, 86%, 68%)", Math.max(5, radius * 0.040))
  drawRing(ctx, x, y, minuteRadius, minuteProgress, 'rgba(229, 237, 250, 0.88)', Math.max(4, radius * 0.027))
  drawRing(ctx, x, y, secondRadius, secondProgress, 'rgba(158, 188, 220, 0.78)', Math.max(2, radius * 0.014))

  for i in [0...time.seconds]
    angle = TAU * i / 60 - Math.PI / 2
    ctx.beginPath()
    ctx.arc(x + Math.cos(angle) * radius * 1.11, y + Math.sin(angle) * radius * 1.11, Math.max(1, radius * 0.009), 0, TAU)
    ctx.fillStyle = 'rgba(219, 232, 250, 0.65)'
    ctx.fill()

drawParticle = (ctx, particle, radius) ->
  opacity = Math.max(0, 1 - particle.age / particle.life)
  ctx.fillStyle = "hsla(#{particle.hue}, 88%, 72%, #{opacity})"
  ctx.beginPath()
  ctx.arc(particle.x, particle.y, Math.max(1.5, radius * 0.012), 0, TAU)
  ctx.fill()

renderFrame = (ctx, viewport, state, date, elapsedMs, reducedMotion) ->
  time = getTimeComponents(date)
  geometry = clockGeometry(viewport.width, viewport.height)
  hue = timeHue(time.hours, time.minutes)

  drawFace(ctx, viewport, geometry, time, hue, reducedMotion)
  particles = if reducedMotion then [] else state.particles
  if shouldExplode(state.lastMinute, time.minuteKey) and not reducedMotion
    particles = particles.concat createExplosionParticles(geometry.x, geometry.y, geometry.radius * 1.11, hue)

  particles = (advanceParticle(p, elapsedMs) for p in particles)
  particles = particles.filter (p) -> p.age < p.life
  for particle in particles
    drawParticle(ctx, particle, geometry.radius)

  { lastMinute: time.minuteKey, particles }

run = ->
  canvas = document.getElementById('clock-canvas')
  return unless canvas?
  ctx = canvas.getContext('2d')
  return unless ctx?

  timeElement = document.getElementById('digital-time')
  dateElement = document.getElementById('date-text')
  reducedMotion = false
  if window.matchMedia?
    reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

  viewport = resizeCanvas(canvas, ctx)
  state = { lastMinute: null, particles: [] }
  lastFrame = null
  frameId = null

  updateLabels = (date) ->
    timeText = formatTime(date)
    dateText = formatDate(date)
    timeElement.textContent = timeText if timeElement? and timeElement.textContent isnt timeText
    dateElement.textContent = dateText if dateElement? and dateElement.textContent isnt dateText

  animate = (timestamp) ->
    elapsedMs = if lastFrame? then Math.min(50, Math.max(0, timestamp - lastFrame)) else 16
    lastFrame = timestamp
    date = new Date()
    updateLabels(date)
    state = renderFrame(ctx, viewport, state, date, elapsedMs, reducedMotion)
    frameId = window.requestAnimationFrame(animate)

  window.addEventListener 'resize', ->
    viewport = resizeCanvas(canvas, ctx)
    state.particles = []

  document.addEventListener 'visibilitychange', ->
    if document.hidden
      window.cancelAnimationFrame(frameId) if frameId?
      frameId = null
      lastFrame = null
    else unless frameId?
      frameId = window.requestAnimationFrame(animate)

  frameId = window.requestAnimationFrame(animate)

# Node-based tests can import pure functions without running a browser.
if typeof module isnt 'undefined' and module.exports?
  module.exports = {
    getTimeComponents
    formatTime
    timeHue
    shouldExplode
    clockGeometry
    createExplosionParticles
    advanceParticle
  }
else if typeof document isnt 'undefined'
  run()
