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
    # Vérification si la ligne n'est pas vide
    if [[ -n "$PROJECT_ID" ]]; then
        echo "Traitement du projet : $PROJECT_ID"
        
        # Exécution de la commande gcloud pour ce projet
        gcloud sql instances list --quiet --project=$PROJECT_ID --format="csv(project,name,database_version,settings.ipConfiguration.ipv4Enabled,settings.ipConfiguration.requireSsl,settings.ipConfiguration.sslMode,settings.backupConfiguration.enabled)" 2>/dev/null >> "$OUTPUT_FILE"
    fi
done < "$PROJECTS_FILE"

echo "Traitement terminé. Résultats enregistrés dans $OUTPUT_FILE."
