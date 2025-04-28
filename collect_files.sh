#!/bin/bash

inp_dir="$1"
outp_dir="$2"

generate_name() {
    local dir="$1" prefix="$2" suffix="$3" num=0
    local result="${prefix}.${suffix}"
    while [ -e "${dir}/${result}" ]; do
        ((num++))
        result="${prefix}${num}.${suffix}"
    done
}

process_items() {
    local folder="$1"
    for element in "$folder"/*; do
        if [ -f "$element" ]; then
            file=$(basename "$element")
            prefix="${file%.*}"
            suffix="${file##*.}"
            destination="$outp_dir/$file"
            if [ -e "$destination" ]; then
                file=$(generate_name "$outp_dir" "$prefix" "$suffix")
                destination="$outp_dir/$file"
            fi
            cp "$element" "$destination"
        elif [ -d "$element" ]; then
            process_items "$element"
        fi
    done
}
process_items "$inp_dir"