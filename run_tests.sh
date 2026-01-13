#!/bin/bash

# Integration Test Runner Script for Naija Property Connect
# This script provides convenient commands to run various test suites

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_info "Flutter version: $(flutter --version | head -n 1)"
}

# Function to run tests
run_tests() {
    local test_file=$1
    local test_name=$2
    
    print_info "Running $test_name..."
    if flutter test "$test_file"; then
        print_info "$test_name passed ✓"
        return 0
    else
        print_error "$test_name failed ✗"
        return 1
    fi
}

# Main script
main() {
    print_info "Naija Property Connect - Integration Test Runner"
    echo ""
    
    # Check Flutter installation
    check_flutter
    
    # Get dependencies
    print_info "Getting dependencies..."
    flutter pub get
    echo ""
    
    # Parse command line arguments
    case "${1:-all}" in
        all)
            print_info "Running all integration tests..."
            echo ""
            
            run_tests "integration_test/auth_integration_test.dart" "Authentication Tests"
            run_tests "integration_test/property_integration_test.dart" "Property Listing Tests"
            run_tests "integration_test/booking_integration_test.dart" "Booking Tests"
            run_tests "integration_test/chat_integration_test.dart" "Chat Tests"
            run_tests "integration_test/database_connection_test.dart" "Database Connection Tests"
            run_tests "integration_test/realtime_subscription_test.dart" "Realtime Subscription Tests"
            run_tests "integration_test/responsive_ui_test.dart" "Responsive UI Tests"
            
            print_info "All tests completed!"
            ;;
            
        auth)
            run_tests "integration_test/auth_integration_test.dart" "Authentication Tests"
            ;;
            
        property)
            run_tests "integration_test/property_integration_test.dart" "Property Listing Tests"
            ;;
            
        booking)
            run_tests "integration_test/booking_integration_test.dart" "Booking Tests"
            ;;
            
        chat)
            run_tests "integration_test/chat_integration_test.dart" "Chat Tests"
            ;;
            
        database)
            run_tests "integration_test/database_connection_test.dart" "Database Connection Tests"
            ;;
            
        realtime)
            run_tests "integration_test/realtime_subscription_test.dart" "Realtime Subscription Tests"
            ;;
            
        ui)
            run_tests "integration_test/responsive_ui_test.dart" "Responsive UI Tests"
            ;;
            
        help)
            echo "Usage: ./run_tests.sh [test_suite]"
            echo ""
            echo "Available test suites:"
            echo "  all       - Run all integration tests (default)"
            echo "  auth      - Run authentication tests"
            echo "  property  - Run property listing tests"
            echo "  booking   - Run booking tests"
            echo "  chat      - Run chat tests"
            echo "  database  - Run database connection tests"
            echo "  realtime  - Run realtime subscription tests"
            echo "  ui        - Run responsive UI tests"
            echo "  help      - Show this help message"
            ;;
            
        *)
            print_error "Unknown test suite: $1"
            echo "Run './run_tests.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
