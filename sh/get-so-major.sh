str="$1"
bo_re=`echo "$str" | grep -bo "\.so"`
idx=${bo_re%:*}
lib_name=${str:0:$idx}
onedot_num=`expr "$str" : ".*\.so\(\(.[0-9]\+\)\{1\}\)"`
echo "${lib_name}.so${onedot_num}"
# total - left(.so+.[0-9]+)
total_count=`echo "$str" | grep -o "\." | wc -l`
r_count=$((${total_count}-2))
expr "$str" : ".*\(\(.[0-9]\+\)\{$r_count\}\)" 