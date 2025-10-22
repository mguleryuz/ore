#!/bin/bash

set -e

# Flag to track if .env needs configuration
ENV_NEEDS_CONFIG=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        echo -e "${RED}❌ Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
}

# Print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}         ORE Mining - Dependency Setup Script             ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Rust and Cargo
install_rust() {
    if command_exists rustc && command_exists cargo; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        print_success "Rust is already installed (version: $RUST_VERSION)"
        return 0
    fi

    print_warning "Rust is not installed. Installing..."
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source cargo env
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    if command_exists rustc && command_exists cargo; then
        print_success "Rust installed successfully"
    else
        print_error "Failed to install Rust. Please install manually from https://rustup.rs/"
        exit 1
    fi
}

# Install Solana CLI
install_solana() {
    if command_exists solana; then
        SOLANA_VERSION=$(solana --version | awk '{print $2}')
        print_success "Solana CLI is already installed (version: $SOLANA_VERSION)"
        return 0
    fi

    print_warning "Solana CLI is not installed. Installing..."
    
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    
    # Add to PATH
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    
    if command_exists solana; then
        print_success "Solana CLI installed successfully"
        print_info "You may need to add Solana to your PATH. Add this to your ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"\$HOME/.local/share/solana/install/active_release/bin:\$PATH\""
    else
        print_error "Failed to install Solana CLI. Please install manually from https://docs.solana.com/cli/install-solana-cli-tools"
        exit 1
    fi
}

# Install bc (basic calculator for bash)
install_bc() {
    if command_exists bc; then
        print_success "bc (calculator) is already installed"
        return 0
    fi

    print_warning "bc is not installed. Installing..."
    
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install bc
        else
            print_error "Homebrew is required but not installed. Please install from https://brew.sh/"
            exit 1
        fi
    elif [ "$OS" = "linux" ]; then
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y bc
        elif command_exists yum; then
            sudo yum install -y bc
        elif command_exists dnf; then
            sudo dnf install -y bc
        elif command_exists pacman; then
            sudo pacman -S --noconfirm bc
        else
            print_error "Could not determine package manager. Please install 'bc' manually."
            exit 1
        fi
    fi
    
    if command_exists bc; then
        print_success "bc installed successfully"
    else
        print_error "Failed to install bc"
        exit 1
    fi
}

# Install pkg-config (needed for Rust compilation)
install_pkg_config() {
    if command_exists pkg-config; then
        print_success "pkg-config is already installed"
        return 0
    fi

    print_warning "pkg-config is not installed. Installing..."
    
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install pkg-config
        else
            print_warning "Skipping pkg-config installation (Homebrew not found)"
            return 0
        fi
    elif [ "$OS" = "linux" ]; then
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y pkg-config
        elif command_exists yum; then
            sudo yum install -y pkgconfig
        elif command_exists dnf; then
            sudo dnf install -y pkgconfig
        elif command_exists pacman; then
            sudo pacman -S --noconfirm pkgconf
        fi
    fi
    
    if command_exists pkg-config; then
        print_success "pkg-config installed successfully"
    fi
}

# Install OpenSSL development libraries (needed for Solana/Rust)
install_openssl() {
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            if brew list openssl &>/dev/null; then
                print_success "OpenSSL is already installed"
            else
                print_warning "Installing OpenSSL..."
                brew install openssl
                print_success "OpenSSL installed successfully"
            fi
        fi
    elif [ "$OS" = "linux" ]; then
        # Check if libssl-dev is installed
        if command_exists apt-get; then
            if dpkg -l | grep -q libssl-dev; then
                print_success "OpenSSL development libraries are already installed"
            else
                print_warning "Installing OpenSSL development libraries..."
                sudo apt-get update
                sudo apt-get install -y libssl-dev
                print_success "OpenSSL libraries installed successfully"
            fi
        elif command_exists yum; then
            if rpm -qa | grep -q openssl-devel; then
                print_success "OpenSSL development libraries are already installed"
            else
                print_warning "Installing OpenSSL development libraries..."
                sudo yum install -y openssl-devel
                print_success "OpenSSL libraries installed successfully"
            fi
        elif command_exists dnf; then
            if rpm -qa | grep -q openssl-devel; then
                print_success "OpenSSL development libraries are already installed"
            else
                print_warning "Installing OpenSSL development libraries..."
                sudo dnf install -y openssl-devel
                print_success "OpenSSL libraries installed successfully"
            fi
        fi
    fi
}

# Check for Homebrew on macOS
check_homebrew() {
    if [ "$OS" = "macos" ]; then
        if ! command_exists brew; then
            print_warning "Homebrew is not installed. Installing automatically..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add to PATH for Apple Silicon Macs
            if [[ $(uname -m) == 'arm64' ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            if command_exists brew; then
                print_success "Homebrew installed successfully"
            else
                print_warning "Homebrew installation may have failed, but continuing..."
            fi
        else
            print_success "Homebrew is already installed"
        fi
    fi
}

# Build the project
build_project() {
    print_info "Checking if project build is needed..."
    
    if [ -f "Cargo.toml" ]; then
        # Check if already built
        if [ -f "target/release/ore-cli" ]; then
            print_success "Project is already built (skipping rebuild)"
        else
            print_info "Building the ORE mining project..."
            cargo build --release
            print_success "Project built successfully"
        fi
    else
        print_error "Cargo.toml not found. Are you in the correct directory?"
        exit 1
    fi
}

# Setup .env file
setup_env_file() {
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_warning ".env file not found. Creating from .env.example..."
            cp .env.example .env
            print_success ".env file created"
            print_warning "⚠️  Please edit .env with your actual configuration before running select_blocks.sh"
            ENV_NEEDS_CONFIG=true
        else
            print_error ".env.example not found. Cannot create .env file."
        fi
    else
        print_success ".env file already exists (preserving existing configuration)"
    fi
}

# Verify Solana wallet
verify_wallet() {
    print_info "Checking for Solana wallet..."
    
    PROJECT_KEYPAIR="./tmp/keypair.json"
    DEFAULT_KEYPAIR="$HOME/.config/solana/id.json"
    
    if [ -f "$PROJECT_KEYPAIR" ]; then
        print_success "Found Solana wallet at: $PROJECT_KEYPAIR"
    elif [ -f "$DEFAULT_KEYPAIR" ]; then
        print_success "Found Solana wallet at default location: $DEFAULT_KEYPAIR"
    else
        print_warning "No Solana wallet found"
        print_info "Generate one with: make generate-keypair"
    fi
}

# Main installation flow
main() {
    print_header
    
    print_info "Detecting operating system..."
    detect_os
    print_success "OS detected: $OS"
    echo ""
    
    print_info "Checking and installing dependencies..."
    echo ""
    
    # Check for package managers first
    check_homebrew
    echo ""
    
    # Install core dependencies
    install_rust
    echo ""
    
    install_solana
    echo ""
    
    install_bc
    echo ""
    
    install_pkg_config
    echo ""
    
    install_openssl
    echo ""
    
    # Setup environment
    cd "$(dirname "$0")"
    setup_env_file
    echo ""
    
    # Generate keypair if needed
    print_info "🔐 Checking for Solana keypair..."
    if [ ! -f ../tmp/keypair.json ]; then
        print_info "Generating keypair automatically..."
        ./generate_keypair.sh
        echo ""
    else
        print_success "Keypair already exists at ../tmp/keypair.json"
        echo ""
    fi
    
    # Build the project
    build_project
    echo ""
    
    # Verify wallet
    verify_wallet
    echo ""
    
    # Final summary
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                  Setup Complete! 🎉                        ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_success "All dependencies are installed and the project is built!"
    echo ""
    
    if [ "$ENV_NEEDS_CONFIG" = true ]; then
        print_warning "⚠️  Action Required:"
        echo "  1. Edit .env file with your configuration"
        echo "  2. Ensure you have a Solana wallet keypair"
        echo "  3. Run: ./select_blocks.sh"
        echo ""
        print_info "📖 For detailed instructions, see: spec/QUICKSTART.md"
        echo ""
    else
        print_info "You can now run: ./select_blocks.sh"
        print_info "📖 For detailed instructions, see: spec/QUICKSTART.md"
        echo ""
    fi
    
    if ! command -v solana &> /dev/null; then
        print_warning "If Solana CLI was just installed, you may need to reload your shell:"
        echo "    source ~/.bashrc    # or ~/.zshrc for zsh"
        echo "    Or open a new terminal window"
        echo ""
    fi
}

# Run main function
main

