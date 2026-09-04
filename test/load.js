"use strict"
const fs = require("node:fs")
const path = require("node:path")

// QML JS libraries are plain JS: execute the source in a sandboxed Function
// and harvest top-level declarations, so lib/ stays importable by QML.
function loadQmlJs(relativePath) {
  const file = path.join(__dirname, "..", relativePath)
  const src = fs.readFileSync(file, "utf8").replace(/^\s*\.pragma\s+library\s*$/gm, "")
  const names = [...src.matchAll(/^function\s+([A-Za-z_$][\w$]*)\s*\(/gm)].map(m => m[1])
  if (names.length === 0) throw new Error("no top-level functions found in " + relativePath)
  const api = {}
  new Function("exports", src + "\nObject.assign(exports,{" + names.join(",") + "});")(api)
  return api
}

module.exports = { loadQmlJs }
