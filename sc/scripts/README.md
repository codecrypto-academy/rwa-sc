# Deployment Scripts

## Table of Contents
- [deploy-complete-auto.sh](#deploy-complete-autosh) - Complete system deployment
- [deploy-compliance.sh](#deploy-compliancesh) - Compliance contracts deployment

---

## deploy-complete-auto.sh

Complete automated deployment script for the RWA system.

### What It Does

1. **Restarts Anvil** with a clean state
2. **Deploys all contracts**:
   - IdentityCloneFactory
   - IdentityRegistry
   - TrustedIssuersRegistry
   - TokenCloneFactory
3. **Creates 3 identities** using Anvil accounts (0, 1, 2)
4. **Registers** all identities in IdentityRegistry
5. **Adds 3 trusted issuers** with claim topics:
   - Issuer 1: KYC, AML
   - Issuer 2: KYC, Accredited Investor
   - Issuer 3: KYC, AML, Accredited Investor
6. **Creates 1 security token** (RWAST) with registries configured
7. **Updates all web applications** with new contract addresses
8. **Verifies** everything is working correctly

### Usage

```bash
cd /Users/joseviejo/2025/cc/PROYECTOS\ TRAINING/56_RWA_SC/sc
./scripts/deploy-complete-auto.sh
```

### Requirements

- Anvil must be installed (part of Foundry)
- `forge`, `cast`, and `jq` must be in PATH
- Web applications must exist in `/Users/joseviejo/2025/cc/PROYECTOS TRAINING/57_RWA_WEB/`

### Output

The script will:
- Show real-time progress
- Display all deployed contract addresses
- Show created identities and their addresses
- List trusted issuers with their claim topics
- Show the created token details
- Verify all operations were successful

### After Running

1. **Start the web applications**:
   ```bash
   # Terminal 1
   cd /Users/joseviejo/2025/cc/PROYECTOS\ TRAINING/57_RWA_WEB/web-identity
   npm run dev
   
   # Terminal 2
   cd /Users/joseviejo/2025/cc/PROYECTOS\ TRAINING/57_RWA_WEB/web-registry-trusted
   npm run dev -- -p 3001
   
   # Terminal 3
   cd /Users/joseviejo/2025/cc/PROYECTOS\ TRAINING/57_RWA_WEB/web-token
   npm run dev -- -p 3002
   ```

2. **Configure MetaMask**:
   - Network: Anvil Local
   - RPC: http://localhost:8545
   - Chain ID: 31337
   - Import Anvil test accounts

3. **Access the applications**:
   - Identity Management: http://localhost:3000
   - Trusted Issuers: http://localhost:3001
   - Token Factory: http://localhost:3002

### Anvil Accounts

The script uses these default Anvil accounts:

| Account | Address | Private Key | Role |
|---------|---------|-------------|------|
| 0 | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974...` | Admin, Identity, Issuer |
| 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c699...` | Identity, Issuer |
| 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de411...` | Identity, Issuer |

### Verification

The script automatically verifies:
- All contracts are deployed and responding
- Identities were created (should be 3)
- Trusted issuers were added (should be 3)
- Token was created (should be 1)
- Web applications were updated with correct addresses

### Troubleshooting

**"Anvil failed to start"**:
- Check if port 8545 is already in use
- Try manually killing anvil: `pkill -f anvil`

**"Deployment failed"**:
- Check forge is installed: `forge --version`
- Ensure contracts compile: `forge build`

**"Web app not updated"**:
- Check the paths in the script match your system
- Verify the contract files exist in `lib/contracts/`

### Files Modified

The script modifies these files:
- `web-identity/lib/contracts.ts`
- `web-registry-trusted/lib/contracts/TrustedIssuersRegistry.ts`
- `web-token/lib/contracts/TokenCloneFactory.ts`

### Deployment Details

See the full deployment summary at:
```
/Users/joseviejo/2025/cc/PROYECTOS TRAINING/56_RWA_SC/DEPLOYMENT_COMPLETE_SUMMARY.md
```

### Re-running

You can run this script multiple times. Each time it will:
- Kill and restart Anvil (fresh state)
- Deploy new contracts with new addresses
- Update web applications automatically

This is useful for:
- Testing with clean state
- Fixing deployment issues
- Starting fresh development cycles

---

## deploy-compliance.sh

Deployment script for all compliance contracts.

### What It Does

1. **Compiles** all contracts
2. **Deploys** compliance contracts:
   - ComplianceAggregator (recommended)
   - MaxBalanceCompliance (individual module)
   - MaxHoldersCompliance (individual module)
   - TransferLockCompliance (individual module)
3. **Extracts** and saves contract addresses
4. **Provides** ready-to-use configuration commands

### Usage

```bash
cd /Users/joseviejo/2025/cc/PROYECTOS\ TRAINING/56_RWA_SC/sc

# Simulation mode (dry-run)
./scripts/deploy-compliance.sh

# Deploy to local Anvil
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# Deploy to testnet/mainnet
export PRIVATE_KEY=<your-private-key>
./scripts/deploy-compliance.sh $RPC_URL --broadcast
```

### Default Values

The contracts are deployed with sensible defaults:

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Max Balance | 1,000,000 tokens | Maximum tokens per wallet |
| Max Holders | 100 | Maximum number of token holders |
| Lock Period | 86,400 seconds (1 day) | Holding period after receiving tokens |

### Output Files

The script saves deployed addresses to:
```
sc/deployments/compliance-addresses.json
```

Example format:
```json
{
  "network": "http://localhost:8545",
  "timestamp": "2025-11-11T12:00:00Z",
  "contracts": {
    "ComplianceAggregator": "0x...",
    "MaxBalanceCompliance": "0x...",
    "MaxHoldersCompliance": "0x...",
    "TransferLockCompliance": "0x..."
  }
}
```

### Configuration After Deployment

#### Option 1: Use ComplianceAggregator (RECOMMENDED)

Best for most use cases. Single contract with all compliance rules.

```bash
AGGREGATOR=<address-from-output>
TOKEN=<your-token-address>

# Configure token
cast send $AGGREGATOR \
  "configureToken(address,uint256,uint256,uint256)" \
  $TOKEN \
  1000000000000000000000000 \    # 1M tokens max balance
  100 \                           # 100 max holders
  86400 \                         # 1 day lock period
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# Add to token
cast send $TOKEN \
  "addComplianceModule(address)" \
  $AGGREGATOR \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

**Benefits:**
- ✅ ~67% gas savings vs separate modules
- ✅ Single transaction for configuration
- ✅ Centralized management
- ✅ All rules in one contract

#### Option 2: Use Individual Modules

Best when you need:
- Only specific compliance rules
- Custom compliance logic
- Independent module management

**MaxBalanceCompliance:**
```bash
MODULE=<address-from-output>
TOKEN=<your-token-address>

# 1. Bind token
cast send $MODULE "bindToken(address)" $TOKEN \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 2. Set max balance
cast send $MODULE "setMaxBalance(address,uint256)" $TOKEN 1000000000000000000000000 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 3. Add to token
cast send $TOKEN "addComplianceModule(address)" $MODULE \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
```

**MaxHoldersCompliance:**
```bash
# Similar steps with setMaxHolders(address,uint256)
cast send $MODULE "setMaxHolders(address,uint256)" $TOKEN 100 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
```

**TransferLockCompliance:**
```bash
# Similar steps with setLockPeriod(address,uint256)
cast send $MODULE "setLockPeriod(address,uint256)" $TOKEN 86400 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
```

### Compliance Rules Explained

**MaxBalance:**
- Limits maximum tokens per wallet
- Prevents concentration of ownership
- Example: Max 1M tokens per investor

**MaxHolders:**
- Limits total number of token holders
- Required for some securities regulations
- Example: Max 100 investors for private securities

**TransferLock:**
- Enforces holding period after receiving tokens
- Prevents immediate resale (lock-up period)
- Example: Must hold tokens for 1 day after receiving

### Gas Cost Comparison

| Operation | ComplianceAggregator | 3 Separate Modules | Savings |
|-----------|---------------------|-------------------|---------|
| Transfer | ~120k gas | ~360k gas | **~67%** |
| Deploy | ~2.5M gas | ~3.5M gas | ~29% |
| Configuration | 1 tx | 9 txs | **~89%** |

### Verification Commands

```bash
# Verify ComplianceAggregator owner
cast call $AGGREGATOR "owner()" --rpc-url http://localhost:8545

# Check token configuration in Aggregator
cast call $AGGREGATOR "getTokenConfig(address)" $TOKEN --rpc-url http://localhost:8545

# Check token's compliance modules
cast call $TOKEN "getComplianceModules()" --rpc-url http://localhost:8545

# Verify individual module
cast call $MODULE "owner()" --rpc-url http://localhost:8545
cast call $MODULE "maxBalance()" --rpc-url http://localhost:8545
```

### Full Documentation

For detailed information, see:
```
/Users/joseviejo/2025/cc/PROYECTOS TRAINING/56_RWA_SC/COMPLIANCE_DEPLOYMENT.md
```

### Troubleshooting

**"Only owner can call this function"**
- Ensure you're using the deployer's private key
- Check ownership: `cast call <ADDRESS> "owner()"`

**"Compilation failed"**
- Run `forge build` to see detailed errors
- Ensure all dependencies are installed

**"Transaction reverted"**
- Verify you have enough ETH for gas
- Check that parameters are correct (no overflow)
- Ensure token address is valid

### Example: Complete Workflow

```bash
# 1. Deploy compliance
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# 2. Get addresses (from output or JSON file)
AGGREGATOR=$(jq -r '.contracts.ComplianceAggregator' deployments/compliance-addresses.json)
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 3. Configure
cast send $AGGREGATOR \
  "configureToken(address,uint256,uint256,uint256)" \
  $TOKEN 5000000000000000000000000 50 172800 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 4. Add to token
cast send $TOKEN \
  "addComplianceModule(address)" $AGGREGATOR \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 5. Verify
cast call $AGGREGATOR "getTokenConfig(address)" $TOKEN \
  --rpc-url http://localhost:8545

# 6. Test transfer (should respect compliance rules)
cast send $TOKEN \
  "transfer(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1000000000000000000000 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY
```

### Requirements

- Forge (Foundry) installed
- Cast installed
- jq installed (for JSON parsing)
- Solidity 0.8.20+

### Re-running

You can run this script multiple times. Each deployment will:
- Create new contract instances
- Generate new addresses
- Save to timestamped JSON files
- Show updated configuration commands

This is useful for:
- Testing different configurations
- Upgrading compliance logic
- Deploying to multiple networks

