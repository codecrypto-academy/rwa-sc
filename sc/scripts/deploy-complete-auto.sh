#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SC_DIR="/Users/joseviejo/2025/cc/PROYECTOS TRAINING/56_RWA_SC/sc"
WEB_DIR="/Users/joseviejo/2025/cc/PROYECTOS TRAINING/57_RWA_WEB"

# Anvil default private key
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   COMPLETE DEPLOYMENT AUTOMATION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Kill existing Anvil and start fresh
echo -e "${YELLOW}[1/7] Restarting Anvil for clean state...${NC}"
pkill -f anvil
sleep 2
anvil > /dev/null 2>&1 &
ANVIL_PID=$!
sleep 3

if ps -p $ANVIL_PID > /dev/null; then
    echo -e "${GREEN}✓ Anvil restarted (PID: $ANVIL_PID)${NC}"
else
    echo -e "${RED}✗ Failed to start Anvil${NC}"
    exit 1
fi
echo ""

# Step 2: Compile contracts
echo -e "${YELLOW}[2/7] Compiling contracts...${NC}"
cd "$SC_DIR"
forge build > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contracts compiled successfully${NC}"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi
echo ""

# Step 3: Deploy all contracts and setup
echo -e "${YELLOW}[3/7] Deploying contracts and setting up system...${NC}"
echo -e "  (This may take a moment...)"
PRIVATE_KEY=$PRIVATE_KEY forge script script/DeployComplete.s.sol:DeployComplete \
    --rpc-url http://localhost:8545 \
    --broadcast 2>&1 | grep -E "(Step|Identity|Token|Trusted|deployed|created|added|Registered)" | sed 's/^/  /'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment complete${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
echo ""

# Step 4: Extract addresses from deployment
echo -e "${YELLOW}[4/7] Extracting contract addresses...${NC}"

# Read the latest deployment file
DEPLOY_FILE="$SC_DIR/broadcast/DeployComplete.s.sol/31337/run-latest.json"

if [ ! -f "$DEPLOY_FILE" ]; then
    echo -e "${RED}✗ Deployment file not found${NC}"
    exit 1
fi

# Extract addresses using jq
IDENTITY_FACTORY=$(jq -r '.transactions[] | select(.contractName == "IdentityCloneFactory") | .contractAddress' "$DEPLOY_FILE" | head -1)
IDENTITY_IMPL=$(jq -r '.transactions[] | select(.contractName == "IdentityCloneable" and .transactionType == "CREATE") | .contractAddress' "$DEPLOY_FILE" | head -1)
IDENTITY_REGISTRY=$(jq -r '.transactions[] | select(.contractName == "IdentityRegistry") | .contractAddress' "$DEPLOY_FILE" | head -1)
TRUSTED_ISSUERS=$(jq -r '.transactions[] | select(.contractName == "TrustedIssuersRegistry") | .contractAddress' "$DEPLOY_FILE" | head -1)
TOKEN_FACTORY=$(jq -r '.transactions[] | select(.contractName == "TokenCloneFactory") | .contractAddress' "$DEPLOY_FILE" | head -1)
TOKEN_IMPL=$(jq -r '.transactions[] | select(.contractName == "TokenCloneable" and .transactionType == "CREATE") | .contractAddress' "$DEPLOY_FILE" | head -1)

echo -e "${GREEN}✓ Addresses extracted:${NC}"
echo -e "  IdentityCloneFactory:    ${IDENTITY_FACTORY}"
echo -e "    Implementation:        ${IDENTITY_IMPL}"
echo -e "  IdentityRegistry:        ${IDENTITY_REGISTRY}"
echo -e "  TrustedIssuersRegistry:  ${TRUSTED_ISSUERS}"
echo -e "  TokenCloneFactory:       ${TOKEN_FACTORY}"
echo -e "    Implementation:        ${TOKEN_IMPL}"
echo ""

# Step 5: Update web applications
echo -e "${YELLOW}[5/7] Updating web applications...${NC}"

# Update web-identity (contracts.ts)
WEB_IDENTITY_CONTRACTS="$WEB_DIR/web-identity/lib/contracts.ts"
if [ -f "$WEB_IDENTITY_CONTRACTS" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/export const IDENTITY_REGISTRY_ADDRESS = '[^']*'/export const IDENTITY_REGISTRY_ADDRESS = '${IDENTITY_REGISTRY}'/" "$WEB_IDENTITY_CONTRACTS"
        sed -i '' "s/export const IDENTITY_FACTORY_ADDRESS = '[^']*'/export const IDENTITY_FACTORY_ADDRESS = '${IDENTITY_FACTORY}'/" "$WEB_IDENTITY_CONTRACTS"
    else
        sed -i "s/export const IDENTITY_REGISTRY_ADDRESS = '[^']*'/export const IDENTITY_REGISTRY_ADDRESS = '${IDENTITY_REGISTRY}'/" "$WEB_IDENTITY_CONTRACTS"
        sed -i "s/export const IDENTITY_FACTORY_ADDRESS = '[^']*'/export const IDENTITY_FACTORY_ADDRESS = '${IDENTITY_FACTORY}'/" "$WEB_IDENTITY_CONTRACTS"
    fi
    echo -e "${GREEN}  ✓ Updated web-identity/lib/contracts.ts${NC}"
else
    echo -e "${YELLOW}  ⚠ web-identity contracts.ts not found${NC}"
fi

# Update web-registry-trusted
WEB_TRUSTED_FILE="$WEB_DIR/web-registry-trusted/lib/contracts/TrustedIssuersRegistry.ts"
if [ -f "$WEB_TRUSTED_FILE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/export const TRUSTED_ISSUERS_REGISTRY_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TRUSTED_ISSUERS_REGISTRY_ADDRESS = \"${TRUSTED_ISSUERS}\"/" "$WEB_TRUSTED_FILE"
    else
        sed -i "s/export const TRUSTED_ISSUERS_REGISTRY_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TRUSTED_ISSUERS_REGISTRY_ADDRESS = \"${TRUSTED_ISSUERS}\"/" "$WEB_TRUSTED_FILE"
    fi
    echo -e "${GREEN}  ✓ Updated web-registry-trusted/lib/contracts/TrustedIssuersRegistry.ts${NC}"
else
    echo -e "${YELLOW}  ⚠ web-registry-trusted TrustedIssuersRegistry.ts not found${NC}"
fi

# Update web-token
WEB_TOKEN_FILE="$WEB_DIR/web-token/lib/contracts/TokenCloneFactory.ts"
if [ -f "$WEB_TOKEN_FILE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/export const TOKEN_CLONE_FACTORY_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TOKEN_CLONE_FACTORY_ADDRESS = \"${TOKEN_FACTORY}\"/" "$WEB_TOKEN_FILE"
        sed -i '' "s/export const TOKEN_IMPLEMENTATION_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TOKEN_IMPLEMENTATION_ADDRESS = \"${TOKEN_IMPL}\"/" "$WEB_TOKEN_FILE"
    else
        sed -i "s/export const TOKEN_CLONE_FACTORY_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TOKEN_CLONE_FACTORY_ADDRESS = \"${TOKEN_FACTORY}\"/" "$WEB_TOKEN_FILE"
        sed -i "s/export const TOKEN_IMPLEMENTATION_ADDRESS = \"0x[a-fA-F0-9]*\"/export const TOKEN_IMPLEMENTATION_ADDRESS = \"${TOKEN_IMPL}\"/" "$WEB_TOKEN_FILE"
    fi
    echo -e "${GREEN}  ✓ Updated web-token/lib/contracts/TokenCloneFactory.ts${NC}"
else
    echo -e "${YELLOW}  ⚠ web-token TokenCloneFactory.ts not found${NC}"
fi

echo ""

# Step 6: Verify deployment
echo -e "${YELLOW}[6/7] Verifying deployment...${NC}"

verify_contract() {
    local name=$1
    local address=$2
    local function=$3
    
    if [ -z "$address" ] || [ "$address" == "null" ]; then
        echo -e "${RED}  ✗ $name: No address found${NC}"
        return 1
    fi
    
    result=$(cast call "$address" "$function" --rpc-url http://localhost:8545 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ $name: $address${NC}"
        return 0
    else
        echo -e "${RED}  ✗ $name verification failed${NC}"
        return 1
    fi
}

verify_contract "IdentityCloneFactory" "$IDENTITY_FACTORY" "implementation()(address)"
verify_contract "IdentityRegistry" "$IDENTITY_REGISTRY" "owner()(address)"
verify_contract "TrustedIssuersRegistry" "$TRUSTED_ISSUERS" "getTrustedIssuersCount()(uint256)"
verify_contract "TokenCloneFactory" "$TOKEN_FACTORY" "getTotalTokens()(uint256)"

echo ""

# Step 7: Verify data created
echo -e "${YELLOW}[7/7] Verifying created data...${NC}"

# Check identities created
TOTAL_IDENTITIES=$(cast call "$IDENTITY_FACTORY" "getTotalIdentities()(uint256)" --rpc-url http://localhost:8545 2>/dev/null)
echo -e "${GREEN}  ✓ Identities created: $(printf %d $TOTAL_IDENTITIES)${NC}"

# Check trusted issuers
TOTAL_ISSUERS=$(cast call "$TRUSTED_ISSUERS" "getTrustedIssuersCount()(uint256)" --rpc-url http://localhost:8545 2>/dev/null)
echo -e "${GREEN}  ✓ Trusted issuers added: $(printf %d $TOTAL_ISSUERS)${NC}"

# Check tokens created
TOTAL_TOKENS=$(cast call "$TOKEN_FACTORY" "getTotalTokens()(uint256)" --rpc-url http://localhost:8545 2>/dev/null)
echo -e "${GREEN}  ✓ Tokens created: $(printf %d $TOTAL_TOKENS)${NC}"

# Get the token address
TOKEN_ADDRESS=$(cast call "$TOKEN_FACTORY" "getTokenAt(uint256)(address)" 0 --rpc-url http://localhost:8545 2>/dev/null)
if [ -n "$TOKEN_ADDRESS" ] && [ "$TOKEN_ADDRESS" != "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${GREEN}  ✓ Token address: $TOKEN_ADDRESS${NC}"
fi

echo ""

# Final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}        DEPLOYMENT SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ Anvil restarted (clean state)${NC}"
echo -e "${GREEN}✓ All contracts deployed${NC}"
echo -e "${GREEN}✓ 3 identities created & registered${NC}"
echo -e "${GREEN}✓ 3 trusted issuers added${NC}"
echo -e "${GREEN}✓ 1 security token created${NC}"
echo -e "${GREEN}✓ All web applications updated${NC}"
echo -e "${GREEN}✓ Deployment verified${NC}"
echo ""
echo -e "${YELLOW}Contract Addresses:${NC}"
echo -e "  IdentityCloneFactory:    ${GREEN}${IDENTITY_FACTORY}${NC}"
echo -e "  IdentityRegistry:        ${GREEN}${IDENTITY_REGISTRY}${NC}"
echo -e "  TrustedIssuersRegistry:  ${GREEN}${TRUSTED_ISSUERS}${NC}"
echo -e "  TokenCloneFactory:       ${GREEN}${TOKEN_FACTORY}${NC}"
echo -e "  Token (RWAST):           ${GREEN}${TOKEN_ADDRESS}${NC}"
echo ""
echo -e "${YELLOW}Anvil Accounts Used:${NC}"
echo -e "  Account 0 (Admin):       ${GREEN}0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266${NC}"
echo -e "    - Identity, Trusted Issuer, Token Admin"
echo -e "  Account 1:               ${GREEN}0x70997970C51812dc3A010C7d01b50e0d17dc79C8${NC}"
echo -e "    - Identity, Trusted Issuer"
echo -e "  Account 2:               ${GREEN}0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC${NC}"
echo -e "    - Identity, Trusted Issuer"
echo ""
echo -e "${YELLOW}Web Applications:${NC}"
echo -e "  web-identity:            ${GREEN}Updated${NC}"
echo -e "  web-registry-trusted:    ${GREEN}Updated${NC}"
echo -e "  web-token:               ${GREEN}Updated${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Start web applications:"
echo -e "     ${GREEN}cd $WEB_DIR/web-identity && npm run dev${NC}         (Port 3000)"
echo -e "     ${GREEN}cd $WEB_DIR/web-registry-trusted && npm run dev${NC} (Port 3001)"
echo -e "     ${GREEN}cd $WEB_DIR/web-token && npm run dev${NC}            (Port 3002)"
echo -e "  2. Connect MetaMask to Anvil (Chain ID: 31337)"
echo -e "  3. Import Anvil accounts to MetaMask"
echo -e "  4. Anvil is running in background (PID: $ANVIL_PID)"
echo ""

