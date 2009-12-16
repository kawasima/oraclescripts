#!/bin/bash

shopt -s extglob

function field_list() {
	local i=0
	for f in $@ ; do
		printf "$f"
		if [[ $f == *_TM ]] ; then
			printf " \"TO_DATE(:%s, 'YYYY/MM/DD HH24:MI:SS')\" " $f
		elif [[ $f == *_DATE ]] ; then
			printf " \"TO_DATE(:%s, 'YYYY/MM/DD')\" " $f
		fi
		if [ $i -lt $(($# - 1)) ] ; then
			printf ","
		fi
		echo ""
		i=$(($i + 1))
	done
}

function create_ctl_file() {
	local table=$TABLE_NAME
	local fields=$(< $HEADER_FILE)

	cat <<EOF > $CTL_FILE
LOAD DATA
INFILE '${table}.dat'
TRUNCATE
INTO TABLE ${table}
FIELDS TERMINATED BY X'09'
TRAILING NULLCOLS
(
$(field_list $fields)
)
EOF
}

function create_dat_file() {
    local i=0
    xlhtml -asc -xp:0 $EXCEL_FILE | while read line; do
        if [ $i -eq 0 ] ; then
            echo $line> $HEADER_FILE
        elif [ "$line" != "" ] ; then
            echo $line
        fi
        i=$(($i+1))
    done > $DAT_FILE
}

if [ $# == 0 ] ; then
	echo "no argument"
	exit 1
fi

for f in $@ ; do
    EXCEL_FILE=$f
    TABLE_NAME=$(basename $(basename $f .xls) .xlsx)

    HEADER_FILE="${TABLE_NAME}.header"
    DAT_FILE="${TABLE_NAME}.dat"
    CTL_FILE="${TABLE_NAME}.ctl"

    create_dat_file
    create_ctl_file
    rm $HEADER_FILE
done

