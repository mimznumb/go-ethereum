import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    profiles: {
      default: { version: "0.8.28" },
      production: {
        version: "0.8.28",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
    },
  },
  networks: {
    hardhatMainnet: { type: "edr-simulated", chainType: "l1" },
    hardhatOp: { type: "edr-simulated", chainType: "op" },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },

    // Add this for your Docker Geth devnet
    localdevnet: {
      type: "http",
      chainType: "l1",
      url: "http://127.0.0.1:8545",
      accounts: [
        // Pre-funded Hardhat test key (handy for devnets)
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      ],
    },
  },
});


// import { HardhatUserConfig } from "hardhat/config";

// const config: HardhatUserConfig = {
//   solidity: "0.8.28",
//   networks: {
//     localdevnet: {
//       url: "http://127.0.0.1:8545",
//       accounts: [
//         // pre-funded test key; fine for local devnet
//         "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
//       ],
//     },
//   },
// };

// export default config;
