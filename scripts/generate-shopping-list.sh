#!/usr/bin/env bash
# generate-shopping-list.sh — Weekly shopping list for Théo's meal prep
# Reads macro targets and generates a formatted shopping list based on
# training days vs rest days in the upcoming week.

set -euo pipefail

VAULT="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault/Areas/Health & Habits"

# Default: 4 training days, 3 rest days (adjustable)
TRAINING_DAYS="${1:-4}"
REST_DAYS=$((7 - TRAINING_DAYS))

echo "============================================"
echo "  WEEKLY SHOPPING LIST"
echo "  Generated: $(date '+%Y-%m-%d %H:%M')"
echo "  Training days: $TRAINING_DAYS | Rest days: $REST_DAYS"
echo "============================================"
echo ""

# Calculate weekly protein needs (190g/day every day)
WEEKLY_PROTEIN=$((190 * 7))

# Protein distribution across sources (approximate weekly)
# Salmon 2x, Beef 2x, Chicken 2x, Eggs daily
SALMON_KG="1.0"
BEEF_KG="1.0"
CHICKEN_KG="1.0"
EGGS_DOZ="2"

# Rice: ~250g cooked/meal on training, ~120g on rest, ~3.5 meals/day
# Dry rice = ~40% of cooked weight
RICE_TRAINING=$((250 * 4 * TRAINING_DAYS / 1000))  # kg cooked on training days
RICE_REST=$((120 * 3 * REST_DAYS / 1000))           # kg cooked on rest days
RICE_TOTAL_COOKED=$((RICE_TRAINING + RICE_REST))
# Dry rice is roughly 40% of cooked weight
RICE_DRY=$(awk "BEGIN {printf \"%.1f\", ($RICE_TOTAL_COOKED) * 0.4}")

echo "--- PROTEINS ---"
echo "  [ ] Salmon fillets ............. ${SALMON_KG} kg (${SALMON_KG}kg = ~5 fillets)"
echo "  [ ] Ground beef (90/10) ........ ${BEEF_KG} kg"
echo "  [ ] Chicken breast ............. ${CHICKEN_KG} kg"
echo "  [ ] Eggs ....................... ${EGGS_DOZ} dozen"
echo "  [ ] Whey protein powder ........ check stock"
echo ""

echo "--- CARBS ---"
echo "  [ ] White/jasmine rice ......... ${RICE_DRY} kg dry (check stock)"
echo ""

echo "--- VEGETABLES ---"
echo "  [ ] Broccoli ................... 1 kg"
echo "  [ ] Bell peppers ............... 5"
echo "  [ ] Spinach .................... 500g"
echo "  [ ] Green beans ................ 500g"
echo "  [ ] Tomatoes ................... 4"
echo "  [ ] Mushrooms .................. 250g"
echo "  [ ] Cucumber ................... 2"
echo ""

echo "--- FATS & ESSENTIALS ---"
echo "  [ ] Extra virgin olive oil ..... check stock"
echo "  [ ] Lemons ..................... 4"
echo "  [ ] Garlic ..................... 1 head"
echo "  [ ] Soy sauce .................. check stock"
echo "  [ ] Salt & pepper .............. check stock"
echo ""

echo "--- OPTIONAL ---"
echo "  [ ] Avocados ................... 2-3"
echo "  [ ] Sourdough bread ............ 1 loaf"
echo "  [ ] Berries (for shakes) ....... 1 punnet"
echo "  [ ] Ginger ..................... 1 piece"
echo ""

echo "============================================"
echo "  WEEKLY MACRO SUMMARY"
echo "============================================"
echo "  Daily protein target: 190g (every day)"
echo "  Training day: 2800 kcal (P190/C350/F65)"
echo "  Rest day:     2200 kcal (P190/C150/F90)"
echo ""
echo "  Weekly total: ~$((2800 * TRAINING_DAYS + 2200 * REST_DAYS)) kcal"
echo "  Weekly protein: ${WEEKLY_PROTEIN}g"
echo "============================================"
echo ""
echo "Tip: Run 'bash $0 5' for a 5-training-day week."
