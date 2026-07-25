// @zed-pkg-test/node-lib is sourced via zed (into .vendor/.zed, linked into
// node_modules by the node adapter); everything else would come from npm.
const { greet } = require("@zed-pkg-test/node-lib");
const msg = greet("node-app");
console.log(msg);
if (!msg.includes("from @zed-pkg-test/node-lib")) {
  console.error("FAIL: zed-sourced dependency did not resolve");
  process.exit(1);
}
console.log("OK: zed-sourced dep resolved alongside npm");
