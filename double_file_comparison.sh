#!/bin/bash

filter_files() {
    # Exclude fișierele .sh și typescriptX
    grep -vE '(main\.sh|single_file_comparison\.sh|double_file_comparison\.sh|typescript[0-9]+)'
}

# Funcție pentru curățarea fișierului typescript
clean_typescript() {
    local file="$1"

    # Eliminăm codurile de culoare și alte secvențe de escape
    sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$file" > /tmp/cleaned_typescript

    # Extragem fișierele și directoarele
    grep -E '^[-d]' /tmp/cleaned_typescript > /tmp/ls_data

    # Extragem informațiile despre utilizarea discului
    grep '/dev/sda2' /tmp/cleaned_typescript > /tmp/df_data
}


# Funcție pentru curățarea valorilor de unități (G, M, K)
clean_disk_value() {
    local value="$1"
    # Eliminăm orice unitate de tip G, M, K și lăsăm doar numărul
    value=$(echo "$value" | sed -e 's/[A-Za-z%]//g') 

    # Eliminăm orice spațiu sau caractere speciale invizibile
    value=$(echo "$value" | tr -d -c '[:digit:].')

    # Validăm că valoarea este numerică
    if ! [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then  
        echo "Valoare invalidă pentru utilizarea discului: $value"
        exit 1
    fi
    echo "$value"
}

# Preluăm fișierele
file1="$1"
file2="$2"
    
    # Curățăm cele două fișiere
    clean_typescript "$file1"
    ls_data1=$(cat /tmp/ls_data)
    df_data1=$(cat /tmp/df_data)

    clean_typescript "$file2"
    ls_data2=$(cat /tmp/ls_data)
    df_data2=$(cat /tmp/df_data)

    # Comparăm fișierele/directoarele ignorând timestamp-ul
    added_files=$(comm -13 <(echo "$ls_data1" | filter_files | awk '{print $5,$9}' | sort) <(echo "$ls_data2" | filter_files | awk '{print $5,$9}' | sort) | awk '{print $2}')
    removed_files=$(comm -23 <(echo "$ls_data1" | filter_files | awk '{print $5,$9}' | sort) <(echo "$ls_data2" | filter_files | awk '{print $5,$9}' | sort) | awk '{print $2}')
    
    echo "Fișiere și directoare adăugate:"
    echo "$added_files"
    
    echo "Fișiere și directoare șterse:"
    echo "$removed_files"
    
    # Comparăm utilizarea discului
    disk_used1=$(echo "$df_data1" | awk '{print $3}' | sed 's/G//')
    disk_used2=$(echo "$df_data2" | awk '{print $3}' | sed 's/G//')

    disk_diff=$(echo "$disk_used2 - $disk_used1" | bc)

    # Afișăm diferența dacă este semnificativă
    if (( $(echo "$disk_diff > 0.01" | bc -l) )); then
        echo "Diferență în utilizarea spațiului pe disc: +${disk_diff}GB"
    elif (( $(echo "$disk_diff < -0.01" | bc -l) )); then
        echo "Diferență în utilizarea spațiului pe disc: ${disk_diff}GB"
    else
        echo "Nu există modificări semnificative în utilizarea spațiului pe disc."
    fi

