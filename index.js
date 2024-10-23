const { ethers } = require("ethers");
const address = process.argv[2];
try {
  const checksummed = ethers.getAddress(address);
  process.stdout.write(checksummed + "\n");
} catch (e) {
  process.stderr.write(e);
  process.exit(1);
}
