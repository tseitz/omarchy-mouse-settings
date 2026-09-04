"use strict"
const test = require("node:test")
const assert = require("node:assert/strict")
const { loadQmlJs } = require("./load.js")

const Model = loadQmlJs("lib/Model.js")

const SAMPLE_INPUT_LUA = [
  "-- Keep only your personal input overrides here.",
  "",
  "hl.config({",
  "  input = {",
  '    accel_profile = "flat",',
  "    sensitivity = -0.18,",
  "  },",
  "})",
  "",
  "-- Keyboard layout and options.",
  "-- hl.config({",
  "--   input = {",
  '--     accel_profile = "flat",',
  "--     sensitivity = 0.35,",
  "--   },",
  "-- })",
  ""
].join("\n")

test("parseInput reads the live block, not the commented example", () => {
  const parsed = Model.parseInput(SAMPLE_INPUT_LUA)
  assert.equal(parsed.accelProfile, "flat")
  assert.equal(parsed.sensitivity, -0.18)
  assert.equal(parsed.scrollFactor, 1)
})

test("parseInput falls back to defaults when there is no block", () => {
  const parsed = Model.parseInput("-- nothing here\n")
  assert.equal(parsed.accelProfile, "adaptive")
  assert.equal(parsed.sensitivity, 0)
  assert.equal(parsed.scrollFactor, 1)
})

test("buildInput updates existing keys in place", () => {
  const updated = Model.buildInput(SAMPLE_INPUT_LUA, "adaptive", 0.5, 1.25)
  const reparsed = Model.parseInput(updated)
  assert.equal(reparsed.accelProfile, "adaptive")
  assert.equal(reparsed.sensitivity, 0.5)
  assert.equal(reparsed.scrollFactor, 1.25)
  // The commented example block must survive untouched.
  assert.match(updated, /--     accel_profile = "flat",/)
})

test("buildInput inserts scroll_factor when the block never had one", () => {
  const withoutScroll = SAMPLE_INPUT_LUA
  const updated = Model.buildInput(withoutScroll, "flat", -0.1, 1.5)
  const reparsed = Model.parseInput(updated)
  assert.equal(reparsed.scrollFactor, 1.5)
})

test("buildInput returns null when there is no hl.config block to edit", () => {
  assert.equal(Model.buildInput("-- nothing here\n", "flat", 0, 1), null)
})
