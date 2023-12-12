#!/bin/bash

source "function.sh"
source "conn.sh"

# Initialize variables
PARENT_NODE="Root"

# Function to display usage
usage() {

	echo ""
	echo "Usage: $0 <command> [options]"
	echo ""
	echo "Commands:"
	echo "  add     Add nodes or files"
	echo "  show    Show node hierarchy"
	echo "  remove  Remove nodes or files"
	echo "  info    Display file path"
	echo ""
	echo "Options:"
	echo "  -n  <c_node>                Specify the child node"
	echo "  -pl <parent_list_file>      Specify a parent list file"
	echo "  -p  <p_node>                Specify a parent node"
	echo "  -f  <file_n>                Specify a file"
	echo "  -fl <file_list>             Specify a file list"
	echo ""
	#echo "Note: When adding a node, use 'Root' as the parent node for those that don't have any parent. If you don't specify a parent node, it will default to 'Root'."
	echo ""	
	echo "Example:"
		echo ""
		#echo "================ update node-node table ADD child_node with multiple parents  ================="
		echo "-Add Nodes"
		#echo ""
		echo "  $0 add -n <c_node> [-pl <parent_file_list>]"
		#echo ""
		# echo "======================= update node-node table ================================"
		echo "  $0 add -n <c_node> [-p <p_node>]"

		echo ""
		#echo "=================== update file-node table  =========================="
		echo "-Add files"
		echo "  $0 add -f <file_name> [-p <fp_node>]"
		#echo "  - Add a node with an optional parent node (default is 'Root')"
		#echo ""
		#echo "================== update file-node table from file-list file ================="
		echo "  $0 add -fl <file_list> -p <parent_node>"
		
		#echo "                     -fl <file_list.txt>     Create a file with list of files that you want to update in a database"
		#echo "                     <file_list> File should be present in files path and mention the complete path of <file_list> in the command"
		echo "  $0 add -f <file_name> -pl <parent_file_list>"
		echo "  $0 add -fl <file_list> -pl <parent_file_list>"
		echo ""
		echo "-Searching Node Hierarchy"
		
		echo "  $0 show -n <node_name>"
		echo "  $0 show -pl <parent_list_file> "
		echo "  $0 show -f <file_name>		it display the parent node "
		echo "  $0 info -f <file_name> 		it display the path of the file"

		echo ""
		echo "-Remove files"
		echo "  $0 remove -f <file_n>"
		echo "  $0 remove -fl <file_list> "
		echo ""
		echo "-Remove nodes"
		echo " $0 remove -n <file_n>"
		echo " $0 remove -pl <file_list> "
	echo ""

}


# Common MySQL command parameters
mysql_command="$mysql_path -s -u $DB_USER -h $DB_HOST -D $DB_NAME"


# Parse command-line arguments for adding nodes 

if [[ "$1" == "add" && ( "$2" == "-n" || "$2" == "-f" || "$2" == "-fl" ) && -n "$3" ]]; then

	case "$2" in
		-n)
			for_node="$2"
			CHILD_NODE="$3"
			;;
		-f)
			for_file="$2"
			user_file="$3"
			 
			user_file_check 	
			;;

		-fl) 
			for_file="$2"
			u_file="$3"
			file_list_check
			;;     

	esac

	if [ $# -eq 3 ]; then
		# If the user provides only three arguments, set default values for "$4" and "$5"
		ARG4="-p"
		ARG5="Root"
	else 
		ARG4="$4"
		ARG5="$5"
	fi

	case "$ARG4" in
					
		-p)
			user_parent_node="$ARG5"
			# echo "yes this is parent check, parent is: $user_parent_node"
			;;
		-pl)
			parent_list_check
			;;    
		*) 
			echo "Invalid option"
			usage
			;; 
			
	esac

	### function file start

	#### function file end

	#Conditions to check parent and child node exists in the databases
	#if [[ "$for_node" == "-n" ]];then

	while IFS= read -r PARENT_NODE; do
					
		# echo "$PARENT_NODE"
		check_parent="SELECT c_node, p_node FROM tagger_node_node WHERE c_node='$PARENT_NODE' or p_node='$PARENT_NODE';"
		parent_check=$($mysql_command -e "$check_parent")

		#echo "this is PN that is avalable in db: $parent_check" 
		
		#if added parent exists in n_n table
		if [ ! -z "$parent_check" ]; then      # ! -z is for not empty
		
			#echo "This is parent node check, here parent node is exists in DB"
			#if parent node is exists then check child node is exists or not 
			is_descen_ances				

		else 
			#else adding parent not exists in n_n
			#parent_chk variable  is empty, means parent node not found in database(n_n)
	
			#echo "This is parent node check (parent node not found in the database, it adds with root node)"
			#if parent not exists in database then create parent as Root and insert parent node in child_node column of n_n table
			parent_insert_with_root="INSERT IGNORE INTO tagger_node_node (p_node, c_node) VALUES ('Root','$PARENT_NODE');"
			
			$mysql_command -e "$parent_insert_with_root"
			remove_doubleroot="delete from tagger_node_node where c_node='Root' and c_node='Root'"
			$mysql_command -e "$remove_doubleroot"
			
			#echo "[Warning:] Parent node $PARENT_NODE not found in the database, so it will add with Root node";
			echo "added CHILD-NODE: $PARENT_NODE  with PARENT-NODE: Root"

			#####is_child_exists
			is_descen_ances

				
		fi
	done <<< "$user_parent_node"

elif [[ "$1" == "remove" && ( "$2" == "-n" || "$2" == "-pl" || "$2" == "-f" || "$2" == "-fl" ) && -n "$3" ]]; then
	
	read -p "Are you sure you want to use remove command [Y/N]: " var
	# Convert user input to lowercase for case-insensitive comparison
	user_call=$(echo "$var" | tr '[:upper:]' '[:lower:]')

	if [ "$user_call" == "y" ] || [ "$user_call" == "yes" ]; then
		if [[  $# -gt 3 ]]; then 
			echo "Invalid parameter"
			exit 1
		fi;
		
		if  [[ "$2" == "-n" ]]; then
			#NODE="$2"
			for_node="$2"
			CHILD_NODE="$3"
			remove_node_relation

		elif [[ "$2" == "-pl" ]]; then
			ARG5="$3"
			parent_list_check
			#echo "write delete query from parent list"
			remove_node="$user_parent_node"

			while IFS= read -r CHILD_NODE; do
				remove_node_relation
			done <<< "$remove_node"


		elif [[ "$2" == "-f" ]]; then
			
			for_file="$2"
			user_file="$3"
			
			#user_file_check
			system_path=$(readlink -f "$3")
			only_file=$(basename "$system_path")
			remove_files

		elif [[ "$2" == "-fl" ]]; then
			for_file="$2"
			u_file="$3"
			user_file=$(<"$u_file")

			#file_list_check
			
			while IFS= read -r line; do             

				# eval echo $line is use tp read ~ sign
				line=$(eval echo "$line");              

				system_path=$(readlink -f "$line"); 
				#echo "systempath is : $system_path";
				only_file=$(basename "$system_path");
				#echo "only file is : $only_file";
				remove_files

			done <<< "$user_file";
		fi
	else
		echo "Removal canceled."
		exit 1
	fi

elif [[ "$1" == "show" && ( "$2" == "-n" || "$2" == "-pl" || "$2" == "-f" ) && -n "$3" ]]; then

	if [[  $# -gt 3 ]]; then 
		echo "Invalid parameter"
		exit 1
	fi

	#To display the node hierarchy and files under searched node 
	if [[ "$2" == "-n" ]]; then
		NODE="$3"
		echo "Node $NODE Hierarchy"
		searching_nodes_hierarchy
		echo "Files under $NODE hierarchy"
		Search_node_get_files
	
	#To display the parent node for searched file 
	elif [[ "$2" == "-f" ]]; then
		searching_file="$3"
		#MYSQL_QUERY="SELECT fp_node as 'parent node for searching file' FROM tagger_file_node WHERE file_n='$searching_file';"
        MYSQL_QUERY="SELECT t1.fp_node as 'parent node for searching file', t2.system_path as 'system_path' FROM tagger_file_node as t1 JOIN tagger_file_info as t2 ON t1.file_path_id=t2.file_path_id WHERE t1.file_n='$searching_file';"
		#$mysql_command -u "$DB_USER" -D "$DB_NAME" -e "$MYSQL_QUERY"
        #get parent node of the searching file
        parent_node=$($mysql_command -u "$DB_USER" -D "$DB_NAME" -e "$MYSQL_QUERY")

		if [ -z "$parent_node" ]
		then
			echo "[Error:] File Not exists"
        else
            echo "parent node and system path of searching file:"
            echo "$parent_node" 
		fi
		
	#It display hierarchy of searching nodes (in coloumn format) it also display the comman nodes and Intesection files between searching nodes.
	elif [[ "$2" == "-pl" ]] && [[ -f "$3" ]]; then
		rm -f /tmp/nodes	
		while IFS= read line
		do 
			NODE="$line"
			
			# Create a temporary file
			temp_file=$(mktemp)
			# store the function's output to the temporary file
			searching_nodes_hierarchy > "$temp_file"  
			
			# Use paste command to combine the columns with tabs as separators
			paste -d'\t' -s - < "$temp_file" >> /tmp/nodes 
			rm -f "$temp_file"  # Remove the temporary file

		done < "$3"
			

		row_to_col /tmp/nodes /tmp/nodes_column
		echo "Searching nodes hierarchy : "
		#cat nodes_column | sed 's/Node_hierarchy//g'
		cat /tmp/nodes_column

		################ Find common nodes  while searching multiple parents using grep
		# call "extract_common" function with argments
		extract_common /tmp/nodes_column /tmp/nodes
	

		############################# Find commom nodes end

		########################## find common files start
		rm -f files
		while IFS= read line
		do
			NODE="$line"

			temp_file=$(mktemp)  # Create a temporary file
			#searching_nodes_hierarchy > "$temp_file"  # Write the function's output to the temporary file
			Search_node_get_files > "$temp_file"
			#   echo "$NODE" >> "$temp_file"  # Append the current node to the temporary file
			paste -d'\t' -s - < "$temp_file" >> /tmp/files # Use paste to combine the columns with tabs as separators			
			rm "$temp_file"  # Remove the temporary file
		done < "$3"

		#cat files
		#call  row_to_col function
		row_to_col /tmp/files /tmp/files_column 
		#cat files_column
		extract_common /tmp/files_column /tmp/files
		
		######################### find common files end

		rm -f /tmp/files /tmp/files_column /tmp/find_intersection /tmp/nodes /tmp/nodes_column

	fi
		
elif [[ "$1" == "info" && "$2" == "-f" && -n "$3" ]]; then

	searching_file="$3"
	
	file_information="SELECT system_path as 'file path information' FROM tagger_file_info WHERE file_name='$searching_file';"
	info=$($mysql_command -e "$file_information")
	if [ -z "$info" ]; then
		echo "file not exists"
	else
		echo "$info"
	fi


else
    echo ""
    #echo "[ERROR: ] Invalid Parameter"
    usage
fi
