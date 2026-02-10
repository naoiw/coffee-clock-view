updateClock = ->
  now = new Date()
  timeStr = now.toLocaleString()
  document.getElementById("clock").textContent = timeStr

setInterval(updateClock, 1000)
updateClock()
