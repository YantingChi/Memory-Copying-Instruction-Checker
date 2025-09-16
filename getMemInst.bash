#!/bin/bash

# Directory containing LLVM IR files
IR_DIR="${1:-.}"  # Use first argument or current directory

# Memory copying functions to search for
MEMORY_FUNCS=(
    "memcpy"
    "memmove"
    "memcpy_and_pad"
    "copy_kernel_nofault"
    "copy_to_kernel_nofault"
    "probe_kernel_read"
    "probe_kernel_write"
    "copy_page"
    "memcpy_from_page"
    "memcpy_to_page"
    "folio_copy"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# echo -e "${BLUE}Searching for memory copying functions in LLVM IR files...${NC}"
# echo "Directory: $IR_DIR"
# echo

# Build regex pattern - matches function calls and declarations
# This pattern looks for:
# - Function calls: call ... @function_name(
# - Function declarations: declare ... @function_name(
# - Function definitions: define ... @function_name(
build_pattern() {
    local funcs=("$@")
    local pattern=""
    
    for i in "${!funcs[@]}"; do
        if [ $i -gt 0 ]; then
            pattern+="|"
        fi
        # Match function calls, declarations, and definitions
        pattern+="(call.*@${funcs[i]}[^a-zA-Z_])"
    done
    
    echo "$pattern"
}

PATTERN=$(build_pattern "${MEMORY_FUNCS[@]}")

# Find and search IR files
found_files=0
total_matches=0

# Search for .ll files (LLVM IR text format) and .bc files won't work with grep
find "$IR_DIR" -name "*.ll" -type f | while read -r file; do
    # echo -e "${YELLOW}Checking: $file${NC}"
    
    # Search for memory functions in the file
    matches=$(grep -n -E "$PATTERN" "$file")
    
    if [ ! -z "$matches" ]; then
        echo -e "${GREEN}Found matches in: $file${NC}"
        
        # Extract and display function names found
        echo "$matches" | while read -r match; do
			total_matches=total_matches+1
            line_num=$(echo "$match" | cut -d: -f1)
            line_content=$(echo "$match" | cut -d: -f2-)
            
            # Extract function name
            func_name=$(echo "$line_content" | grep -oE "@[a-zA-Z_][a-zA-Z0-9_]*" | head -1 | sed 's/@//')
            
            echo -e "  ${RED}Line $line_num:${NC} $func_name"
            echo -e "    ${line_content}"
        done
        echo
        ((found_files++))
    fi
done
# echo found_files=$found_files
echo total_matches=$total_matches
# Alternative: Simple one-liner approach
echo -e "${BLUE}Alternative one-liner commands:${NC}"
echo
echo "1. Basic search for all memory functions (includes LLVM intrinsics):"
echo "   find . -name '*.ll' -exec grep -l -E '@(llvm\.)?(memcpy|memmove|memcpy_and_pad|copy_kernel_nofault|copy_to_kernel_nofault|probe_kernel_read|probe_kernel_write|copy_page|memcpy_from_page|memcpy_to_page|folio_copy)(\.|[^a-zA-Z_])' {} \;"
echo
echo "2. Detailed search with context:"
echo "   find . -name '*.ll' -exec grep -n -E '@(llvm\.)?(memcpy|memmove|memcpy_and_pad|copy_kernel_nofault|copy_to_kernel_nofault|probe_kernel_read|probe_kernel_write|copy_page|memcpy_from_page|memcpy_to_page|folio_copy)(\.|[^a-zA-Z_])' {} /dev/null \;"
echo
echo "3. Search specifically for LLVM intrinsics:"
echo "   find . -name '*.ll' -exec grep -n -E 'call.*@llvm\.(memcpy|memmove)\.[a-zA-Z0-9_.]*' {} /dev/null \;"
echo
echo "4. Count occurrences:"
echo "   find . -name '*.ll' -exec grep -c -E '@(llvm\.)?(memcpy|memmove|memcpy_and_pad|copy_kernel_nofault|copy_to_kernel_nofault|probe_kernel_read|probe_kernel_write|copy_page|memcpy_from_page|memcpy_to_page|folio_copy)(\.|[^a-zA-Z_])' {} /dev/null \; | grep -v ':0"