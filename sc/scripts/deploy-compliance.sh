#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   COMPLIANCE DEPLOYMENT SCRIPT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/foundry.toml" ]; then
    echo -e "${RED}✗ Error: foundry.toml not found${NC}"
    echo "  Please run this script from the sc/ directory"
    exit 1
fi

cd "$PROJECT_ROOT" || exit 1

# Check for RPC URL argument
RPC_URL="${1:-http://localhost:8545}"
BROADCAST="${2:-}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  RPC URL: $RPC_URL"
echo "  Broadcast: ${BROADCAST:-simulation only}"
echo ""

# Compile contracts
echo -e "${YELLOW}[1/3] Compiling contracts...${NC}"
forge build > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Compilation successful${NC}"
else
    echo -e "${RED}  ✗ Compilation failed${NC}"
    exit 1
fi
echo ""

# Deploy contracts
echo -e "${YELLOW}[2/3] Deploying compliance contracts...${NC}"

if [ "$BROADCAST" == "--broadcast" ]; then
    echo "  (Broadcasting to blockchain...)"
    OUTPUT=$(forge script script/DeployCompliance.s.sol:DeployCompliance \
        --rpc-url "$RPC_URL" \
        --broadcast \
        2>&1)
else
    echo "  (Simulation mode - use '$0 $RPC_URL --broadcast' to deploy)"
    OUTPUT=$(forge script script/DeployCompliance.s.sol:DeployCompliance \
        --rpc-url "$RPC_URL" \
        2>&1)
fi

DEPLOY_STATUS=$?
echo ""

# Check deployment status
if [ $DEPLOY_STATUS -eq 0 ]; then
    echo -e "${GREEN}  ✓ Deployment successful${NC}"
else
    echo -e "${RED}  ✗ Deployment failed${NC}"
    echo "$OUTPUT"
    exit 1
fi
echo ""

# Extract addresses from output
echo -e "${YELLOW}[3/3] Extracting contract addresses...${NC}"

MAX_BALANCE=$(echo "$OUTPUT" | grep "MaxBalanceCompliance deployed at:" | awk '{print $4}' | tr '[:upper:]' '[:lower:]')
MAX_HOLDERS=$(echo "$OUTPUT" | grep "MaxHoldersCompliance deployed at:" | awk '{print $4}' | tr '[:upper:]' '[:lower:]')
TRANSFER_LOCK=$(echo "$OUTPUT" | grep "TransferLockCompliance deployed at:" | awk '{print $4}' | tr '[:upper:]' '[:lower:]')

if [ -n "$MAX_BALANCE" ]; then
    echo -e "${GREEN}  ✓ Addresses extracted:${NC}"
    echo "    MaxBalanceCompliance:    $MAX_BALANCE"
    echo "    MaxHoldersCompliance:    $MAX_HOLDERS"
    echo "    TransferLockCompliance:  $TRANSFER_LOCK"
    echo ""
    
    # Save to file
    ADDRESSES_FILE="$PROJECT_ROOT/deployments/compliance-addresses.json"
    mkdir -p "$(dirname "$ADDRESSES_FILE")"
    
    cat > "$ADDRESSES_FILE" << EOF
{
  "network": "$RPC_URL",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "contracts": {
    "MaxBalanceCompliance": "$MAX_BALANCE",
    "MaxHoldersCompliance": "$MAX_HOLDERS",
    "TransferLockCompliance": "$TRANSFER_LOCK"
  }
}
EOF
    
    echo -e "${GREEN}  ✓ Addresses saved to: $ADDRESSES_FILE${NC}"
    echo ""
else
    echo -e "${YELLOW}  ! Could not extract addresses from output${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      DEPLOYMENT SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$BROADCAST" == "--broadcast" ]; then
    echo -e "${GREEN}✓ All compliance contracts deployed${NC}"
else
    echo -e "${YELLOW}! Simulation completed (not deployed)${NC}"
fi

echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo ""
echo "  1. Bind module to token:"
echo "     cast send $MAX_BALANCE \\"
echo "       \"bindToken(address)\" \\"
echo "       <TOKEN_ADDRESS> \\"
echo "       --rpc-url $RPC_URL \\"
echo "       --private-key \$PRIVATE_KEY"
echo ""
echo "  2. Configure module settings:"
echo "     cast send $MAX_BALANCE \\"
echo "       \"setMaxBalance(address,uint256)\" \\"
echo "       <TOKEN_ADDRESS> \\"
echo "       1000000000000000000000000 \\"  # 1M tokens
echo "       --rpc-url $RPC_URL \\"
echo "       --private-key \$PRIVATE_KEY"
echo ""
echo "  3. Add module to token:"
echo "     cast send <TOKEN_ADDRESS> \\"
echo "       \"addComplianceModule(address)\" \\"
echo "       $MAX_BALANCE \\"
echo "       --rpc-url $RPC_URL \\"
echo "       --private-key \$PRIVATE_KEY"
echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# Show full output in verbose mode
if [ "$VERBOSE" == "1" ]; then
    echo -e "${YELLOW}Full deployment output:${NC}"
    echo "$OUTPUT"
fi

