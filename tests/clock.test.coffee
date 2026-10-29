{ test } = require 'node:test'
assert = require 'node:assert/strict'
{
  getTimeComponents
  formatTime
  timeHue
  shouldExplode
  clockGeometry
  createExplosionParticles
  advanceParticle
} = require '../src/clock.coffee'

test 'time includes fractional progress for smooth hands', ->
  date = new Date(2026, 0, 1, 13, 30, 15, 500)
  time = getTimeComponents(date)
  assert.equal time.hours, 13
  assert.equal time.minutes, 30
  assert.equal time.seconds, 15
  assert.equal time.smoothSeconds, 15.5
  assert.ok time.smoothMinutes > 30
  assert.ok time.smoothHours > 1
  assert.equal formatTime(date), '13:30'

test 'minute boundary triggers exactly once, not on initial frame', ->
  assert.equal shouldExplode(null, 5), false
  assert.equal shouldExplode(5, 5), false
  assert.equal shouldExplode(5, 6), true
  assert.equal shouldExplode(6, 6), false

test 'hue follows the time of day', ->
  assert.equal timeHue(0, 0), 0
  assert.equal timeHue(12, 0), 180
  assert.ok timeHue(23, 59) < 360

test 'clock fits desktop and mobile viewports', ->
  mobile = clockGeometry(320, 640)
  desktop = clockGeometry(1920, 1080)
  assert.ok mobile.radius * 1.15 < 160
  assert.ok desktop.radius <= 214
  assert.equal mobile.x, 160
  assert.equal desktop.y, 540

test 'particles are reproducible and use elapsed time', ->
  particles = createExplosionParticles(50, 100, 20, 180, -> 0.5)
  assert.equal particles.length, 60
  particle = particles[0]
  next = advanceParticle(particle, 250)
  assert.equal next.age, 250
  assert.equal next.x, particle.x + particle.vx * 0.25
  assert.equal next.y, particle.y + particle.vy * 0.25
  assert.equal particle.age, 0
