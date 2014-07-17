#!/bin/bash
#
# simple-backup.sh -- compress and archive directories simply
#
# The MIT License (MIT)
#
# Copyright (c) 2014 Michael Sutherland, codesmak.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

backup=("/var/www/html/*" "/home/*" "/root");
save_dir="/backups";
keep_archive=2;

function rotate_archive() {

    if [ "$#" -lt 2 ]; then
        echo $"Usage: rotate_archive [target] [keep_archive]"
        return 1
    fi

    # Rotate archive disabled
    [ $2 -lt 1 ] && return

    local target

    # Strip trailing slash
    target=${1%*/}
    # Strip base path, leaving target dir
    target=${target##*/}

    # Rotate archives
    for ((i=$(($2-2)); i>=0; i--))
    do
        if [ -f "${save_dir}/${target}.${i}.tar.gz" ]
        then
            x=$((i+1));
            echo "Rotating: ${save_dir}/${target}.${i}.tar.gz -> ${save_dir}/${target}.${x}.tar.gz"
            mv "${save_dir}/${target}.${i}.tar.gz" "${save_dir}/${target}.${x}.tar.gz"
        fi
    done

    if [[ -f "${save_dir}/${target}.tar.gz" ]]
    then
        echo "Rotating: ${save_dir}/${target}.tar.gz -> ${save_dir}/${target}.0.tar.gz"
         mv "${save_dir}/${target}.tar.gz" "${save_dir}/${target}.0.tar.gz"
    fi
}

function compress_dir() {

    if [ "$#" = 0 ]; then
        echo $"Usage: compress_dir [target]"
        return 1
    fi

    local base target

    # Strip trailing slash
    base=${1%*/};
    # Strip base, leaving target dir
    target=${base##*/}
    # Remove target dir from base path
    base=${base%/*}

    #echo "base: $base, target: $target"
    cd ${base}
    echo -n "Compressing: ${base}/${target} -> ${save_dir}/${target}.tar.gz ..."
    tar -czf "${save_dir}/${target}.tar.gz" "${base}/${target}" 2>/dev/null
    [ $? -eq 0 ] && echo " done" || echo " failed"
}


for bk in "${backup[@]}"
do
    if [[ "$(ls ${bk} 2>/dev/null)" || -d ${bk} ]]
    then
        for bk_target in $bk;
        do
            echo "Target: \"$bk_target\"";
            
            rotate_archive $bk_target $keep_archive
            compress_dir $bk_target
        done
    else
        echo "Missing backup target: $bk"
    fi
done
