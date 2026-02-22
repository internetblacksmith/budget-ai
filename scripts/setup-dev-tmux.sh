#!/bin/bash

# Budget AI Development Environment Setup
# Creates or attaches to a tmux session with all dev tools

set -e

SESSION_NAME="budget-ai"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Setting up Budget AI development environment...${NC}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "❌ tmux is not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install tmux"
    echo "  macOS: brew install tmux"
    exit 1
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Attaching to existing session: $SESSION_NAME${NC}"
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

echo -e "${GREEN}✓ Creating new tmux session: $SESSION_NAME${NC}"

# Create new session with first window (Claude Code)
tmux new-session -d -s "$SESSION_NAME" -x 220 -y 50 -c "$PROJECT_ROOT" -n "claude"

# Window 1: Claude Code with --continue
echo -e "${CYAN}→ Setting up Claude pane...${NC}"
tmux send-keys -t "$SESSION_NAME:claude" "claude --continue" Enter

# Window 2: Neovim
echo -e "${CYAN}→ Setting up Neovim pane...${NC}"
tmux new-window -t "$SESSION_NAME" -n "nvim" -c "$PROJECT_ROOT"
tmux send-keys -t "$SESSION_NAME:nvim" "nvim ." Enter

# Window 3: Rails Server (start immediately)
echo -e "${CYAN}→ Setting up Rails Server pane (starting automatically)...${NC}"
tmux new-window -t "$SESSION_NAME" -n "server" -c "$PROJECT_ROOT"
tmux send-keys -t "$SESSION_NAME:server" "make server" Enter

# Window 4: Background Jobs (Solid Queue)
echo -e "${CYAN}→ Setting up Background Jobs pane...${NC}"
tmux new-window -t "$SESSION_NAME" -n "jobs" -c "$PROJECT_ROOT"
tmux send-keys -t "$SESSION_NAME:jobs" "make jobs" Enter

# Window 5: Shell (empty, for one-off commands)
echo -e "${CYAN}→ Setting up Shell pane (for one-off commands)...${NC}"
tmux new-window -t "$SESSION_NAME" -n "shell" -c "$PROJECT_ROOT"
# Keep it empty and ready

# Select the claude window to start with
tmux select-window -t "$SESSION_NAME:claude"

echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════════════"
echo "✓ Development environment ready!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "📦 Available windows:"
echo "  • claude  (1) - Claude Code with --continue"
echo "  • nvim    (2) - Neovim editor"
echo "  • server  (3) - Rails server (started automatically)"
echo "  • jobs    (4) - Background jobs (Solid Queue)"
echo "  • shell   (5) - Empty shell for one-off commands"
echo ""
echo "🎮 Tmux shortcuts:"
echo "  • Ctrl+B 1-6   - Jump to window by number"
echo "  • Ctrl+B n/p   - Next/Previous window"
echo "  • Ctrl+B c     - Create new window"
echo "  • Ctrl+B [     - Enter scroll mode (q to exit)"
echo "  • Ctrl+B d     - Detach from session"
echo "  • Ctrl+B x     - Kill current pane"
echo ""
echo "📝 To reconnect later:"
echo "  • make dev     - Re-attach to this session"
echo "  • tmux a       - Manually attach"
echo ""
echo -e "${NC}"

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
