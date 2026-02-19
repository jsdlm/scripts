param (
    [string]$groupNamesFile = $(throw "Veuillez spécifier le chemin du fichier contenant les noms des groupes.")
)

Write-Output "Début du script"
Write-Output "Fichier fourni : $groupNamesFile"

if (!(Test-Path -Path $groupNamesFile)) {
    Write-Output "Le fichier spécifié n'existe pas : $groupNamesFile"
    exit
}

Write-Output "Chargement des noms de groupes..."
$groupNames = Get-Content -Path $groupNamesFile
Write-Output "Nombre de noms trouvés : $($groupNames.Count)"

$exportPath = "exports"
$baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($groupNamesFile)
$subExportPath = Join-Path $exportPath $baseFileName

if (!(Test-Path -Path $exportPath)) {
    Write-Output "Création du dossier $exportPath"
    New-Item -ItemType Directory -Path $exportPath | Out-Null
}

if (!(Test-Path -Path $subExportPath)) {
    Write-Output "Création du sous-dossier $subExportPath"
    New-Item -ItemType Directory -Path $subExportPath | Out-Null
}

foreach ($groupName in $groupNames) {

    $groupName = $groupName.Trim()
    if ([string]::IsNullOrWhiteSpace($groupName)) {
        Write-Output "Ligne vide ignorée"
        continue
    }

    Write-Output "--------------------------------------"
    Write-Output "Recherche du groupe : $groupName"

    try {
        $group = Get-AzureADGroup -Filter "DisplayName eq '$groupName'"
    }
    catch {
        Write-Output "Erreur lors de l'appel Get-AzureADGroup : $_"
        continue
    }

    if ($group) {
        Write-Output "Groupe trouvé : $($group.DisplayName)"
        $groupId = $group.ObjectId
        Write-Output "ObjectId : $groupId"

        try {
            $members = Get-AzureADGroupMember -ObjectId $groupId -All $true
            Write-Output "Nombre de membres récupérés : $($members.Count)"
        }
        catch {
            Write-Output "Erreur lors de la récupération des membres : $_"
            continue
        }

        # Nettoyage complet du nom de fichier
        $cleanFileName = $groupName -replace '[^a-zA-Z0-9._-]', '_'
        $outputFile = Join-Path $subExportPath "$cleanFileName.csv"

        Write-Output "Export vers : $outputFile"

        $members | Select-Object ObjectId, DisplayName, UserPrincipalName |
            Export-Csv -LiteralPath $outputFile -NoTypeInformation -Encoding UTF8

        Write-Output "Export terminé pour $groupName"
    }
    else {
        Write-Output "Groupe non trouvé pour : $groupName"
    }
}

Write-Output "Script terminé"
