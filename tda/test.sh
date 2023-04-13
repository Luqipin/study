read -r -d '' my_var << 'EOF'
This is a string with a 'single quote' and a "double quote"
$variable1 and $variable2
EOF
echo "$my_var"

