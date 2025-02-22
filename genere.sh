#!/bin/bash

# Récupérer les données d'entrée depuis stdin
data=$(cat)

# Générer le début du document HTML (en-tête, inclusion de Bootstrap, etc.)
cat <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Projet1</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="script.js" defer></script>
</head>
<body>
    <div class="container">
        <!-- Titre de la page -->
        <div class="row pb-1">
            <div class="text-center">
                <h1>Visualisateur</h1>d'images/vidéos
            </div>
        </div>
        <!-- Section principale affichant le tableau des ressources -->
        <div class="row col-12 p-3" id="view">
            <table class="table table-hover" id="table">
                <thead>
                    <tr>
                        <th scope="col">ressource</th>
                        <th scope="col">alt</th>
                    </tr>
                </thead>
                <tbody>
EOF

# Parcourir les lignes d'entrée pour construire les lignes du tableau
while IFS=' ' read -r type ressource alt; do
    # Si la ligne commence par "PATH", on stocke le chemin de base dans la variable "path"
    if [ "$type" == "PATH" ]; then
        path="$ressource"
        continue
    fi
    # Afficher une ligne du tableau avec les attributs data-type et data-src
    echo "                     
                    <tr data-type=\"$type\" data-src=\"$path/$ressource\">
                        <td>$path/$ressource</td>
                        <td>$(echo "$alt" | tr -d '"')</td>
                    </tr>"
done <<< "$data"

# Générer la fin du document HTML (fin du tableau, zone pour les boutons, popup et scripts)
cat <<EOF
                </tbody>
            </table>
        </div>
        <!-- Zone pour les boutons (ex: Carousel, Galerie, etc.) -->
        <div class="row" id="button_row"></div>
    </div>
    <!-- Popup qui s'affiche lors d'un clic sur une ressource -->
    <div id="popup">
        <img id="popup_img" src="">
        <video id="popup_video" src=""> </video> 
    </div>
    <!-- Inclusion du bundle JavaScript de Bootstrap -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF
