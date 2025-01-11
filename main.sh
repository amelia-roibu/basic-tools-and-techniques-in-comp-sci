#!/bin/bash

# Verificăm numărul de argumente
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Utilizare: $0 <typescript1> [<typescript2>]"
    exit 1
fi

# Dacă avem un singur fișier typescript
if [[ $# -eq 1 ]]; then
    ./single_file_comparison.sh "$1"
# Dacă avem două fișiere typescript
elif [[ $# -eq 2 ]]; then
    ./double_file_comparison.sh "$1" "$2"
fi

