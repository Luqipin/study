#!/bin/bash
#author luqp

echo "使用方法 tda.sh db_type table data_date"
echo "db_type:数据库类型 table:表名 data_date:数据日期 "

if [ $# -ne 3 ]; then
	echo "您输入$#个参数，参数不对，请检查！"
	exit 1
fi

db_type=$1
table=$2
data_date=$3

if [ ${db_type} == 'hive' ]; then
	echo "导出数据库${db_type}"
	while read line; do
		config_name=$(echo "$line" | cut -d = -f 1|  rev |cut -c 2- | rev )
		TERMINATED=$(echo "$line" | cut -d = -f 1 | rev |cut -c -1 )
		exp_sql=$(echo "$line" | cut -d = -f 2 )
		if [ "$config_name" == ${table} ]; then
			echo "正在导出${table}"

			read -r -d '' v_exp << 'EOF'
            INSERT OVERWRITE  DIRECTORY '/var/hive/warehouse/data_output/${data_date}/${table_name}'
            ROW FORMAT DELIMITED
            FIELDS TERMINATED BY '${delimiter}'
            ${sql}
EOF


			
			
			v_exp=${v_exp//\$\{sql\}/${exp_sql}}
			v_exp=${v_exp//\$\{delimiter\}/${TERMINATED}}
			v_exp=${v_exp//\$\{data_date\}/${data_date}}
			v_exp=${v_exp//\$\{table_name\}/${table}}
			echo "导出语句
			${v_exp}
			"
			hive -e "$(cat <<EOF
${v_exp}
EOF
)"
	if [ -f /root/data/${data_date}/${table}.txt ];then
		rm /root/data/${data_date}/${table}.txt
	fi
	# hadoop fs -get /var/hive/warehouse/data_output/${data_date}/${table}/000000_0 /root/data/${data_date}/${table}.txt
	hadoop fs -getmerge /var/hive/warehouse/data_output/${data_date}/${table} /root/data/${data_date}/${table}.txt
	hadoop fs -rm -r /var/hive/warehouse/data_output/${data_date}/${table}
		else
			echo "未找到${table}配置，请检查tda.cfg！"
		fi
	done < tda.cfg

elif [ ${db_type} == 'mysql' ]; then
	echo "导出数据库${db_type}"
		while read line; do
		config_name=$(echo "$line" | cut -d = -f 1|  rev |cut -c 2- | rev )
		TERMINATED=$(echo "$line" | cut -d = -f 1 | rev |cut -c -1 )
		exp_sql=$(echo "$line" | cut -d = -f 2 )
		
		sql_1=$(echo "$exp_sql" | awk -F "from" '{print $1}' | sed 's/[[:space:]]*$//')
		sql_2=$(echo "$exp_sql" | awk -F "from" '{print $2}')

		if [ "$config_name" == ${table} ]; then
			echo "正在导出${table}"

			read -r -d '' v_exp << 'EOF'
            ${sql_1}
            INTO OUTFILE '/root/data/${data_date}/${table_name}.txt'
            FIELDS TERMINATED BY '${delimiter}'
            from ${sql_2}

EOF


			
			
			v_exp=${v_exp//\$\{sql_1\}/${sql_1}}
			v_exp=${v_exp//\$\{sql_2\}/${sql_2}}
			v_exp=${v_exp//\$\{delimiter\}/${TERMINATED}}
			v_exp=${v_exp//\$\{data_date\}/${data_date}}
			v_exp=${v_exp//\$\{table_name\}/${table}}
			echo "导出语句
			${v_exp}
			"

	if [ -f /root/data/${data_date}/${table}.txt ];then
		rm /root/data/${data_date}/${table}.txt
	fi

		else
			echo "未找到${table}配置，请检查tda.cfg！"
		fi
	done < tda.cfg
	
	
elif [ ${db_type} == 'oracle' ]; then
	echo "导出数据库${db_type}"
else
	echo "不支持导出${db_type}数据库!"
fi


