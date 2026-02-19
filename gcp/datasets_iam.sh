#!/bin/bash

# Vérification des arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <fichier_datasets>"
    exit 1
fi

DATASETS_FILE="$1"
EXPORT_DIR="export_datasets_iam_front"

# Vérification que le fichier existe
if [ ! -f "$DATASETS_FILE" ]; then
    echo "Le fichier $DATASETS_FILE n'existe pas."
    exit 1
fi

# Création du dossier export
mkdir -p "$EXPORT_DIR"

# Lecture des datasets (format attendu : PROJECT_ID:DATASET_ID)
while IFS= read -r DATASET; do
    if [[ -n "$DATASET" ]]; then
        echo "Export du dataset : $DATASET"

        # Remplace ":" par "_" pour le nom de fichier
        FILE_NAME=$(echo "$DATASET" | tr ':' '_')

        bq show --format=json "$DATASET" > "$EXPORT_DIR/${FILE_NAME}.json" 2>/dev/null
    fi
done < "$DATASETS_FILE"

echo "Export terminé. Fichiers générés dans le dossier $EXPORT_DIR."
