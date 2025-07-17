#!/bin/bash

# Script to count changes in token_changes JSON files
# Usage: ./count_changes.sh [filename_pattern]

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

# Function to count changes in a single file
count_changes_in_file() {
    local file=$1
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Check if it's a valid JSON file
    if ! jq empty "$file" 2>/dev/null; then
        print_error "Invalid JSON file: $file"
        return 1
    fi
    
    print_status "Analyzing: $file"
    
    # Get total number of tokens across all chains
    local total_tokens=$(jq 'reduce (.[] | length) as $count (0; . + $count)' "$file")
    
    # Get number of chains
    local num_chains=$(jq 'length' "$file")
    
    # Get breakdown by chain
    echo "  Total tokens: $total_tokens"
    echo "  Number of chains: $num_chains"
    echo "  Breakdown by chain:"
    
    # Show breakdown for each chain
    jq -r 'to_entries[] | "    \(.key): \(.value | length) tokens"' "$file"
    
    # Show sample tokens (first 3 from each chain)
    echo "  Sample tokens:"
    jq -r 'to_entries[] | "    \(.key):" + (.value[0:3] | map(" \(.symbol) (\(.address[0:10])...)") | join(""))' "$file" 2>/dev/null || echo "    (No tokens found)"
    
    echo
}

# Function to find and process files
process_files() {
    local pattern=${1:-"token_changes_*.json"}
    
    print_status "Looking for files matching pattern: $pattern"
    
    # Find all matching files
    local files=($(find . -name "$pattern" -type f 2>/dev/null | sort))
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_warning "No files found matching pattern: $pattern"
        return 1
    fi
    
    print_status "Found ${#files[@]} file(s):"
    for file in "${files[@]}"; do
        echo "  - $file"
    done
    echo
    
    # Process each file
    local total_files=0
    local total_tokens=0
    
    for file in "${files[@]}"; do
        if count_changes_in_file "$file"; then
            total_files=$((total_files + 1))
            local file_tokens=$(jq 'reduce (.[] | length) as $count (0; . + $count)' "$file" 2>/dev/null || echo "0")
            total_tokens=$((total_tokens + file_tokens))
        fi
    done
    
    # Show summary
    echo "========================================"
    print_status "SUMMARY"
    echo "========================================"
    print_status "Total files processed: $total_files"
    print_status "Total tokens across all files: $total_tokens"
    echo
}

# Function to show detailed statistics
show_detailed_stats() {
    local pattern=${1:-"token_changes_*.json"}
    
    print_status "Generating detailed statistics..."
    
    # Find all matching files
    local files=($(find . -name "$pattern" -type f 2>/dev/null | sort))
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_warning "No files found for detailed analysis"
        return 1
    fi
    
    # Combine all data for analysis
    local combined_data="{}"
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]] && jq empty "$file" 2>/dev/null; then
            # Merge data from this file into combined data
            combined_data=$(echo "$combined_data" | jq -s '.[0] * .[1]' - "$file")
        fi
    done
    
    # Analyze combined data
    echo "========================================"
    print_status "DETAILED STATISTICS"
    echo "========================================"
    
    # Total unique tokens by chain
    echo "Total unique tokens by chain:"
    echo "$combined_data" | jq -r 'to_entries[] | "  \(.key): \(.value | length) tokens"'
    
    # Most common symbols
    echo
    echo "Most common token symbols:"
    echo "$combined_data" | jq -r '.[] | .[] | .symbol' | sort | uniq -c | sort -nr | head -10 | awk '{print "  " $2 ": " $1 " occurrences"}'
    
    # Token distribution by decimals
    echo
    echo "Token distribution by decimals:"
    echo "$combined_data" | jq -r '.[] | .[] | .decimals' | sort | uniq -c | sort -k2n | awk '{print "  " $2 " decimals: " $1 " tokens"}'
    
    # Chain distribution
    echo
    echo "Chain distribution:"
    echo "$combined_data" | jq -r 'keys[]' | sort | uniq -c | sort -nr | awk '{print "  " $2 ": " $1 " files contain this chain"}'
    
    echo
}

# Main script
main() {
    local pattern=$1
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        echo "Install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        exit 1
    fi
    
    # If no pattern provided, use default
    if [[ -z "$pattern" ]]; then
        pattern="token_changes_*.json"
    fi
    
    print_status "Token Changes Counter"
    echo "========================================"
    
    # Process files
    if process_files "$pattern"; then
        # Show detailed statistics if requested
        if [[ "$2" == "--detailed" ]]; then
            show_detailed_stats "$pattern"
        fi
    else
        print_error "No files found or processing failed"
        exit 1
    fi
}

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [filename_pattern] [--detailed]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Count all token_changes_*.json files"
    echo "  $0 token_changes_unsupported_*.json   # Count specific pattern"
    echo "  $0 --detailed                        # Show detailed statistics"
    echo "  $0 token_changes_*.json --detailed   # Count with detailed stats"
    echo ""
    echo "The script will:"
    echo "  - Find all JSON files matching the pattern"
    echo "  - Count tokens by chain for each file"
    echo "  - Show total summary across all files"
    echo "  - Optionally show detailed statistics"
    exit 0
fi

# Run main function with all arguments
main "$@" 