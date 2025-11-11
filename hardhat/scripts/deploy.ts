import hre from "hardhat";
import { ethers } from "ethers";

async function fundDeployerIfNeeded(provider: ethers.JsonRpcProvider, deployer: string) {
  const min = 1_000_000_000_000_000_000n; // 1 ETH
  const bal = await provider.getBalance(deployer);
  if (bal >= min) return;

  const [dev] = await provider.send("eth_accounts", []);
  if (!dev) throw new Error("No dev account found on --dev chain");

  const txHash: string = await provider.send("eth_sendTransaction", [{
    from: dev,
    to: deployer,
    value: "0x56BC75E2D63100000" // 100 ETH
  }]);
  await provider.waitForTransaction(txHash);
}

async function main() {
  const RPC = process.env.RPC_URL ?? "http://127.0.0.1:8545";
  const PK  = process.env.DEPLOYER_PK
    ?? "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

  const provider = new ethers.JsonRpcProvider(RPC);
  const wallet   = new ethers.Wallet(PK, provider);

  // show we’re on the right chain
  const net = await provider.getNetwork();
  console.log("Connected chainId:", net.chainId.toString());

  // ensure deployer has funds
  await fundDeployerIfNeeded(provider, await wallet.getAddress());

  // deploy Lock
  const artifact = await hre.artifacts.readArtifact("Lock");
  const factory  = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const addr = await contract.getAddress();
  const code = await provider.getCode(addr);
  console.log("Lock deployed to:", addr);
  console.log("Deployed code length:", code.length); // should be > 2
}

main().catch((e) => { console.error(e); process.exit(1); });
