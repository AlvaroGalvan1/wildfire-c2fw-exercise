#!/usr/bin/env bash
# =============================================================
# install.sh — Wildfire C2F-W Exercise Setup
# =============================================================
# Installs Python dependencies, downloads & compiles C2F-W,
# and creates the runtime directory structure.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# Tested on: Ubuntu 24.04 (Noble) — Wildfire Commons JupyterHub
# =============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C2FW_DIR="${REPO_DIR}/C2F-W"
C2FW_REPO="https://github.com/fire2a/C2F-W.git"
C2FW_BINARY="${C2FW_DIR}/Cell2Fire/Cell2Fire"

echo "================================================="
echo " Wildfire C2F-W Exercise — Environment Setup"
echo "================================================="
echo ""

# ── 1. Python dependencies ───────────────────────────────────
echo "[1/4] Installing Python dependencies..."
pip install --quiet -r "${REPO_DIR}/requirements.txt"
echo "  ✓ Python packages installed"
echo ""

# ── 2. System dependencies for compilation ───────────────────
echo "[2/4] Checking system dependencies (g++, libboost, libtiff)..."
# Try apt-get without sudo (works on some JupyterHub environments)
if command -v apt-get &>/dev/null; then
    apt-get install -y --quiet g++ libboost-all-dev libtiff-dev 2>/dev/null || \
    sudo apt-get install -y --quiet g++ libboost-all-dev libtiff-dev 2>/dev/null || \
    echo "  ⚠ Could not install via apt-get — will attempt compilation anyway"
else
    echo "  ⚠ apt-get not found — attempting compilation with existing tools"
fi
# Verify g++ is available
if command -v g++ &>/dev/null; then
    echo "  ✓ g++ found: $(g++ --version | head -1)"
else
    echo "  ✗ g++ not found — compilation will fail"
    exit 1
fi
echo ""

# ── 3. Clone and compile C2F-W ───────────────────────────────
echo "[3/4] Setting up Cell2Fire W..."

if [ -f "${C2FW_BINARY}" ]; then
    echo "  ✓ C2F-W binary already exists at: ${C2FW_BINARY}"
else
    if [ ! -d "${C2FW_DIR}" ]; then
        echo "  Cloning C2F-W repository..."
        git clone --quiet "${C2FW_REPO}" "${C2FW_DIR}"
        echo "  ✓ Repository cloned"
    else
        echo "  ✓ C2F-W directory exists, skipping clone"
    fi

    echo "  Compiling C2F-W (this may take 1–2 minutes)..."
    cd "${C2FW_DIR}/Cell2Fire"
    make -j4 2>&1 | tail -5
    cd "${REPO_DIR}"

    if [ -f "${C2FW_BINARY}" ]; then
        chmod +x "${C2FW_BINARY}"
        echo "  ✓ C2F-W compiled successfully"
    else
        echo "  ✗ Compilation failed — binary not found at ${C2FW_BINARY}"
        echo "    Try compiling manually: cd C2F-W/Cell2Fire && make"
        exit 1
    fi
fi
echo ""

# ── 4. Create runtime directories ───────────────────────────
echo "[4/4] Creating runtime directories..."
for town in forest prairie; do
    mkdir -p "${REPO_DIR}/instance/${town}"
    mkdir -p "${REPO_DIR}/results/${town}"
    mkdir -p "${REPO_DIR}/plots/${town}"
    mkdir -p "${REPO_DIR}/data-raw/${town}"
    echo "  ✓ ${town}/ directories ready"
done
echo ""

# ── Summary ──────────────────────────────────────────────────
echo "================================================="
echo " Setup complete!"
echo "================================================="
echo ""
echo "  Binary:  ${C2FW_BINARY}"
echo "  Lookup:  ${C2FW_DIR}/data/ScottAndBurgan/Zona_60-tif/spain_lookup_table.csv"
echo ""
echo "  Next steps:"
echo "  1. Add exercise data to data-raw/forest/ and data-raw/prairie/"
echo "     (use the Wildfire Commons UI → Add Files to Current Folder)"
echo "  2. Open notebooks/ and run in order:"
echo "     01_data_exploration.ipynb"
echo "     02_data_transformation.ipynb"
echo "     03_run_simulation.ipynb"
echo "     04_results_and_outputs.ipynb"
echo ""