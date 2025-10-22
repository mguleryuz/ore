# ORE Project Directory Structure

This document describes the clean, organized directory structure of the ORE mining project.

## 📁 Current Structure

```
ore/
├── api/                  # ORE API and SDK
│   ├── Cargo.toml
│   └── src/
│       ├── consts.rs
│       ├── error.rs
│       ├── event.rs
│       ├── instruction.rs
│       ├── lib.rs
│       ├── sdk.rs
│       └── state/        # State management
│           ├── automation.rs
│           ├── board.rs
│           ├── config.rs
│           ├── miner.rs
│           ├── mod.rs
│           ├── round.rs
│           ├── seeker.rs
│           ├── stake.rs
│           └── treasury.rs
│
├── cli/                  # Command-line interface
│   ├── Cargo.toml
│   └── src/
│       └── main.rs
│
├── program/              # Solana program
│   ├── Cargo.toml
│   └── src/
│       ├── automate.rs
│       ├── bury.rs
│       ├── checkpoint.rs
│       ├── claim_ore.rs
│       ├── claim_seeker.rs
│       ├── claim_sol.rs
│       ├── claim_yield.rs
│       ├── close.rs
│       ├── deploy.rs
│       ├── deposit.rs
│       ├── initialize.rs
│       ├── lib.rs
│       ├── log.rs
│       ├── migrate_staker.rs
│       ├── reset.rs
│       ├── set_admin.rs
│       ├── set_fee_collector.rs
│       ├── whitelist.rs
│       ├── withdraw.rs
│       └── wrap.rs
│
├── script/               # Shell scripts and utilities
│   ├── auto_deploy.sh    # Auto block selection & deployment
│   ├── generate_keypair.sh # Secure keypair generation
│   ├── localnet.sh       # Local network setup
│   └── setup.sh          # Dependency setup
│
├── spec/                 # Documentation & specifications
│   ├── DIRECTORY_STRUCTURE.md (this file)
│   ├── E2E_FLOW_ANALYSIS.md
│   ├── E2E_IMPLEMENTATION_SUMMARY.md
│   ├── E2E_TESTING.md
│   ├── MAKEFILE_REFERENCE.md
│   ├── QUICKSTART.md
│   ├── SCRIPTS_README.md
│   └── SCRIPT_MIGRATION_SUMMARY.md
│
├── test/                 # E2E integration tests
│   ├── Cargo.toml
│   ├── e2e/
│   │   └── deploy_e2e.rs
│   └── src/
│       ├── helpers.rs
│       └── lib.rs
│
├── .env.example          # Environment variables template
├── .gitignore            # Git ignore rules
├── Cargo.lock            # Dependency lock file
├── Cargo.toml            # Workspace configuration
├── Makefile              # Build & deployment automation
├── README.md             # Main project documentation
└── rust-toolchain.toml   # Rust toolchain spec
```

## 📂 Directory Purposes

### `/api`

**Purpose**: ORE protocol API and SDK

- Public-facing API definitions
- State management structures
- Instruction builders
- Event definitions
- Error types
- SDK helper functions

### `/cli`

**Purpose**: Command-line interface tool

- Interactive CLI for ORE protocol
- Connects to RPC endpoints
- Executes program instructions
- Query blockchain state
- Submit transactions

### `/program`

**Purpose**: Core Solana program

- On-chain program logic
- Instruction processors
- Business logic for mining
- State transitions
- Validation and security

### `/script`

**Purpose**: Shell scripts and utilities

- Automated deployment scripts
- Setup and installation scripts
- Keypair generation tools
- Local network management
- All executable shell scripts

### `/spec`

**Purpose**: Documentation and specifications

- User guides and tutorials
- API documentation
- Workflow examples
- Command reference
- Architecture specifications
- E2E testing documentation
- This directory structure guide

### `/test`

**Purpose**: E2E integration tests

- End-to-end deployment tests
- Mainnet state forking tests
- Helper utilities and test fixtures
- Integration test scenarios

## 🎯 Design Principles

### 1. Clean Root Directory

The root directory contains only:

- Essential configuration files
- Main README
- Build automation (Makefile)
- Setup scripts
- Cargo workspace config

### 2. Documentation in `/spec`

All documentation markdown files (except README.md) live in `/spec`:

- ✅ Keeps root clean and navigable
- ✅ Easy to find all docs in one place
- ✅ Clear separation of code and docs
- ✅ Scalable as documentation grows

### 3. Logical Code Organization

- Each major component has its own directory
- Related files are grouped together
- Clear separation of concerns
- Easy to navigate and understand

### 4. Configuration Management

- `.env.example` provides template
- `.env` is gitignored (contains secrets)
- `.gitignore` protects sensitive files
- `.cursor/rules/` tracked for team consistency

## 📏 File Placement Rules

### Root Level Files (Allowed)

✅ README.md - Main documentation entry point  
✅ Cargo.toml - Workspace configuration  
✅ Cargo.lock - Dependency lock  
✅ Makefile - Build automation  
✅ .env.example - Config template  
✅ .gitignore - Git rules  
✅ rust-toolchain.toml - Toolchain spec

### Root Level Files (NOT Allowed)

❌ Additional \*.md files → use `/spec` instead  
❌ Shell scripts → use `/script` directory  
❌ Test files → use `/test` directory  
❌ Build artifacts → gitignored in `/target`  
❌ Temporary files → use `/tmp` (gitignored)

### Documentation Files

All documentation → `/spec` directory:

- User guides
- API references
- Workflow documentation
- Architecture specs
- Examples and tutorials

Exception: `README.md` stays at root as the main entry point.

## 🔄 Migration History

**2025-10-22**: Organized documentation into `/spec`

- Moved `QUICKSTART.md` → `spec/QUICKSTART.md`
- Moved `MAKEFILE_REFERENCE.md` → `spec/MAKEFILE_REFERENCE.md`
- Moved `SCRIPTS_README.md` → `spec/SCRIPTS_README.md`
- Created `spec/DIRECTORY_STRUCTURE.md`
- Created `.cursor/rules/base.mdc` for enforcement
- Updated all references in scripts and README

## 🛠️ Maintaining Structure

### When Adding New Files

**Documentation?**

```bash
# ✅ Correct
touch spec/NEW_FEATURE_GUIDE.md

# ❌ Wrong
touch NEW_FEATURE_GUIDE.md  # at root
```

**Script?**

```bash
# ✅ Correct
touch script/new-utility.sh
chmod +x script/new-utility.sh

# ❌ Wrong
touch new-utility.sh  # at root
```

**Code?**

```bash
# ✅ Correct
touch api/src/new_feature.rs
touch program/src/new_instruction.rs
```

### When Moving Files

Always update references:

1. Update imports in Rust code
2. Update paths in scripts
3. Update links in documentation
4. Test that everything still works

### Cursor AI Enforcement

The `.cursor/rules/base.mdc` file enforces these rules automatically when using Cursor IDE. AI assistants will:

- Place new files in the correct directories
- Suggest moving misplaced files
- Update references when moving files
- Maintain clean root directory

## 🔍 Quick Navigation

### Finding Files

```bash
# Documentation
ls spec/

# Code
ls api/src/
ls program/src/
ls cli/src/

# Scripts
ls script/

# Tests
ls test/

# Config
ls .env* Cargo.toml Makefile
```

### Using Make Commands

```bash
make help          # See all commands
make quickstart    # View quickstart guide (from spec/)
make check-deps    # Verify setup
```

## 📊 File Counts

As of 2025-10-22:

- **Documentation files**: 8 (in `/spec`)
- **Script files**: 4 (in `/script`)
- **Source directories**: 4 (api, cli, program, test)
- **Configuration files**: 5 (at root)

## 🚀 Benefits

### Developer Experience

✅ Easy to find files  
✅ Logical organization  
✅ Clear separation of concerns  
✅ Scalable structure

### Team Collaboration

✅ Consistent conventions  
✅ AI-enforced rules  
✅ Clear documentation location  
✅ Easy onboarding

### Maintenance

✅ Simple to update docs  
✅ Easy to add new features  
✅ Clear module boundaries  
✅ Reduced clutter

## 📖 Related Documentation

- [Quick Start Guide](QUICKSTART.md) - Get started quickly
- [Makefile Reference](MAKEFILE_REFERENCE.md) - All make commands
- [Scripts Documentation](SCRIPTS_README.md) - Automation scripts
- [E2E Testing Guide](E2E_TESTING.md) - Integration testing

---

**Maintained By**: Development Team  
**Enforced By**: Cursor AI, Code Reviews  
**Last Updated**: 2025-10-22
