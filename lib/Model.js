.pragma library

var DEFAULT_ACCEL_PROFILE = "adaptive"
var DEFAULT_SENSITIVITY = 0
var DEFAULT_SCROLL_FACTOR = 1

// Omarchy's input.lua opens with one uncommented hl.config({ input = {...} })
// block, followed by a large commented-out block showing the same keys as
// examples. Matching only the first (non-greedy) block keeps us from ever
// reading or writing the commented-out copy.
var BLOCK_RE = /hl\.config\(\{[\s\S]*?\}\)/

function parseInput(text) {
  var match = BLOCK_RE.exec(String(text || ""))
  var block = match ? match[0] : ""

  var accelMatch = /accel_profile\s*=\s*"([^"]+)"/.exec(block)
  var sensMatch = /sensitivity\s*=\s*(-?[0-9.]+)/.exec(block)
  var scrollMatch = /scroll_factor\s*=\s*([0-9.]+)/.exec(block)

  return {
    accelProfile: accelMatch ? accelMatch[1] : DEFAULT_ACCEL_PROFILE,
    sensitivity: sensMatch ? parseFloat(sensMatch[1]) : DEFAULT_SENSITIVITY,
    scrollFactor: scrollMatch ? parseFloat(scrollMatch[1]) : DEFAULT_SCROLL_FACTOR
  }
}

function setScalar(block, key, formattedValue, pattern) {
  if (pattern.test(block)) {
    return block.replace(pattern, "$1" + formattedValue)
  }
  return block.replace(/(input\s*=\s*\{)/, "$1\n    " + key + " = " + formattedValue + ",")
}

// Returns null if input.lua has no hl.config block to edit — the caller
// decides how to surface that rather than this function silently no-oping.
function buildInput(text, accelProfile, sensitivity, scrollFactor) {
  var source = String(text || "")
  var match = BLOCK_RE.exec(source)
  if (!match) return null

  var block = match[0]

  if (/accel_profile\s*=\s*"[^"]+"/.test(block)) {
    block = block.replace(/accel_profile\s*=\s*"[^"]+"/, 'accel_profile = "' + accelProfile + '"')
  } else {
    block = block.replace(/(input\s*=\s*\{)/, '$1\n    accel_profile = "' + accelProfile + '",')
  }

  block = setScalar(block, "sensitivity", sensitivity.toFixed(2), /(sensitivity\s*=\s*)-?[0-9.]+/)
  block = setScalar(block, "scroll_factor", scrollFactor.toFixed(2), /(scroll_factor\s*=\s*)[0-9.]+/)

  return source.slice(0, match.index) + block + source.slice(match.index + match[0].length)
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}
