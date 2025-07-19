#!/bin/bash

# Vérification des arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <fichier_de_projects> <output_csv>"
    exit 1
fi

# Arguments
PROJECTS_FILE="$1"
OUTPUT_FILE="$2"

# Vérification que le fichier de projets existe
if [ ! -f "$PROJECTS_FILE" ]; then
    echo "Le fichier $PROJECTS_FILE n'existe pas."
    exit 1
fi

# Lecture et traitement des projets
while IFS= read -r PROJECT_ID; do
    if [[ -n "$PROJECT_ID" ]]; then
        echo "Traitement du projet : $PROJECT_ID"

        # Lister les buckets et ajouter le nom du projet à chaque ligne
        gcloud storage buckets list --project="$PROJECT_ID" --quiet --format="csv(name,public_access_prevention,uniform_bucket_level_access,rpo,soft_delete_policy.retentionDurationSeconds)" \
        | awk -v project="$PROJECT_ID" '{print project "," $0}' 2>/dev/null >> "$OUTPUT_FILE"
    fi
done < "$PROJECTS_FILE"


echo "Traitement terminé. Résultats enregistrés dans $OUTPUT_FILE."
