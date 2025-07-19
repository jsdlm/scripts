param (
    [string]$groupEmailsFile = $(throw "Veuillez spécifier le chemin du fichier contenant les emails des groupes.")
)

# Vérifie si le fichier existe
if (!(Test-Path -Path $groupEmailsFile)) {
    Write-Output "Le fichier spécifié n'existe pas : $groupEmailsFile"
    exit
}

# Charger les emails des groupes depuis le fichier fourni en argument
$groupEmails = Get-Content -Path $groupEmailsFile

# Dossier pour enregistrer les fichiers d'export
$exportPath = "exports"

# Extraire le nom du fichier sans extension pour créer un sous-dossier
$baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($groupEmailsFile)
$subExportPath = "$exportPath\$baseFileName"

# Créer le dossier principal et le sous-dossier s'ils n'existent pas
if (!(Test-Path -Path $exportPath)) {
    New-Item -ItemType Directory -Path $exportPath | Out-Null
}
if (!(Test-Path -Path $subExportPath)) {
    New-Item -ItemType Directory -Path $subExportPath | Out-Null
}

foreach ($groupEmail in $groupEmails) {
    # Rechercher le groupe par son email
    $group = Get-AzureADGroup -Filter "Mail eq '$groupEmail'"

    if ($group) {
        # Récupérer l'ID du groupe
        $groupId = $group.ObjectId

        # Récupérer les membres du groupe
        $members = Get-AzureADGroupMember -ObjectId $groupId -All $true

        # Extraire la partie avant le "@" dans l'email pour nommer le fichier
        $cleanFileName = $groupEmail -replace '@.*$', ''

        # Exporter les informations des utilisateurs dans un fichier CSV
        $members | Select-Object ObjectId, DisplayName, UserPrincipalName | Export-Csv -Path "$subExportPath\$cleanFileName.csv" -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Output "Group with email $groupEmail not found."
    }
}
