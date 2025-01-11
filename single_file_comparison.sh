#!/bin/bash

# Funcție pentru curățarea fișierului typescript
clean_typescript() {
    local file="$1"
    
    # Extragem fișiere și directoare din typescript (ignoram timestamp-ul)
    grep -E '^[-d]' "$file" | awk '{print $9}' | sed 's/\r//g' | sort > /tmp/ls_data
    # Extragem informații despre utilizarea discului
    grep '/dev/sda2' "$file" | awk '{print $3}' | sed 's/\r//g' > /tmp/df_data
}

# Funcție pentru extragerea stării curente
get_current_state() {
    # Extragem fișiere și directoare din starea curentă
    ls -l | grep -E '^[-d]' | awk '{print $9}' | sed 's/\r//g' | sort > /tmp/ls_current
    # Extragem utilizarea discului din starea curentă
    df -h | grep '/dev/sda2' | awk '{print $3}' | sed 's/\r//g' > /tmp/df_current
}

# Funcție pentru curățarea valorii de utilizare a discului
clean_disk_value() {
    local value="$1"
    # Îndepărtăm caracterele nevalide (unități și caractere speciale)
    value=$(echo "$value" | sed -e 's/[A-Za-z%]//g' -e 's/\s//g')
    echo "$value"
}

# Verificăm numărul de argumente
if [[ $# -ne 1 ]]; then
    echo "Utilizare: $0 <typescript1>"
    exit 1
fi

# Preluăm fișierul typescript
file1="$1"

# Curățăm fișierul typescript
clean_typescript "$file1"
ls_data1=$(cat /tmp/ls_data)
df_data1=$(cat /tmp/df_data)

# Obținem starea curentă
get_current_state
ls_data2=$(cat /tmp/ls_current)
df_data2=$(cat /tmp/df_current)

# Comparăm fișierele/directoarele ignorând timestamp-ul
# Excludem sursa.sh din comparație
added_files=$(comm -13 <(echo "$ls_data1" | grep -v 'sursa.sh' | sort) <(echo "$ls_data2" | grep -v 'sursa.sh' | sort))
removed_files=$(comm -23 <(echo "$ls_data1" | grep -v 'sursa.sh' | sort) <(echo "$ls_data2" | grep -v 'sursa.sh' | sort))

# Generăm raportul fișierelor adăugate și șterse
echo "Fișiere și directoare adăugate:"
echo "$added_files"

echo "Fișiere și directoare șterse:"
echo "$removed_files"

# Comparăm utilizarea discului
disk_used1=$(clean_disk_value "$(cat /tmp/df_data)")
disk_used2=$(clean_disk_value "$(cat /tmp/df_current)")

# Calculăm diferența în utilizarea discului
disk_diff=$(echo "$disk_used2 - $disk_used1" | bc)

# Afișăm diferența dacă este semnificativă
if (( $(echo "$disk_diff > 0.01" | bc -l) )); then
    echo "Diferență în utilizarea spațiului pe disc: +${disk_diff}GB"
elif (( $(echo "$disk_diff < -0.01" | bc -l) )); then
    echo "Diferență în utilizarea spațiului pe disc: ${disk_diff}GB (scădere)"
else
    echo "Nu există modificări semnificative în utilizarea spațiului pe disc."
fi

