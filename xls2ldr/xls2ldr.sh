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
LENGTH SEMANTICS CHAR
INFILE '${table}.dat'
TRUNCATE
INTO TABLE ${table}
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
$(field_list $fields)
)
EOF
}

function create_dat_file() {
    local sheet_no=$1
    local i=0
    xlhtml -csv -xp:$sheet_no $EXCEL_FILE | perl -pe 's/&amp;/&/g' | while read line; do
        if [ $i -eq 0 ] ; then
            echo $line> $HEADER_FILE
        elif [ "$line" != "" ] ; then
            printf "$line\n"
        fi
        i=$(($i+1))
    done > $DAT_FILE
}

function parse_excel() {
    local sheet_no=$1
    TABLE_NAME=$2

    HEADER_FILE="${OUTDIR:-.}/${TABLE_NAME}.header"
    DAT_FILE="${OUTDIR:-.}/${TABLE_NAME}.dat"
    CTL_FILE="${OUTDIR:-.}/${TABLE_NAME}.ctl"

    create_dat_file $sheet_no
    create_ctl_file
    rm $HEADER_FILE
}

if [ $# == 0 ] ; then
    echo "no argument"
    exit 1
fi

while getopts o: opt $@ ; do
    case "$opt" in
        "o") OUTDIR=$OPTARG;;
        *) break;;
    esac
done

shift $((OPTIND-1))

echo $@
for f in $@ ; do
    EXCEL_FILE=$f
    xlhtml -asc -dp $EXCEL_FILE \
        | perl -ne 'print "$1 $2\n" if /^Page:(\d+) Name:(\w+)/' \
        | while read line; do eval parse_excel $line; done
done

