#!/bin/bash

# Script to process token URLs and update token lists
# Usage: ./process_tokens.sh <input_file>
# Input file should contain one URL per line in format: https://app.uniswap.org/token/<chain>/<address>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get chain ID from name
get_chain_id() {
    local chain_name=$1
    case $(echo "$chain_name" | tr '[:upper:]' '[:lower:]') in
        "ethereum"|"mainnet")
            echo "1"
            ;;
        "arbitrum")
            echo "42161"
            ;;
        "avalanche")
            echo "43114"
            ;;
        "base")
            echo "8453"
            ;;
        "binance"|"bnb")
            echo "56"
            ;;
        "celo")
            echo "42220"
            ;;
        "optimism")
            echo "10"
            ;;
        "polygon")
            echo "137"
            ;;
        "blast")
            echo "81457"
            ;;
        *)
            print_error "Unsupported chain: $chain_name"
            return 1
            ;;
    esac
}

# Function to get chain name from ID
get_chain_name() {
    local chain_id=$1
    case $chain_id in
        "1")
            echo "ethereum"
            ;;
        "42161")
            echo "arbitrum"
            ;;
        "43114")
            echo "avalanche"
            ;;
        "8453")
            echo "base"
            ;;
        "56")
            echo "binance"
            ;;
        "42220")
            echo "celo"
            ;;
        "10")
            echo "optimism"
            ;;
        "137")
            echo "polygon"
            ;;
        *)
            print_error "Unsupported chain ID: $chain_id"
            return 1
            ;;
    esac
}

# Function to validate Ethereum address
validate_address() {
    local address=$1
    if [[ ! $address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        print_error "Invalid Ethereum address format: $address"
        return 1
    fi
    return 0
}

# Function to get checksummed address using ethers.js
get_checksum_address() {
    local address=$1
    node -e "
        const { ethers } = require('ethers');
        try {
            console.log(ethers.getAddress('$address'));
        } catch (e) {
            console.error('Invalid address: $address');
            process.exit(1);
        }
    "
}

# Function to fetch token data from Uniswap API
fetch_token_data() {
    local chain=$1
    local address=$2
    
    # Convert chain name to uppercase for API
    local chain_upper=$(echo "$chain" | tr '[:lower:]' '[:upper:]')
    
    local query='{
        "query": "query Token($chain: Chain!, $address: String = null) { token(chain: $chain, address: $address) { address symbol decimals name } }",
        "variables": {
            "chain": "'$chain_upper'",
            "address": "'$address'"
        }
    }'
    
    local response=$(curl -s -X POST \
        -H "accept: */*" \
        -H "content-type: application/json" \
        -H "origin: https://app.uniswap.org" \
        -d "$query" \
        https://api.uniswap.org/v1/graphql)
    
    echo "$response"
}

# Function to parse URL and extract chain and address
parse_url() {
    local url=$1
    
    # Extract chain and address from URL pattern: https://app.uniswap.org/token/<chain>/<address>
    if [[ $url =~ https://app\.uniswap\.org/explore/tokens/([^/]+)/([^/]+)$ ]]; then
        local chain="${BASH_REMATCH[1]}"
        local address="${BASH_REMATCH[2]}"
        echo "$chain:$address"
    else
        print_error "Invalid URL format: $url"
        return 1
    fi
}

# Function to update token list file
update_token_list() {
    local list_type=$1
    local chain_name=$2
    local token_data=$3
    
    local list_dir="${list_type}-token-list"
    local json_file="${list_dir}/src/tokens/${chain_name}.json"
    
    # Parse token data
    local address=$(echo "$token_data" | jq -r '.address')
    local name=$(echo "$token_data" | jq -r '.name')
    local symbol=$(echo "$token_data" | jq -r '.symbol')
    local decimals=$(echo "$token_data" | jq -r '.decimals')
    local chain_id=$(get_chain_id "$chain_name")
    
    # Create new token object
    local new_token=$(jq -n \
        --arg address "$address" \
        --arg name "$name" \
        --arg symbol "$symbol" \
        --arg decimals "$decimals" \
        --arg chainId "$chain_id" \
        --arg logoURI "" \
        '{
            chainId: ($chainId | tonumber),
            address: $address,
            name: $name,
            symbol: $symbol,
            decimals: ($decimals | tonumber),
            logoURI: $logoURI
        }')
    
    # Check if token already exists (only if file exists)
    if [[ -f "$json_file" ]]; then
        local exists=$(jq --arg addr "$address" 'any(.address == $addr)' "$json_file")
        
        if [[ "$exists" == "true" ]]; then
            print_warning "Token $address already exists in $json_file"
            # Still return success but don't add to file
            return 0
        fi
        
        # Add new token to the list
        jq --argjson new_token "$new_token" '. += [$new_token]' "$json_file" > "${json_file}.tmp"
        mv "${json_file}.tmp" "$json_file"
        
        print_status "Added token $name ($symbol) to $json_file"
    else
        print_warning "Token list file not found: $json_file (skipping file update)"
    fi
    
    # Always return success for JSON output generation
    return 0
}

# Main processing function
process_token() {
    local url=$1
    local list_type=${2:-"default"}
    local output_file=$3
    
    print_status "Processing URL: $url"
    
    # Parse URL
    local parsed=$(parse_url "$url")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local chain=$(echo "$parsed" | cut -d: -f1)
    local address=$(echo "$parsed" | cut -d: -f2)
    
    print_status "Chain: $chain, Address: $address"
    
    # Validate address
    if ! validate_address "$address"; then
        return 1
    fi
    
    # Get checksummed address
    local checksummed_address
    checksummed_address=$(get_checksum_address "$address")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    print_status "Checksummed address: $checksummed_address"
    
    # Fetch token data
    print_status "Fetching token data from Uniswap API..."
    local token_response=$(fetch_token_data "$chain" "$checksummed_address")
    
    # Check for API errors
    if echo "$token_response" | jq -e '.errors' > /dev/null 2>&1; then
        print_error "API error: $(echo "$token_response" | jq -r '.errors[0].message')"
        return 1
    fi
    
    local token_data=$(echo "$token_response" | jq -r '.data.token')
    
    # Check if token data is valid
    if [[ "$token_data" == "null" ]]; then
        print_error "Token not found on chain $chain"
        return 1
    fi
    
    print_status "Token data: $(echo "$token_data" | jq -r '.name + " (" + .symbol + ")"')"
    
    # Update token list (this will handle file updates)
    update_token_list "$list_type" "$chain" "$token_data"
    
    # Always add to output JSON, regardless of whether it was added to the file
    local chain_id=$(get_chain_id "$chain")
    local name=$(echo "$token_data" | jq -r '.name')
    local symbol=$(echo "$token_data" | jq -r '.symbol')
    local decimals=$(echo "$token_data" | jq -r '.decimals')
    
    # Create change object
    local change_obj=$(jq -n \
        --arg address "$checksummed_address" \
        --arg name "$name" \
        --arg symbol "$symbol" \
        --arg decimals "$decimals" \
        --arg chainId "$chain_id" \
        '{
            address: $address,
            name: $name,
            symbol: $symbol,
            decimals: ($decimals | tonumber),
            chainId: ($chainId | tonumber),
            logoURI: ""
        }')
    
    # Add to output file
    if [[ -f "$output_file" ]]; then
        # File exists, add to existing chain or create new chain
        if jq -e ".$chain" "$output_file" > /dev/null 2>&1; then
            # Chain exists, append to it
            jq --arg chain "$chain" --argjson change "$change_obj" '.[$chain] += [$change]' "$output_file" > "${output_file}.tmp"
            mv "${output_file}.tmp" "$output_file"
        else
            # Chain doesn't exist, create it
            jq --arg chain "$chain" --argjson change "$change_obj" '.[$chain] = [$change]' "$output_file" > "${output_file}.tmp"
            mv "${output_file}.tmp" "$output_file"
        fi
    else
        # File doesn't exist, create it
        jq -n --arg chain "$chain" --argjson change "$change_obj" '.[$chain] = [$change]' > "$output_file"
    fi
    
    return 0
}

# Main script
main() {
    local input_file=$1
    local list_type=${2:-"default"}
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        print_error "Input file not found: $input_file"
        echo "Usage: $0 <input_file> [list_type]"
        echo "  list_type: default, extended, or unsupported (default: default)"
        exit 1
    fi
    
    # Validate list type
    case $list_type in
        "default"|"extended"|"unsupported")
            ;;
        *)
            print_error "Invalid list type: $list_type"
            echo "Valid list types: default, extended, unsupported"
            exit 1
            ;;
    esac
    
    print_status "Processing tokens from file: $input_file"
    print_status "Target list type: $list_type"
    

    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        echo "Install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        exit 1
    fi
    
    # Create output file name
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local output_file="token_changes_${list_type}_${timestamp}.json"
    
    print_status "Output will be written to: $output_file"
    
    # Process each line in the input file
    local line_num=0
    local success_count=0
    local error_count=0
    local unprocessed_tokens=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        print_status "Processing line $line_num: $line"
        
        if process_token "$line" "$list_type" "$output_file"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
            unprocessed_tokens+=("$line")
        fi
        
        echo
    done < "$input_file"
    
    print_status "Processing complete!"
    print_status "Successfully processed: $success_count tokens"
    print_status "Changes written to: $output_file"
    
    if [[ $error_count -gt 0 ]]; then
        print_warning "Failed to process: $error_count tokens"
        echo
        print_warning "Unprocessed tokens:"
        for token in "${unprocessed_tokens[@]}"; do
            echo "  - $token"
        done
    fi
    
    # Show summary of changes
    if [[ -f "$output_file" ]]; then
        echo
        print_status "Summary of changes:"
        jq -r 'to_entries[] | "\(.key): \(.value | length) tokens"' "$output_file"
    fi
}

# Run main function with all arguments
main "$@" 