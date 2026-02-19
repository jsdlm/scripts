#!/bin/bash

# Vérification des arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <fichier_de_projects.txt> <output.csv>"
    exit 1
fi

# Arguments
PROJECTS_FILE="$1"
OUTPUT_FILE="$2"

# Vérification du fichier de projets
if [ ! -f "$PROJECTS_FILE" ]; then
    echo "Le fichier $PROJECTS_FILE n'existe pas."
    exit 1
fi

# En-tête CSV
echo "ProjectID,Member,Role" > "$OUTPUT_FILE"

# Lecture et traitement
while IFS= read -r PROJECT_ID; do
    if [[ -n "$PROJECT_ID" ]]; then
        echo "Traitement du projet : $PROJECT_ID"

        gcloud projects get-iam-policy "$PROJECT_ID" \
            --flatten="bindings[].members[]" \
            --format="csv[no-heading](bindings.members,bindings.role)" 2>/dev/null | \
        while IFS=',' read -r MEMBER ROLE; do
            echo "$PROJECT_ID","$MEMBER","$ROLE"
        done >> "$OUTPUT_FILE"
    fi
done < "$PROJECTS_FILE"

echo "Traitement terminé. Résultats enregistrés dans $OUTPUT_FILE."
