import { expect } from "chai";
import { ethers } from "ethers";

const RPC = process.env.RPC_URL || "http://127.0.0.1:8545";
const LOCK = process.env.LOCK_ADDRESS;

describe("Predeployed Lock (Geth RPC)", function () {
  it("has bytecode at LOCK_ADDRESS", async () => {
    if (!LOCK) throw new Error("LOCK_ADDRESS not set");
    const provider = new ethers.JsonRpcProvider(RPC);
    const code = await provider.getCode(LOCK);
    expect(code).to.not.equal("0x");
  });
});
