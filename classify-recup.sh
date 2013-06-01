#!/bin/bash

# classifyrecup.sh - Classify recup directories contents generated by Photorec into
# folders of file extensions like Foremost does.
# 
# Author: Wahyu Adi Setyanto <wahyu.adi@gmail.com>
# Last updated: 25 February 2013
#
# This file is distributed under GNU General Public License version 2 or later.
#

#
# strip trailing slashes
#

WHICH=`which which`;
LS=`$WHICH ls`
GREP=`$WHICH grep`
SED=`$WHICH sed`
AWK=`$WHICH awk`
SORT=`$WHICH sort`
UNIQ=`$WHICH uniq`
HEAD=`$WHICH head`
MKDIR=`$WHICH mkdir`
RSYNC=`$WHICH rsync`
RM=`$WHICH rm`
PRINT=`$WHICH print`

INPUTDIR=$(echo "$1" | sed 's/\/$//g')
OUTPUTDIR=$(echo "$2" | sed 's/\/$//g')

FILTER=recup_dir

if [ -d "$1" ] && [ -d "$2" ]
then
    #
    # how many (remaining) recup_dirs do we have?
    # this safely assumes we always start from where the script stopped on previous run
    #
    END=`$LS -1 "$INPUTDIR/" | $GREP -i "$FILTER" | $SED 's/[a-zA-Z_.]*//' | $SORT -n -r | $HEAD -n 1`
    START=`$LS -1 "$INPUTDIR/" | $GREP -i "$FILTER" | $SED 's/[a-zA-Z_.]*//' | $SORT | $HEAD -n 1`
    N=$((END - START))
    echo "Found $N recup_dirs --> END = $END, START = $START.\n"

    echo "(Re)starting from $FILTER $START.\n"

    #
    # iterate on those recup_dirs
    #
    declare -i i=$START
    while [ $i -le $END ]
    do
        #
        # we may continue at where the user stopped, accidentally or not.
        #
        SOURCE=$INPUTDIR/$FILTER.$i
        if [ ! -d "$SOURCE" ];
        then
            echo "Non-existent directory $SOURCE skipped."
            continue
        fi

        #
        # classify each file by its extension, then iterate each folder and classify
        # afterwards, delete the original
        #
        EXTENSIONS=`$LS -1 "$SOURCE/" | $AWK -F . '{print $NF}' | $SORT | $UNIQ`
        echo "Found the following extensions in $SOURCE:\n $EXTENSIONS.\n"
        for j in $EXTENSIONS
        do
            if [ ! -d "$OUTPUTDIR/$j" ]
            then
                /bin/mkdir -p $OUTPUTDIR/$j
                echo "$OUTPUTDIR/$j/ directory created.\n"
            fi
            echo "syncing $SOURCE/*$j..."
            /usr/bin/rsync -av $SOURCE/*$j $OUTPUTDIR/$j/
            echo "DONE.\n"
            /bin/rm $SOURCE/*$j
            echo "$j file(s) in $SOURCE deleted.\n"
        done
        echo "$SOURCE removed.\n"
        /bin/rm -R $SOURCE
        (( i = i + 1 ))
    done
else
    echo "Syntax: $0 input_dir output_dir";
fi
