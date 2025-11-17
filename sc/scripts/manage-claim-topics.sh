#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RPC_URL="${RPC_URL:-http://localhost:8545}"
CLAIM_TOPICS_REGISTRY="${CLAIM_TOPICS_REGISTRY:-}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   CLAIM TOPICS MANAGEMENT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list <registry_address>           - List all claim topics"
    echo "  add <registry_address> <topic>    - Add a new claim topic"
    echo "  remove <registry_address> <topic> - Remove a claim topic"
    echo "  exists <registry_address> <topic> - Check if topic exists"
    echo ""
    echo "Environment Variables:"
    echo "  RPC_URL       - RPC endpoint (default: http://localhost:8545)"
    echo "  PRIVATE_KEY   - Private key for transactions (required for add/remove)"
    echo ""
    echo "Claim Topic IDs (Common):"
    echo "  1 - KYC (Know Your Customer)"
    echo "  2 - AML (Anti-Money Laundering)"
    echo "  3 - Accredited Investor"
    echo "  4 - Country Verification"
    echo "  5 - Age Verification"
    echo ""
    echo "Examples:"
    echo "  # List all topics"
    echo "  $0 list 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
    echo ""
    echo "  # Add KYC topic"
    echo "  export PRIVATE_KEY=0xac0974..."
    echo "  $0 add 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 1"
    echo ""
    echo "  # Remove AML topic"
    echo "  $0 remove 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 2"
    echo ""
    exit 1
}

# Function to get topic name
get_topic_name() {
    case $1 in
        1) echo "KYC (Know Your Customer)" ;;
        2) echo "AML (Anti-Money Laundering)" ;;
        3) echo "Accredited Investor" ;;
        4) echo "Country Verification" ;;
        5) echo "Age Verification" ;;
        *) echo "Custom Topic" ;;
    esac
}

# Check if cast is installed
if ! command -v cast &> /dev/null; then
    echo -e "${RED}✗ Error: 'cast' command not found${NC}"
    echo "  Please install Foundry: https://getfoundry.sh"
    exit 1
fi

# Parse command
COMMAND="${1:-}"
REGISTRY="${2:-}"

if [ -z "$COMMAND" ] || [ -z "$REGISTRY" ]; then
    show_usage
fi

case $COMMAND in
    list)
        echo -e "${YELLOW}Fetching claim topics from: $REGISTRY${NC}"
        echo ""
        
        # Get topics
        TOPICS_HEX=$(cast call "$REGISTRY" "getClaimTopics()" --rpc-url "$RPC_URL" 2>&1)
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Error fetching topics${NC}"
            echo "$TOPICS_HEX"
            exit 1
        fi
        
        # Get count
        COUNT=$(cast call "$REGISTRY" "getClaimTopicsCount()" --rpc-url "$RPC_URL" 2>&1)
        COUNT_DEC=$(cast --to-dec "$COUNT" 2>/dev/null || echo "0")
        
        echo -e "${GREEN}✓ Found $COUNT_DEC claim topics:${NC}"
        echo ""
        
        if [ "$COUNT_DEC" -eq 0 ]; then
            echo "  No topics configured yet."
        else
            # Parse the hex output (this is a simple approach)
            echo "  Registry: $REGISTRY"
            echo "  Total: $COUNT_DEC topics"
            echo ""
            echo "  Use: cast call $REGISTRY \"getClaimTopics()\" --rpc-url $RPC_URL"
            echo "       to see raw data"
        fi
        ;;
        
    add)
        TOPIC="${3:-}"
        if [ -z "$TOPIC" ]; then
            echo -e "${RED}✗ Error: Topic ID required${NC}"
            show_usage
        fi
        
        if [ -z "$PRIVATE_KEY" ]; then
            echo -e "${RED}✗ Error: PRIVATE_KEY environment variable required${NC}"
            exit 1
        fi
        
        TOPIC_NAME=$(get_topic_name "$TOPIC")
        
        echo -e "${YELLOW}Adding claim topic: $TOPIC ($TOPIC_NAME)${NC}"
        echo "  Registry: $REGISTRY"
        echo ""
        
        # Check if already exists
        EXISTS=$(cast call "$REGISTRY" "claimTopicExists(uint256)" "$TOPIC" --rpc-url "$RPC_URL" 2>&1)
        if echo "$EXISTS" | grep -q "0x0000000000000000000000000000000000000000000000000000000000000001"; then
            echo -e "${YELLOW}! Topic already exists${NC}"
            exit 0
        fi
        
        # Add topic
        TX=$(cast send "$REGISTRY" \
            "addClaimTopic(uint256)" \
            "$TOPIC" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY" \
            2>&1)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Claim topic added successfully${NC}"
            echo ""
            # Extract transaction hash
            TX_HASH=$(echo "$TX" | grep "transactionHash" | awk '{print $2}')
            if [ -n "$TX_HASH" ]; then
                echo "  Transaction: $TX_HASH"
            fi
        else
            echo -e "${RED}✗ Error adding topic${NC}"
            echo "$TX"
            exit 1
        fi
        ;;
        
    remove)
        TOPIC="${3:-}"
        if [ -z "$TOPIC" ]; then
            echo -e "${RED}✗ Error: Topic ID required${NC}"
            show_usage
        fi
        
        if [ -z "$PRIVATE_KEY" ]; then
            echo -e "${RED}✗ Error: PRIVATE_KEY environment variable required${NC}"
            exit 1
        fi
        
        TOPIC_NAME=$(get_topic_name "$TOPIC")
        
        echo -e "${YELLOW}Removing claim topic: $TOPIC ($TOPIC_NAME)${NC}"
        echo "  Registry: $REGISTRY"
        echo ""
        
        # Check if exists
        EXISTS=$(cast call "$REGISTRY" "claimTopicExists(uint256)" "$TOPIC" --rpc-url "$RPC_URL" 2>&1)
        if echo "$EXISTS" | grep -q "0x0000000000000000000000000000000000000000000000000000000000000000"; then
            echo -e "${RED}✗ Topic does not exist${NC}"
            exit 1
        fi
        
        echo -e "${RED}⚠️  WARNING: This will remove the claim topic!${NC}"
        echo "  This may affect token compliance requirements."
        echo ""
        read -p "  Continue? (yes/no): " CONFIRM
        
        if [ "$CONFIRM" != "yes" ]; then
            echo "  Cancelled."
            exit 0
        fi
        
        # Remove topic
        TX=$(cast send "$REGISTRY" \
            "removeClaimTopic(uint256)" \
            "$TOPIC" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY" \
            2>&1)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Claim topic removed successfully${NC}"
            echo ""
            # Extract transaction hash
            TX_HASH=$(echo "$TX" | grep "transactionHash" | awk '{print $2}')
            if [ -n "$TX_HASH" ]; then
                echo "  Transaction: $TX_HASH"
            fi
        else
            echo -e "${RED}✗ Error removing topic${NC}"
            echo "$TX"
            exit 1
        fi
        ;;
        
    exists)
        TOPIC="${3:-}"
        if [ -z "$TOPIC" ]; then
            echo -e "${RED}✗ Error: Topic ID required${NC}"
            show_usage
        fi
        
        TOPIC_NAME=$(get_topic_name "$TOPIC")
        
        echo -e "${YELLOW}Checking if topic exists: $TOPIC ($TOPIC_NAME)${NC}"
        echo ""
        
        EXISTS=$(cast call "$REGISTRY" "claimTopicExists(uint256)" "$TOPIC" --rpc-url "$RPC_URL" 2>&1)
        
        if echo "$EXISTS" | grep -q "0x0000000000000000000000000000000000000000000000000000000000000001"; then
            echo -e "${GREEN}✓ Topic exists${NC}"
            exit 0
        else
            echo -e "${YELLOW}✗ Topic does not exist${NC}"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}✗ Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"

