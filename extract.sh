#!/bin/bash

if [ $# -lt 1 ] ; then 
    echo "Utilisation : extract [options] <url>"
fi

r=0 i=0 v=0 p=0 h=0 path="" reg=""

for arg in "$@"; do 
    if [ "$r" -eq 1 ]; then
        reg=$arg
        r=0
    elif [ "$p" -eq 1 ]; then
        path=$arg
        p=0
    elif [ "$arg" == '-r' ]; then r=1
    elif [ "$arg" == '-i' ]; then i=1
    elif [ "$arg" == '-v' ]; then v=1
    elif [ "$arg" == '-p' ]; then p=1
    elif [ "$arg" == '-h' ]; then h=1
    fi
done

if [ "$h" -eq 1 ]; then
    echo "
    Createurs : Miali Matteo 20308845
    Utilisation : extract [options] <url>

        Options :
        -r <regex>    Liste uniquement les ressources dont le nom matche 
                      l'expression régulière.
        -i            Ne liste pas les éléments <img> (par défaut : les liste).
        -v            Ne liste pas les éléments <video> (par défaut : les liste).
        -p <path>     Liste et copie les ressources <img> et/ou <video> de <url> 
                      dans <path> (par défaut : ne fait que lister).
        -h            Affiche ce message d'aide ainsi que les informations sur les auteurs."
fi

url=${!#}
working_directory=$(dirname "$url")

# Créer le path s'il n'existe pas et le vider sinon
if [ -n "$path" ]; then
    if [ -d "$path" ]; then
        rm -rf "$path"/*
    else
        mkdir -p "$path"
    fi
fi

# Récupération du contenu HTML en désactivant le globbing (-g)
html_content=$(curl -s -g "$url")
if [ $? -ne 0 ]; then
    echo "Error fetching URL" >&2
    exit 1
fi

# Fonction pour extraire le nom de fichier à partir d'une URL
extract_filename() {
    clean_src=$(echo "$1" | cut -d'?' -f1)
    file_name=$(echo "$clean_src" | grep -oE '/[^/]+\.(png|jpg|jpeg|gif|webp|svg)' | tail -1 | cut -d'/' -f2)
    [ -z "$file_name" ] && file_name=$(basename "$clean_src")
    echo "$file_name"
}

# Fonction de téléchargement
download_file() {
    local resource_url="$1"
    local destination="$2"
    
    # Si l'URL est un data URI, on l'ignore
    if [[ "$resource_url" == data:* ]]; then
        return 1
    fi

    local file_name
    file_name=$(extract_filename "$resource_url")
    curl -s -g -L -o "$destination/$file_name" "$resource_url"
    if [ $? -ne 0 ]; then
         return 1
    fi
    echo "$file_name"
}
images=""
videos=""

if [ "$i" -eq 0 ]; then
    # Itération sur les balises <img>
    images=$(echo "$html_content" | grep -oE '<img[^>]+' | while read -r img_tag; do 
        src=$(echo "$img_tag" | grep -oE 'src="[^"]+"' | cut -d'"' -f2)
        [ -z "$src" ] && continue
        if [ -n "$reg" ]; then
            if ! grep -q "$reg" <<< "$src"; then
                continue
            fi
        fi
        if [ -n "$path" ]; then
            if [[ ${src:0:4} == "http" ]]; then
                file_name=$(download_file "$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            elif [[ ${src:0:1} == "/" ]]; then
                base_url=$(echo "$url" | awk -F/ '{print $1"//"$3}')
                file_name=$(download_file "$base_url$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            else
                file_name=$(download_file "$working_directory/$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            fi
        fi
        alt=$(echo "$img_tag" | grep -oE 'alt="[^"]+"' | cut -d'"' -f2)
        if [ -n "$alt" ]; then
            echo "$src \"$alt\""
        else
            echo "$src"
        fi
    done)
fi

# Aplatir le HTML pour gérer les balises <video> sur plusieurs lignes
html_video_flat=$(echo "$html_content" | tr '\n' ' ' | sed 's|</video>|</video>\n|g')

if [ "$v" -eq 0 ]; then
    # Itération sur les balises <video>
    videos=$(echo "$html_video_flat" | grep -oE '<video[^>]*>.*</video>' | while read -r video_tag; do 
        src=$(echo "$video_tag" | grep -oE 'src="[^"]+"' | head -n 1 | cut -d'"' -f2)
        [ -z "$src" ] && continue
        if [ -n "$reg" ]; then
            if ! grep -q "$reg" <<< "$src"; then
                continue
            fi
        fi
        if [ -n "$path" ]; then
            if [[ ${src:0:4} == "http" ]]; then
                file_name=$(download_file "$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            elif [[ ${src:0:1} == "/" ]]; then
                base_url=$(echo "$url" | awk -F/ '{print $1"//"$3}')
                file_name=$(download_file "$base_url$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            else
                file_name=$(download_file "$working_directory/$src" "$path")
                [ $? -ne 0 ] && continue
                src=$file_name
            fi
        fi
        echo "$src"
    done)
fi

if [ -n "$path" ]; then
    echo "PATH $path"
else
    echo "PATH $working_directory"
fi

if [ -n "$images" ]; then
    while IFS= read -r img; do
        echo "IMAGE $img"
    done <<< "$images"
fi

if [ -n "$videos" ]; then
    while IFS= read -r vid; do
        echo "VIDEO $vid"
    done <<< "$videos"
fi
