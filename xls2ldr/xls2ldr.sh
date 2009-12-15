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
	local fields=$HEADER

	echo $fields
	echo ${table}.ctl
	cat <<EOF > ${table}.ctl
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
			HEADER=$line;
		fi
		echo $line
		i=$(($i+1))
	done > $DAT_FILE
}

if [ $# == 0 ] ; then
	echo "no argument"
	exit 1
fi

TABLE_NAME=$(basename $(basename $1 .xls) .xlsx)

DAT_FILE="${base_name}.dat"
CTL_FILE="${base_name}.dat"

create_dat_file
create_ctl_file

