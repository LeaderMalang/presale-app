// This script can be run in the Remix IDE.
// It assumes you have a helper file named `ethers-lib.js` in the same directory.
// 1. Make sure you have all your contracts compiled.
// 2. Open the "Deploy & Run Transactions" tab in Remix.
// 3. Select the "Injected Provider - MetaMask" environment and connect your wallet.
// 4. Go back to the "File Explorer", right-click on this script's name, and click "Run".
// 5. The addresses of all deployed contracts will be printed in the Remix console.

import { deploy } from './ethers-lib'

(async () => {
    try {
        console.log('Starting deployment of all AI platform contracts...');

        // --- CONFIGURE THESE VALUES BEFORE RUNNING ---
        const SAFE_ADDRESS = "0x7e9dA27B303e20dA738E158b86fA38d082c94366"; // IMPORTANT: Replace this
        const USDC_ADDRESS_TESTNET = "0xf3C3351D6Bd0098EEb33ca8f830FAf2a141Ea2E1"; // IMPORTANT: Replace with a testnet USDC address
        
        // --- Role Addresses ---
        // These can be the same as the SAFE_ADDRESS or dedicated addresses.
        const defaultAdmin = SAFE_ADDRESS;
        const roleAdmin = SAFE_ADDRESS;
        const pauser = SAFE_ADDRESS;
        const arbiter = SAFE_ADDRESS;
        const uriSetter = SAFE_ADDRESS;
        const verifier = "0x7e9dA27B303e20dA738E158b86fA38d082c94366"; // The address of your off-chain verifier service
        const minter = "0x7e9dA27B303e20dA738E158b86fA38d082c94366";   // The address of your off-chain minter service

        // --- Contract Parameters ---
        const initialURI = "https://api.yourplatform.com/assets/{id}";
        const eip712Name = "AIUsageReceipts";
        const eip712Version = "1";
        const initialFeeBps = 250; // 2.5%
        const disputeWindowSeconds = 3 * 24 * 60 * 60; // 3 days

        // --- Deployment Logic ---

        // 1. AssetToken
        console.log('Deploying AssetToken...');
        const assetToken = await deploy("AssetToken", [defaultAdmin, minter, uriSetter, initialURI]);
        console.log(`AssetToken deployed to: ${assetToken.address}`);

        // 2. ContributorRegistry
        console.log('Deploying ContributorRegistry...');
        const contributorRegistry = await deploy("ContributorRegistry", [defaultAdmin, roleAdmin, pauser]);
        console.log(`ContributorRegistry deployed to: ${contributorRegistry.address}`);

        // 3. ProvenanceGraph
        console.log('Deploying ProvenanceGraph...');
        const provenanceGraph = await deploy("ProvenanceGraph", [assetToken.address, contributorRegistry.address]);
        console.log(`ProvenanceGraph deployed to: ${provenanceGraph.address}`);

        // 4. RoyaltySplitFactory
        console.log('Deploying RoyaltySplitFactory...');
        const royaltySplitFactory = await deploy("RoyaltySplitFactory", [provenanceGraph.address]);
        console.log(`RoyaltySplitFactory deployed to: ${royaltySplitFactory.address}`);

        // 5. FeeTreasury
        console.log('Deploying FeeTreasury...');
        const feeTreasury = await deploy("FeeTreasury", [defaultAdmin, SAFE_ADDRESS, initialFeeBps]);
        console.log(`FeeTreasury deployed to: ${feeTreasury.address}`);
        
        // 6. Escrow
        console.log('Deploying Escrow...');
        const escrow = await deploy("Escrow", [USDC_ADDRESS_TESTNET, feeTreasury.address, royaltySplitFactory.address, defaultAdmin, pauser, arbiter, disputeWindowSeconds]);
        console.log(`Escrow deployed to: ${escrow.address}`);

        // 7. UsageReceiptVerifier
        console.log('Deploying UsageReceiptVerifier...');
        const usageReceiptVerifier = await deploy("UsageReceiptVerifier", [eip712Name, eip712Version, USDC_ADDRESS_TESTNET, escrow.address, defaultAdmin, verifier, pauser]);
        console.log(`UsageReceiptVerifier deployed to: ${usageReceiptVerifier.address}`);

        // 8. RegistryRouter
        console.log('Deploying RegistryRouter...');
        const registryRouter = await deploy("RegistryRouter", [assetToken.address, contributorRegistry.address, provenanceGraph.address, royaltySplitFactory.address]);
        console.log(`RegistryRouter deployed to: ${registryRouter.address}`);

        console.log('\n--- All contracts deployed successfully! ---');
        console.log(`AssetToken: ${assetToken.address}`);
        console.log(`ContributorRegistry: ${contributorRegistry.address}`);
        console.log(`ProvenanceGraph: ${provenanceGraph.address}`);
        console.log(`RoyaltySplitFactory: ${royaltySplitFactory.address}`);
        console.log(`FeeTreasury: ${feeTreasury.address}`);
        console.log(`Escrow: ${escrow.address}`);
        console.log(`UsageReceiptVerifier: ${usageReceiptVerifier.address}`);
        console.log(`RegistryRouter: ${registryRouter.address}`);
        console.log('\nDeployment finished.');

    } catch (e) {
        console.error('Deployment failed:', e);
    }
})();

