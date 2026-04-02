#!/bin/bash
# AI Agency Project - Auto-update script
# Cleans unnecessary files and updates project status

set -e

PROJECT_DIR="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Business_Vault/Projects/AI Agency"
cd "$PROJECT_DIR"

echo "🧹 AI Agency Project Update"
echo ""

# List of files to keep
KEEP_FILES=(
    "EXECUTION ROADMAP.md"
    "project.md"
    "tasks.md"
    "notes.md"
)

# Remove any files not in keep list (except hidden files)
echo "📂 Cleaning unnecessary files..."
for file in *.md; do
    if [[ ! " ${KEEP_FILES[@]} " =~ " ${file} " ]]; then
        echo "  Removing: $file"
        rm -f "$file"
    fi
done

echo ""
echo "✅ Project structure clean"
echo ""
echo "📄 Current files:"
ls -lh *.md | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo "📊 Project status:"
echo "  Source of truth: EXECUTION ROADMAP.md"
echo "  Current actions: tasks.md"
echo "  Ideas/research: notes.md"
echo "  Overview: project.md"

echo ""
echo "🔗 To view roadmap:"
echo "  cat 'EXECUTION ROADMAP.md' | less"

echo ""
echo "✅ Update complete!"
