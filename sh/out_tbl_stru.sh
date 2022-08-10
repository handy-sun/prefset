#!/bin/bash
tbl_name=$1
file="$HOME/atca/components/application/call_handling/interface/libTkDataXIf/inc/TdhDataRec.hh"
reg_content=`grep -nE "typedef struct|$tbl_name" $file | grep -n $tbl_name`
varl=`grep -nE "typedef struct|$tbl_name" $file | grep $tbl_name | cut -f1 -d:`
lnum=`echo $reg_content | cut -f1 -d:`
stru_linenum=$((lnum-1))
pre_content=`grep -nE "typedef struct|$tbl_name" $file | head -n $stru_linenum | tail -1 | cut -f1 -d:`
cat $file | head -n $varl | tail -n $(($varl-$pre_content+1))