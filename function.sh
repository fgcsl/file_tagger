    #### function is_child_exists() start

is_descendant() {

        desc_MYSQL_QUERY="WITH RECURSIVE NodeHierarchy AS (
                SELECT id, c_node, p_node FROM test2_n_n WHERE BINARY p_node = '$PARENT_NODE'
                UNION ALL
                SELECT tn.id, tn.c_node, tn.p_node
                FROM test2_n_n tn
                JOIN NodeHierarchy nh ON nh.c_node = tn.p_node 
                )
                SELECT * from  NodeHierarchy"

                # child node search in child node col of desc_MYSQL_QUERY heirarchy
                child_search=$("$mysql_path" -s -u "$DB_USER" -h "$DB_HOST" -D "$DB_NAME" -e "$desc_MYSQL_QUERY" | awk -v child_node="$CHILD_NODE" '$2 == child_node {print $2}')

                # for file check in descendant heirarchy
                descendant_list=$("$mysql_path" -s -u "$DB_USER" -h "$DB_HOST" -D "$DB_NAME" -e "$desc_MYSQL_QUERY" | awk '{print $2}')
                #echo "$descendant_list"
        
                file_search=$(while IFS= read -r node; do
                                while IFS= read -r  file_is; do
                                    file_is=$(eval echo "$file_is");              # eval echo $file_is is use tp read ~ sign
                                    file_path=$(readlink -f "$file_is");
                                    file_name=$(basename "$file_path");
                                    search_file_query="select * from test2_f_n where BINARY fp_node='$node' AND file_n='$file_name'"
                                    $mysql_command -e "$search_file_query"
                                done <<< "$user_file"

                        done <<< "$descendant_list")
                        
                
}

    

is_ancestor() {

    anc_MYSQL_QUERY="WITH RECURSIVE NodeHierarchy AS (                                         
            SELECT id, c_node, p_node FROM test2_n_n WHERE BINARY c_node = '$PARENT_NODE'                                         
            UNION ALL
            SELECT tn.id, tn.c_node, tn.p_node
            FROM test2_n_n tn
            JOIN NodeHierarchy nh ON nh.p_node = tn.c_node
            ) 
            SELECT id, c_node, p_node FROM NodeHierarchy"
            
    parent_search=$($mysql_command -e "$anc_MYSQL_QUERY" | awk -v child_node="$CHILD_NODE" '$3 == child_node {print $3}')
    anc_hierarchy=$($mysql_command -e "$anc_MYSQL_QUERY")

    anc_hierarchy_pl=$($mysql_command -e "$anc_MYSQL_QUERY" | awk '{print $3}')        
                
}

#Child search in ancestor
child_search_in_anc_node() {
        
    desc_MYSQL_QUERY="SELECT id, c_node, p_node FROM test2_n_n WHERE BINARY p_node = '$parent_list' AND c_node='$CHILD_NODE'"
    $mysql_command -e "$desc_MYSQL_QUERY"
    parent_file_search=$(while IFS= read -r node; do
                search_file_query="select * from test2_f_n where BINARY fp_node='$node' AND file_n='$file_name'"
                $mysql_command -e "$search_file_query"
            done <<< "$anc_hierarchy_pl")
    
}

node_parent_insertion() {
    
    loop_child_search=$(while IFS='' read -r parent_list; do
                            # echo "Descendant of $parent_list"
                            child_search_in_anc_node
                            done <<< "$anc_hierarchy_pl")
    
    delete_from_db=$(echo "$loop_child_search" | awk '!seen[$1]++ {print $1}')
    #echo "delete this id from database: '$delete_from_db'"

    #Use while loop for removing ids from node node graph because it can be multiple in diffrent direction
    while IFS= read -r id; do    
        # echo "CHILD NODE : $CHILD_NODE found in decendant hierarchy of Parent Node ancestor with id :$id"
        # remove existing relations with child node and add a new relation
        remove_relation="DELETE FROM test2_n_n WHERE id='$id'"
        $mysql_command -e "$remove_relation"
        
    done <<< "$delete_from_db"
    
    insert_new_relation="INSERT IGNORE INTO test2_n_n (p_node, c_node) VALUES ('$PARENT_NODE', '$CHILD_NODE');"
    $mysql_command -e "$insert_new_relation"


    if [ $? -eq 0 ]
    then
        echo "added CHILD-NODE: $CHILD_NODE  with PARENT-NODE: $PARENT_NODE"
            
    else
        echo "[Error:] Not inserted"
    fi
}

file_node_insertion() {

    while IFS= read -r  line; do
        #echo "inside_loop"
        #echo "$PARENT_NODE"
        line=$(eval echo "$line");              # eval echo $line is use tp read ~ sign

        file_path=$(readlink -f "$line");
        
        file_name=$(basename "$file_path");
        #echo "file nanme is : $file_name";
        #echo "$anc_hierarchy_pl"
        parent_file_search=$(while IFS= read -r node; do
                        search_file_query="select * from test2_f_n where BINARY fp_node='$node' AND file_n='$file_name'"
                        $mysql_command -e "$search_file_query"
                done <<< "$anc_hierarchy_pl")

        delete_from_f_n="$(echo "$parent_file_search"| awk '!seen[$1]++ {print $1}')"
        #echo "delete_from_f_n : $delete_from_f_n"

        remove_relation1="DELETE FROM test2_f_n  WHERE test2_f_n.file_path_id='$delete_from_f_n'"
        remove_relation2="DELETE FROM test2_file_info WHERE test2_file_info.file_path_id='$delete_from_f_n'"
        $mysql_command -e "$remove_relation1"; 
        $mysql_command -e "$remove_relation2";

        insert_new_relation="INSERT IGNORE INTO test2_file_info (file_name, system_path)
        VALUES ('$file_name', '$file_path') ON DUPLICATE KEY UPDATE file_path_id = LAST_INSERT_ID(file_path_id);

        -- Get the auto-generated file_path_id from the first insert
        SET @last_file_path_id = LAST_INSERT_ID();

        -- Insert data into test2_f_n, using the obtained file_path_id
        INSERT IGNORE INTO test2_f_n (file_path_id, file_n, fp_node)
        VALUES (@last_file_path_id, '$file_name', '$PARENT_NODE');"

        $mysql_command -e "$insert_new_relation"

        if [ $? -eq 0 ]
        then
            echo "added FILE: $file_name  with PARENT-NODE: $PARENT_NODE"
                
        else
            echo "[Error:] Not inserted"
        fi
    done <<< "$user_file"
}


is_descen_ances() {


    is_descendant  
    is_ancestor
    child_search_in_anc_node


    #CASE-1 variable used in in this case are belongs to is_descendant() function
    #first check in descendant node for node-node graph
    if [[ ! -z "$child_search" ]]; then # ! -z variable not empty
        # echo "$child_search"
        #echo "Child node: $CHILD_NODE searching on Decendant node...."
        #echo "Child Node: $CHILD_NODE Already exists in Descendant Node"
        exit 1
    #first check in descendant node for file_node(f_n) graph
    elif [[ ! -z "$file_search" ]]; then
        f_name=$(echo "$file_search" | awk '{print $2}')
        #echo "file: $f_name searching on Decendant node...."
        n_name=$(echo "$file_search" | awk '{print $3}')
        #echo "$f_name file already exists in Descendant Node: $n_name"
        exit 1 

    #CASE-2 variable used in  this case are belongs to is_ancestor() function
    #second check for child_node is exists in the list of ancestors node for node_node(n_n) graph
    elif [[ ! -z "$parent_search" ]]; then # ! -z variable not empty
        #echo "Child Node: $CHILD_NODE not exists in descendant nodes, it is searching on Ancestor nodes..."
                
        sleep 1
        #echo "Child Node: $CHILD_NODE Already exists in ancestor node"
        echo "[ERROR: loop formation] Cyclic graph not allowed"
        exit 1

    #Neither CASE-1 or CASE-2  variable used in in this case are belongs to child_search_in_anc_node() function
    else

        #echo "$for_file"
        #echo "$for_node"

        if [[ "$for_node" == "-n" ]];
        then    
            node_parent_insertion
        
        elif [[ ("$for_file" == "-f" || "$for_file" == "-fl") ]];
        then
        
            file_node_insertion
        
        else
        
            echo "invalid option"
        
        fi
            
    fi
}


#remove command

remove_node_relation() {
    #step1: Display the relation of deleting node 
    node_joins="SELECT * FROM test2_n_n WHERE BINARY c_node = '$CHILD_NODE' OR  p_node ='$CHILD_NODE';"
    #echo "delete below relation"
    #$mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$node_joins"

    #step2: Display the parent nodes of new relation
   # echo "new relation with below parent"
    add_parent="SELECT p_node FROM test2_n_n WHERE BINARY c_node ='$CHILD_NODE';"
    parent_nodes=$($mysql_path -s -u "$DB_USER" -D "$DB_NAME" -e "$add_parent")
    #run sql query 
    #echo "$parent_nodes"

    #step3: Display the child nodes of new relation  
    #echo "new relation with below child"
    add_child="SELECT c_node FROM test2_n_n WHERE BINARY p_node ='$CHILD_NODE';"
    child_node=$($mysql_path -s -u "$DB_USER" -D "$DB_NAME" -e "$add_child")
    #run sql query 
    #echo "$child_node"

    #step4: Remove the relation
    remove_n_n="DELETE FROM test2_n_n  WHERE BINARY c_node = '$CHILD_NODE' OR  p_node ='$CHILD_NODE';"
    $mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$remove_n_n"

    #step6: if node contains file, remove node from file relation and info table
    get_id="SELECT file_path_id FROM test2_f_n WHERE BINARY fp_node='$CHILD_NODE'"
    remove_f_n_id=$($mysql_path -s -u "$DB_USER" -D "$DB_NAME" -e "$get_id")

    while IFS= read -r rm_id; do
        remove_f_n="DELETE FROM test2_f_n WHERE BINARY file_path_id='$rm_id'"
        remove_info="DELETE FROM test2_file_info WHERE BINARY file_path_id='$rm_id'"
        $mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$remove_f_n"
        $mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$remove_info"
    done <<< "$remove_f_n_id"

    if [ -z "$child_node" ]; then
        # no need to add new relations for base nodes.
        echo "Removed all the relation with $CHILD_NODE node"
        
    else
        #step5: Insert new relations 
        echo "Establish new relationships with the following parent-child pairs:"
        echo "Child_node parent_node"
        while IFS= read -r pn; do
            while IFS= read -r cn; do
                insert_new_rel="INSERT IGNORE INTO test2_n_n (p_node, c_node) VALUES ('$pn', '$cn');"
                $mysql_path -s -u "$DB_USER" -D "$DB_NAME" -e "$insert_new_rel"	
                echo "$cn		$pn"
            done <<< "$child_node"
        done <<< "$parent_nodes"
    fi

    


}

remove_files(){
    	
        # Delete file query
		remove_fp_relation="DELETE FROM test2_f_n WHERE BINARY file_n='$only_file';"
		remove_file_info="DELETE FROM test2_file_info WHERE BINARY file_name='$only_file';"

		# Execute the query			
		$mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$remove_fp_relation"
		$mysql_path -u "$DB_USER" -D "$DB_NAME" -e "$remove_file_info" 

		#check above code exit with 0(success)
			
		if [ "$?" -eq 0 ]
		then
			echo "Removed File: $only_file"
		else
			echo "[Error:] File Not Removed"
		fi
}



#show functions
sql_recursive_query() {

    RESULT=$($mysql_command -e "$MYSQL_QUERY")
    # Check if the result is empty
    if [ -z "$RESULT" ]; then
        echo "$1"
    else
    # Print the result
    echo "$RESULT"
    fi

}

searching_nodes_hierarchy() {

MYSQL_QUERY="WITH RECURSIVE NodeHierarchy AS (
        SELECT p_node, c_node FROM test2_n_n WHERE BINARY p_node = '$NODE'
        UNION ALL
        SELECT tn.p_node, tn.c_node
        FROM test2_n_n tn
        JOIN NodeHierarchy nh ON tn.p_node = nh.c_node
        )
        SELECT DISTINCT p_node AS result FROM NodeHierarchy
        UNION
        SELECT DISTINCT c_node AS result FROM NodeHierarchy"	
        
error_message="[Error: ] No Hierarchy found for searching node"
sql_recursive_query "$error_message"

    }

Search_node_get_files() {

MYSQL_QUERY="WITH RECURSIVE NodeHierarchy AS (
            SELECT p_node, c_node FROM test2_n_n WHERE BINARY p_node = '$NODE'
            UNION ALL
            SELECT tn.p_node, tn.c_node
            FROM test2_n_n tn
            JOIN NodeHierarchy nh ON tn.p_node = nh.c_node
            )
            -- search all the previous results
            SELECT t1.file_n, t2.system_path FROM test2_f_n as t1 INNER JOIN test2_file_info as t2 on t1.file_n=t2.file_name WHERE fp_node IN (
            SELECT result FROM (
                SELECT DISTINCT p_node AS result FROM NodeHierarchy
                UNION
                SELECT DISTINCT c_node AS result FROM NodeHierarchy
                UNION
                -- if searching node not found in parent column then add it and search to the file table 
                SELECT '$NODE' AS result
            ) AS subquery
            );"

error_message="[Error: ] File not exists on hierarchy list"
sql_recursive_query "$error_message"
											
			}


#show searching nodes as column #change row to col 
row_to_col() {	awk '
    { 
        for (i=1; i<=NF; i++)  {
                a[NR,i] = $i
        }
        }
        NF>p { p = NF }
        END {    
            for(j=1; j<=p; j++) {
                    str=a[1,j]
                for(i=2; i<=NR; i++){
                            str=str" "a[i,j];
                            }
                            print str
                            }
                    }' $1 > $2
    } 

################ Find common nodes  while searching multiple parents using grep
extract_common() {

    searching_hierarchy="$1"
    number_of_column="$(awk 'BEGIN{FS=" "};{print NF}' $searching_hierarchy| sort -n | tail -1)"
    #echo $number_of_column

    # grep the first col in second col

    grep -o -f <(awk '{print $1}' $searching_hierarchy) <(awk '{print $2}' $searching_hierarchy) > /tmp/find_intersection

    # grep the result of previous grep in 3rd col and the result of that in  4th upto  nth col.....
    for i in $(seq 3 "$number_of_column")
        do
        grep -o -f <(awk '{print $1}' /tmp/find_intersection) <(awk -v col="$i" '{print $col}' $searching_hierarchy) > /tmp/tmp_intersection
        cp /tmp/tmp_intersection /tmp/find_intersection
    done

    rm -f /tmp/tmp_intersection

    if [ -s /tmp/find_intersection ]
    then
        echo ""
        echo "common $(basename $2) : " 
        #cat find_intersection | sed 's/Node_hierarchy//g' | sed 's/file_n//g'
        cat /tmp/find_intersection
    else
        echo "No Intesection $(basename $2) found between searching nodes"
    fi
}



