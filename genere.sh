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
        <video id="popup_video" src="">
    </div>
    <script>
        // Lorsque le DOM est complètement chargé
        document.addEventListener("DOMContentLoaded", function() {
            // Récupération des éléments nécessaires
            const view = document.getElementById("view");
            const table_view_html = view.innerHTML; // Sauvegarde de la vue initiale (tableau)
            const popup = document.getElementById("popup");
            popup.style.display = "none"; // La popup est masquée par défaut
            const button_row = document.getElementById("button_row");

            // Affichage de la popup lors du clic (mousedown)
            document.addEventListener("mousedown", function(event) {
                // Identifier la ligne cliquée dans le tableau
                let row = event.target.closest("#table tbody tr");
                if (!row) return;
                if(row.dataset.type == "IMAGE"){
                    // Si c'est une image, afficher l'image dans la popup
                    popup_img.src = row.dataset.src;
                    popup_img.style.maxWidth = "200px";
                    popup_img.style.maxHeight = "200px";
                }
                else{
                    // Sinon, afficher la vidéo dans la popup
                    popup_video.src = row.dataset.src;
                    popup_video.style.maxWidth = "200px";
                    popup_video.style.maxHeight = "200px";
                }
                // Positionner et afficher la popup à côté du curseur
                popup.style.display = "block";
                popup.style.position = "absolute";
                popup.style.top = \`\${event.pageY + 15}px\`;
                popup.style.left = \`\${event.pageX + 15}px\`;
            });

            // Masquer la popup lors du relâchement du clic (mouseup)
            document.addEventListener("mouseup", function() {
                popup.style.display = "none";
                popup_img.src = "";
                popup_video.src = "";
            });

            // Fonction pour restaurer l'affichage du tableau initial
            function tableView() {
                view.innerHTML = table_view_html;
            }

            // Afficher un bouton "Back" pour revenir à la vue initiale
            function showBackButton() {
                button_row.innerHTML = \`
                    <div class="col-12 d-flex justify-content-center pt-3">
                        <button type="button" class="btn btn-primary w-25" id="backButton">Back</button>
                    </div>
                \`;
                document.getElementById("backButton").addEventListener("click", function(){
                    showOriginalButtons();
                    tableView();
                });
            }

            // Afficher les boutons originaux : "Carousel" et "Galerie"
            function showOriginalButtons() {
                button_row.innerHTML = \`
                    <div class="col-6 d-flex justify-content-end pe-5">
                        <button type="button" class="btn btn-primary w-25" id="carouselButton">Carousel</button>
                    </div>
                    <div class="col-6 d-flex justify-content-start ps-5">
                        <button type="button" class="btn btn-primary w-25" id="galerieButton">Galerie</button>
                    </div>
                \`;
               // Gestionnaire d'événement pour le bouton Carousel
               document.getElementById("carouselButton").addEventListener("click", function() {
                    let carouselHtml = \`
                        <div class="d-flex flex-column align-items-center">
                            <div id="carousel" class="carousel slide w-50 vh-50 mx-auto" data-bs-ride="carousel">
                                <div class="carousel-inner">
                    \`;

                    let first = true;
                    // Parcourir chaque ligne du tableau pour créer les items du carousel
                    document.querySelectorAll("#table tbody tr").forEach(row => {
                        if (row.dataset.type == "IMAGE") {
                            const imgSrc = row.dataset.src;
                            const img_td = row.querySelectorAll("td");
                            let img_name = img_td[0].textContent;
                            let img_alt = img_td.length === 2 ? img_td[1].textContent : "";

                            carouselHtml += \`
                                <div class="carousel-item \${first ? 'active' : ''}">
                                    <div class="ratio ratio-1x1">
                                        <img src="\${imgSrc}" class="d-block w-100 h-100 object-fit-contain" alt="\${img_alt}">
                                        <div class="carousel-caption bg-dark bg-opacity-25 p-2">
                                            <h6>\${img_name}</h6>
                                            <p>\${img_alt}</p>
                                        </div>
                                    </div>
                                </div>\`;

                            first = false;
                        }
                    });

                    carouselHtml += \`
                                </div>
                                <div class="carousel-indicators">
                    \`;

                    first = true;
                    let index = 0;
                    // Créer les indicateurs du carousel pour chaque image
                    document.querySelectorAll("#table tbody tr").forEach(row => {
                        if (row.dataset.type == "IMAGE") {
                            carouselHtml += \`
                                <button type="button" data-bs-target="#carousel" data-bs-slide-to="\${index}" \${first ? 'class="active"' : ''}></button>
                            \`;
                            first = false;
                            index++;
                        }
                    });

                    carouselHtml += \`
                                </div>
                                <button class="carousel-control-prev" type="button" data-bs-target="#carousel" data-bs-slide="prev">
                                    <span class="carousel-control-prev-icon"></span>
                                </button>
                                <button class="carousel-control-next" type="button" data-bs-target="#carousel" data-bs-slide="next">
                                    <span class="carousel-control-next-icon"></span>
                                </button>
                            </div>
                        </div>\`;

                    // Remplacer la vue par le carousel
                    view.innerHTML = carouselHtml;
                    showBackButton();
                });

                // Gestionnaire d'événement pour le bouton Galerie
                document.getElementById("galerieButton").addEventListener("click", function(){
                    let gallerieHtml = "<div class='row g-3 justify-content-center'>";
                    
                    // Parcourir les lignes du tableau pour créer la galerie
                    document.querySelectorAll("#table tbody tr").forEach(row => {
                        if(row.dataset.type == "IMAGE"){
                            const imgSrc = row.dataset.src;
                            const img_td = row.querySelectorAll("td");
                            let img_name = img_td[0].textContent;
                            let img_alt = img_td.length === 2 ? img_td[1].textContent : "";
                            if (imgSrc) {
                                gallerieHtml += \`
                                    <div class="col-md-3">
                                        <div class="ratio ratio-1x1"> \`;
                                
                                // Si le fichier est un SVG, on utilise <object> pour l'afficher
                                if (imgSrc.slice(-3) === "svg"){
                                    gallerieHtml += \`<object data="\${imgSrc}" type="image/svg+xml" class="img-fluid w-100 h-100 object-fit-contain" alt="\${img_alt}"></object>\`;
                                }
                                else{
                                    // Sinon, on affiche l'image avec la balise <img>
                                    gallerieHtml += \`<img src="\${imgSrc}" class="img-fluid w-100 h-100 object-fit-contain" alt="\${img_alt}">\`;
                                }
                                gallerieHtml += \`
                                        </div>
                                    </div>
                                \`;
                            }
                        }
                        else{
                            // Si la ressource est une vidéo, l'ajouter dans la galerie
                            const videoSrc = row.dataset.src;
                            if (videoSrc) {
                                gallerieHtml += \`
                                <div class="col-6">
                                     <div class="ratio ratio-1x1">
                                        <video src="\${videoSrc}" controls class="w-100 h-100 object-fit-contain"> </video>
                                    </div>
                                </div>
                                \`;
                            }
                        }
                    });

                    gallerieHtml += "</div>";
                    // Remplacer la vue par la galerie
                    view.innerHTML = gallerieHtml;
                    showBackButton();
                });
            }
            // Afficher les boutons "Carousel" et "Galerie" dès le chargement
            showOriginalButtons();
        });
    </script>
    <!-- Inclusion du bundle JavaScript de Bootstrap -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF
