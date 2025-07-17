# Token List Processor

This bash script processes token URLs and automatically updates Uniswap token lists by fetching token data from the Uniswap API.

## Features

- Parses token URLs to extract chain and address information
- Validates Ethereum addresses and converts them to checksummed format
- Fetches token metadata (name, symbol, decimals) from Uniswap GraphQL API
- Updates JSON token list files with new tokens
- Supports multiple token list types (default, extended, unsupported)
- Handles errors gracefully with colored output
- Skips duplicate tokens automatically

## Prerequisites

1. **Node.js and npm** - Required for ethers.js address validation
2. **jq** - Required for JSON processing
   - macOS: `brew install jq`
   - Ubuntu: `sudo apt-get install jq`
3. **curl** - Usually pre-installed on most systems
4. **Git repositories** - The target token list repositories must be cloned locally

## Installation

1. Make sure you have the required dependencies installed
2. Clone the token list repositories you want to work with:

```bash
git clone git@github.com:Uniswap/default-token-list.git
git clone git@github.com:Uniswap/extended-token-list.git
git clone git@github.com:Uniswap/unsupported-token-list.git
```

3. Make the script executable:
```bash
chmod +x process_tokens.sh
```

## Usage

### Basic Usage

```bash
./process_tokens.sh <input_file> [list_type]
```

### Parameters

- `input_file`: Path to a text file containing token URLs (one per line)
- `list_type`: (Optional) Target token list type - `default`, `extended`, or `unsupported` (default: `default`)

### Input File Format

The input file should contain one token URL per line in the format:
```
https://app.uniswap.org/token/<chain>/<address>
```

Example (`sample_tokens.txt`):
```
# USDC on Ethereum
https://app.uniswap.org/token/ethereum/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

# USDT on Ethereum
https://app.uniswap.org/token/ethereum/0xdAC17F958D2ee523a2206206994597C13D831ec7

# WETH on Polygon
https://app.uniswap.org/token/polygon/0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
```

### Examples

Process tokens for the default list:
```bash
./process_tokens.sh sample_tokens.txt
```

Process tokens for the extended list:
```bash
./process_tokens.sh sample_tokens.txt extended
```

Process tokens for the unsupported list:
```bash
./process_tokens.sh sample_tokens.txt unsupported
```

## Supported Chains

The script supports the following blockchain networks:

- **Ethereum/Mainnet** (`ethereum`, `mainnet`) - Chain ID: 1
- **Arbitrum** (`arbitrum`) - Chain ID: 42161
- **Avalanche** (`avalanche`) - Chain ID: 43114
- **Base** (`base`) - Chain ID: 8453
- **Binance Smart Chain** (`binance`, `bnb`) - Chain ID: 56
- **Celo** (`celo`) - Chain ID: 42220
- **Optimism** (`optimism`) - Chain ID: 10
- **Polygon** (`polygon`) - Chain ID: 137

## How It Works

1. **URL Parsing**: Extracts chain name and token address from Uniswap URLs
2. **Address Validation**: Validates the Ethereum address format and converts to checksummed format
3. **API Fetching**: Queries the Uniswap GraphQL API to get token metadata
4. **File Updates**: Adds the new token to the appropriate JSON file in the token list repository
5. **Duplicate Detection**: Checks if the token already exists before adding

## Output

The script provides colored output with different message types:

- 🟢 **INFO** (Green): Successful operations and status updates
- 🟡 **WARNING** (Yellow): Non-critical issues (e.g., duplicate tokens)
- 🔴 **ERROR** (Red): Critical errors that prevent processing

## Error Handling

The script handles various error conditions:

- Invalid URL format
- Invalid Ethereum addresses
- Unsupported blockchain chains
- API errors from Uniswap
- Missing token list files
- Duplicate tokens (skipped with warning)

## File Structure

After processing, tokens are added to the appropriate JSON files:

```
<list_type>-token-list/
└── src/
    └── tokens/
        ├── ethereum.json
        ├── polygon.json
        ├── arbitrum.json
        └── ...
```

## Token Object Format

Each token is added with the following structure:

```json
{
  "chainId": 1,
  "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  "name": "USD Coin",
  "symbol": "USDC",
  "decimals": 6,
  "logoURI": ""
}
```

## Notes

- The script does not handle Git operations (commits, pushes, pull requests)
- Logo URLs are left empty and need to be added manually if required
- The script processes tokens sequentially and continues even if some fail
- All operations are logged with timestamps and status information 