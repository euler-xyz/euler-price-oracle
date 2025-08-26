#!/bin/bash

# Euler Price Oracle Adapter Verification Script
# This script verifies an already deployed oracle adapter by extracting constructor arguments
# from the deployment transaction and then verifying the contract

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        print_error "File not found: $1"
        exit 1
    fi
}

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        print_error "Directory not found: $1"
        exit 1
    fi
}

# Function to load environment variables
load_env() {
    local env_file="../evk-periphery/.env"
    check_file "$env_file"
    
    # Source the environment file
    set -a
    source "$env_file"
    set +a
}

# Function to get RPC URL and chain ID
get_rpc_url_and_chain_id() {
    local input="$1"
    local rpc_url=""
    local extracted_chain_id=""
    
    # Check if input looks like a URL
    if [[ "$input" =~ ^https?:// ]]; then
        # Input is a URL, use it directly and extract chain ID
        rpc_url="$input"
        
        # Extract chain ID using cast
        if command -v cast >/dev/null 2>&1; then
            extracted_chain_id=$(cast chain-id --rpc-url "$rpc_url" 2>/dev/null)
            
            if [ -z "$extracted_chain_id" ] || [ "$extracted_chain_id" = "null" ]; then
                print_error "Failed to extract chain ID from RPC URL"
                exit 1
            fi
        else
            print_error "cast command not found. Please install foundry to extract chain ID from RPC URL"
            exit 1
        fi
    else
        # Input is a chain ID, get RPC URL from environment
        extracted_chain_id="$input"
        
        # Validate chain ID is numeric
        if ! [[ "$extracted_chain_id" =~ ^[0-9]+$ ]]; then
            print_error "Chain ID must be a number when not providing a full RPC URL"
            exit 1
        fi
        
        local env_var="DEPLOYMENT_RPC_URL_$extracted_chain_id"
        rpc_url="${!env_var}"
        
        if [ -z "$rpc_url" ]; then
            print_error "RPC URL not found for chain ID $extracted_chain_id. Check if $env_var is set in ../evk-periphery/.env"
            exit 1
        fi
    fi
    
    # Return both values in a format we can parse
    echo "$rpc_url|$extracted_chain_id"
}

# Function to get verifier URL
get_verifier_url() {
    local chain_id="$1"
    local env_var="VERIFIER_URL_$chain_id"
    local verifier_url="${!env_var}"
    
    if [ -z "$verifier_url" ]; then
        print_error "Verifier URL not found for chain ID $chain_id. Check if $env_var is set in .env"
        exit 1
    fi
    
    echo "$verifier_url"
}

# Function to get verifier API key
get_verifier_api_key() {
    local chain_id="$1"
    local env_var="VERIFIER_API_KEY_$chain_id"
    local api_key="${!env_var}"
    
    if [ -z "$api_key" ]; then
        print_error "Verifier API key not found for chain ID $chain_id. Check if $env_var is set in .env"
        exit 1
    fi
    
    echo "$api_key"
}

# Function to get adapter constructor signature and arguments
get_adapter_constructor_info() {
    local adapter_name="$1"
    
    case "$adapter_name" in
        "PythOracle")
            echo "constructor(address,address,address,bytes32,uint256,uint256)|_pyth,_base,_quote,_feedId,_maxStaleness,_maxConfWidth"
            ;;
        "ChainlinkOracle"|"ChainlinkInfrequentOracle")
            echo "constructor(address,address,address,uint256)|_base,_quote,_feed,_maxStaleness"
            ;;
        "ChronicleOracle")
            echo "constructor(address,address,address,uint256)|_base,_quote,_feed,_maxStaleness"
            ;;
        "CurveEMAOracle")
            echo "constructor(address,address,uint256)|_pool,_base,_priceOracleIndex"
            ;;
        "FixedRateOracle")
            echo "constructor(address,address,uint256)|_base,_quote,_rate"
            ;;
        "IdleTranchesOracle")
            echo "constructor(address,address)|_cdo,_tranche"
            ;;
        "LidoOracle")
            echo "constructor()|"
            ;;
        "OndoOracle")
            echo "constructor(address,address,address)|_base,_quote,_rwaOracle"
            ;;
        "PendleOracle"|"PendleUniversalOracle")
            echo "constructor(address,address,address,address,uint32)|_pendleOracle,_pendleMarket,_base,_quote,_twapWindow"
            ;;
        "RateProviderOracle")
            echo "constructor(address,address,address)|_base,_quote,_rateProvider"
            ;;
        "RedstoneCoreOracle")
            echo "constructor(address,address,bytes32,uint8,uint256)|_base,_quote,_feedId,_feedDecimals,_maxStaleness"
            ;;
        "UniswapV3Oracle")
            echo "constructor(address,address,uint24,uint32,address)|_tokenA,_tokenB,_fee,_twapWindow,_uniswapV3Factory"
            ;;
        "CrossAdapter")
            echo "constructor(address,address,address,address,address)|_base,_cross,_quote,_oracleBaseCross,_oracleCrossQuote"
            ;;
        *)
            print_error "Unknown adapter name: $adapter_name"
            print_info "Supported adapters:"
            print_info "  - PythOracle"
            print_info "  - ChainlinkOracle"
            print_info "  - ChainlinkInfrequentOracle"
            print_info "  - ChronicleOracle"
            print_info "  - CurveEMAOracle"
            print_info "  - FixedRateOracle"
            print_info "  - IdleTranchesOracle"
            print_info "  - LidoOracle"
            print_info "  - OndoOracle"
            print_info "  - PendleOracle"
            print_info "  - PendleUniversalOracle"
            print_info "  - RateProviderOracle"
            print_info "  - RedstoneCoreOracle"
            print_info "  - UniswapV3Oracle"
            print_info "  - CrossAdapter"
            exit 1
            ;;
    esac
}

# Function to get adapter contract path
get_adapter_contract_path() {
    local adapter_name="$1"
    
    case "$adapter_name" in
        "PythOracle")
            echo "src/adapter/pyth/PythOracle.sol:PythOracle"
            ;;
        "ChainlinkOracle")
            echo "src/adapter/chainlink/ChainlinkOracle.sol:ChainlinkOracle"
            ;;
        "ChainlinkInfrequentOracle")
            echo "src/adapter/chainlink/ChainlinkInfrequentOracle.sol:ChainlinkInfrequentOracle"
            ;;
        "ChronicleOracle")
            echo "src/adapter/chronicle/ChronicleOracle.sol:ChronicleOracle"
            ;;
        "CurveEMAOracle")
            echo "src/adapter/curve/CurveEMAOracle.sol:CurveEMAOracle"
            ;;
        "FixedRateOracle")
            echo "src/adapter/fixed/FixedRateOracle.sol:FixedRateOracle"
            ;;
        "IdleTranchesOracle")
            echo "src/adapter/idle/IdleTranchesOracle.sol:IdleTranchesOracle"
            ;;
        "LidoOracle")
            echo "src/adapter/lido/LidoOracle.sol:LidoOracle"
            ;;
        "OndoOracle")
            echo "src/adapter/ondo/OndoOracle.sol:OndoOracle"
            ;;
        "PendleOracle")
            echo "src/adapter/pendle/PendleOracle.sol:PendleOracle"
            ;;
        "PendleUniversalOracle")
            echo "src/adapter/pendle/PendleUniversalOracle.sol:PendleUniversalOracle"
            ;;
        "RateProviderOracle")
            echo "src/adapter/rate/RateProviderOracle.sol:RateProviderOracle"
            ;;
        "RedstoneCoreOracle")
            echo "src/adapter/redstone/RedstoneCoreOracle.sol:RedstoneCoreOracle"
            ;;
        "UniswapV3Oracle")
            echo "src/adapter/uniswap/UniswapV3Oracle.sol:UniswapV3Oracle"
            ;;
        "CrossAdapter")
            echo "src/adapter/CrossAdapter.sol:CrossAdapter"
            ;;
        *)
            print_error "Unknown adapter name: $adapter_name"
            exit 1
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 --tx-hash TX_HASH --adapter-address ADAPTER_ADDRESS --adapter-name ADAPTER_NAME --rpc-url CHAIN_ID_OR_URL [--verifier VERIFIER_TYPE]"
    echo
    echo "Options:"
    echo "  --tx-hash TX_HASH        Deployment transaction hash"
    echo "  --adapter-address ADDRESS  Deployed adapter contract address"
    echo "  --adapter-name NAME      Name of the adapter (e.g., PythOracle, ChainlinkOracle)"
    echo "  --rpc-url CHAIN_ID_OR_URL  Chain ID (numeric) or full RPC URL"
    echo "  --verifier TYPE          Verifier type (default: etherscan)"
    echo "                           Supported: etherscan, blockscout, sourcify, custom"
    echo "  -h, --help              Show this help message"
    echo
    echo "Description:"
    echo "  Verifies an already deployed oracle adapter by extracting constructor arguments"
    echo "  from the deployment transaction and then verifying the contract."
    echo
    echo "Supported Adapters:"
    echo "  - PythOracle"
    echo "  - ChainlinkOracle"
    echo "  - ChainlinkInfrequentOracle"
    echo "  - ChronicleOracle"
    echo "  - CurveEMAOracle"
    echo "  - FixedRateOracle"
    echo "  - IdleTranchesOracle"
    echo "  - LidoOracle"
    echo "  - OndoOracle"
    echo "  - PendleOracle"
    echo "  - PendleUniversalOracle"
    echo "  - RateProviderOracle"
    echo "  - RedstoneCoreOracle"
    echo "  - UniswapV3Oracle"
    echo "  - CrossAdapter"
    echo
    echo "Examples:"
    echo "  $0 --tx-hash 0x1234... --adapter-address 0xabcd... --adapter-name PythOracle --rpc-url 10 --verifier etherscan"
    echo "  $0 --tx-hash 0x1234... --adapter-address 0xabcd... --adapter-name ChainlinkOracle --rpc-url https://rpc.example.com --verifier blockscout"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tx-hash)
                tx_hash="$2"
                shift 2
                ;;
            --adapter-address)
                adapter_address="$2"
                shift 2
                ;;
            --adapter-name)
                adapter_name="$2"
                shift 2
                ;;
            --rpc-url)
                chain_id="$2"
                shift 2
                ;;
            --verifier)
                verifier_type="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$tx_hash" ]; then
        print_error "Missing required argument: --tx-hash"
        show_usage
        exit 1
    fi
    
    if [ -z "$adapter_address" ]; then
        print_error "Missing required argument: --adapter-address"
        show_usage
        exit 1
    fi
    
    if [ -z "$adapter_name" ]; then
        print_error "Missing required argument: --adapter-name"
        show_usage
        exit 1
    fi
    
    if [ -z "$chain_id" ]; then
        print_error "Missing required argument: --rpc-url"
        show_usage
        exit 1
    fi
    
    # Validate chain ID is numeric (only if it's not a URL)
    if ! [[ "$chain_id" =~ ^[0-9]+$ ]] && ! [[ "$chain_id" =~ ^https?:// ]]; then
        print_error "Chain ID must be a number when not providing a full RPC URL"
        exit 1
    fi
    
    # Set default verifier type if not provided
    verifier_type=${verifier_type:-etherscan}
}

# Main script
main() {
    print_info "Euler Price Oracle Adapter Verification Script"
    echo
    
    # Parse command line arguments
    parse_args "$@"
    
    # Check if we're in the right directory
    if [ ! -f "foundry.toml" ]; then
        print_error "This script must be run from the euler-price-oracle directory (where foundry.toml is located)"
        exit 1
    fi
    
    # Load environment variables
    print_info "Loading environment variables..."
    load_env
    print_success "Environment variables loaded"
    
    print_info "Using transaction hash: $tx_hash"
    print_info "Using adapter address: $adapter_address"
    print_info "Using adapter name: $adapter_name"
    print_info "Using chain ID: $chain_id"
    print_info "Using verifier: $verifier_type"
    echo
    
    # Get all required values
    print_info "Getting RPC URL and chain ID..."
    local result=$(get_rpc_url_and_chain_id "$chain_id")
    rpc_url=$(echo "$result" | cut -d'|' -f1)
    chain_id=$(echo "$result" | cut -d'|' -f2)
    print_success "RPC URL: $rpc_url"
    print_success "Chain ID: $chain_id"
    
    print_info "Getting verifier URL for chain $chain_id..."
    verifier_url=$(get_verifier_url "$chain_id")
    print_success "Verifier URL: $verifier_url"
    
    # Only get API key if the verifier type needs it
    if [[ $verifier_type == "blockscout" || $verifier_type == "sourcify" || $verifier_type == "custom" ]]; then
        print_info "Skipping API key retrieval for $verifier_type verifier"
        verifier_api_key=""
    else
        print_info "Getting verifier API key for chain $chain_id..."
        verifier_api_key=$(get_verifier_api_key "$chain_id")
        print_success "Verifier API key: ***${verifier_api_key: -4}"
    fi
    
    # Get adapter constructor information
    print_info "Getting constructor information for $adapter_name..."
    local constructor_info=$(get_adapter_constructor_info "$adapter_name")
    local constructor_signature=$(echo "$constructor_info" | cut -d'|' -f1)
    local constructor_params=$(echo "$constructor_info" | cut -d'|' -f2)
    
    print_success "Constructor signature: $constructor_signature"
    print_success "Constructor parameters: $constructor_params"
    
    # Get adapter contract path
    print_info "Getting contract path for $adapter_name..."
    local contract_path=$(get_adapter_contract_path "$adapter_name")
    print_success "Contract path: $contract_path"
    
    echo
    
    # Extract constructor arguments from the transaction
    print_info "Extracting transaction data for tx: $tx_hash"
    
    # Get transaction data using cast tx
    local tx_data=$(cast tx "$tx_hash" --rpc-url "$rpc_url" --json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        print_error "Failed to get transaction data for tx: $tx_hash"
        exit 1
    fi
    
    # Extract the input data from the transaction
    local input_data=$(echo "$tx_data" | jq -r '.input' 2>/dev/null)
    
    if [ -z "$input_data" ] || [ "$input_data" = "null" ]; then
        print_error "Failed to extract input data from transaction"
        exit 1
    fi
    
    print_info "Extracted input data: $input_data"
    
    # Check if this is a contract creation transaction
    local to_address=$(echo "$tx_data" | jq -r '.to' 2>/dev/null)
    
    if [ "$to_address" != "null" ] && [ -n "$to_address" ]; then
        print_error "This transaction is not a contract creation transaction (has 'to' address: $to_address)"
        print_error "Please provide the transaction hash of the contract creation transaction"
        exit 1
    fi
    
    # For contract creation, the input data contains the constructor arguments
    # We need to remove the constructor bytecode (first part) to get just the arguments
    # This is more complex and depends on the specific deployment pattern
    
    print_warning "Contract creation transaction detected. Constructor argument extraction may require manual analysis."
    print_info "The input data contains both constructor bytecode and arguments."
    print_info "You may need to manually extract the constructor arguments from the deployment transaction."
    
    # For now, we'll try to decode using the constructor signature
    # But this may not work if the deployment includes additional data
    print_info "Attempting to decode constructor arguments using signature: $constructor_signature"
    
    # Try to decode the input data as constructor arguments
    local decoded_data=""
    if [ -n "$constructor_params" ]; then
        # Try to decode using cast decode-abi
        decoded_data=$(cast decode-abi --input "$constructor_signature" "$input_data" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            print_warning "Failed to decode constructor arguments automatically."
            print_info "This may be due to additional deployment data or different encoding."
            print_info "You may need to manually extract the constructor arguments."
            
            # Show the raw input data for manual analysis
            print_info "Raw input data for manual analysis:"
            echo "$input_data"
            
            # Ask user if they want to continue with manual input
            read -p "Do you want to manually input the constructor arguments? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Please provide the constructor arguments in the correct order:"
                echo "$constructor_params"
                read -p "Enter constructor arguments (space-separated): " constructor_args_input
                
                if [ -n "$constructor_args_input" ]; then
                    # Encode the constructor arguments
                    local constructor_args_encoded=$(cast abi-encode "$constructor_signature" $constructor_args_input 2>/dev/null)
                    
                    if [ $? -eq 0 ]; then
                        print_success "Successfully encoded constructor arguments: $constructor_args_encoded"
                        decoded_data="$constructor_args_input"
                    else
                        print_error "Failed to encode constructor arguments"
                        exit 1
                    fi
                else
                    print_error "No constructor arguments provided"
                    exit 1
                fi
            else
                print_error "Cannot proceed without constructor arguments"
                exit 1
            fi
        fi
    else
        # No constructor parameters (like LidoOracle)
        print_success "No constructor arguments needed for $adapter_name"
        decoded_data=""
    fi
    
    if [ -n "$decoded_data" ]; then
        print_success "Successfully extracted constructor parameters:"
        echo "$decoded_data"
    fi
    
    echo
    
    # Build verifier arguments based on verifier type
    local verifier_args="--verifier-url $verifier_url"
    
    if [[ $verifier_type == "blockscout" ]]; then
        verifier_args="$verifier_args --verifier-api-key \"\" --verifier=blockscout"
    elif [[ $verifier_type == "sourcify" ]]; then
        verifier_args="$verifier_args --verifier=$verifier_type --retries 1"
    elif [[ $verifier_type == "custom" ]]; then
        verifier_args="$verifier_args --verifier=$verifier_type"
    else
        # Default to etherscan and other verifiers that need API key
        verifier_args="$verifier_args --verifier-api-key $verifier_api_key --verifier=etherscan"
    fi
    
    # Verify the contract using forge verify-contract
    print_info "Verifying $adapter_name contract..."
    
    # Build the forge verify command
    local verify_cmd="forge verify-contract $adapter_address $contract_path \
        --chain $chain_id \
        --rpc-url $rpc_url \
        --watch \
        $verifier_args"
    
    # Add constructor arguments if they exist
    if [ -n "$decoded_data" ] && [ -n "$constructor_args_input" ]; then
        verify_cmd="$verify_cmd --constructor-args $constructor_args_input"
    fi
    
    print_info "Executing forge verify command..."
    echo
    
    # Execute the verification
    local temp_output=$(mktemp)
    local exit_code=0
    
    eval "$verify_cmd" 2>&1 | tee "$temp_output"
    exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        print_success "Contract verification completed successfully!"
        
        # Check if verification was successful
        if grep -q "Successfully verified" "$temp_output" || grep -q "Contract is already verified" "$temp_output"; then
            print_success "$adapter_name at $adapter_address has been verified on chain $chain_id!"
        else
            print_warning "Verification command completed but success message not found in output"
            print_info "Please check the output above for verification status"
        fi
    else
        print_error "Contract verification failed with exit code $exit_code!"
        print_info "Please check the output above for error details"
        rm -f "$temp_output"
        exit $exit_code
    fi
    
    rm -f "$temp_output"
    
    print_success "Verification process completed!"
    print_info "Adapter address: $adapter_address"
    print_info "Adapter name: $adapter_name"
    print_info "Chain ID: $chain_id"
    print_info "Transaction hash: $tx_hash"
}

# Run main function
main "$@" 