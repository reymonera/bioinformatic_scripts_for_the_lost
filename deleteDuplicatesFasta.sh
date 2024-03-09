#!/bin/bash

# Directorio donde se encuentran los archivos multifasta
directorio="/ruta/a/tu/carpeta"

# Recorre todos los archivos multifasta en el directorio
for archivo in "$directorio"/*.fasta
do
    echo "Procesando archivo $archivo"
    
    # Crea un array asociativo para almacenar las secuencias
    declare -A secuencias

    # Lee el archivo línea por línea
    while IFS= read -r linea
    do
        # Si la línea comienza con '>', es una cabecera de secuencia
        if [[ $linea =~ ^\> ]]
        then
            cabecera=$linea
        else
            # Si la secuencia ya existe en el array, la elimina
            if [[ ${secuencias[$linea]} ]]
            then
                unset secuencias[$cabecera]
            else
                secuencias[$cabecera]=$linea
            fi
        fi
    done < "$archivo"

    # Escribe las secuencias no duplicadas a un nuevo archivo
    for cabecera in "${!secuencias[@]}"
    do
        echo "$cabecera" >> "${archivo%.fasta}_nodup.fasta"
        echo "${secuencias[$cabecera]}" >> "${archivo%.fasta}_nodup.fasta"
    done

    # Limpia el array para el próximo archivo
    unset secuencias
done
