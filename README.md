# file_tagger


### Usage: run.sh <command> [options]

#### Commands:
```
  add     Add nodes or files
  show    Show node hierarchy
  remove  Remove nodes or files
```
#### Options:
```
  -n  <c_node>                Specify the child node
  -pl <parent_list_file>      Specify a parent list file
  -p  <p_node>                Specify a parent node
  -f  <file_n>                Specify a file
  -fl <file_list>             Specify a file list
```
Note: When adding a node, use 'Root' as the parent node for those that don't have any parent. If you don't specify a parent node, it will default to 'Root'.

Example:

-Add Nodes
```
 $ run.sh add -n <c_node> [-pl <parent_file_list>]
 $ run.sh add -n <c_node> [-p <p_node>]
```

-Add files
```
 $ run.sh add -f <file_name> [-p <fp_node>]
 $ run.sh add -fl <file_list> -p <parent_node>
 $ run.sh add -f <file_name> -pl <parent_file_list>
 $ run.sh add -fl <file_list> -pl <parent_file_list>
 ```

-Searching Node Hierarchy
```
  run.sh show -n <node_name>
  run.sh show -pl <parent_list_file> 
  run.sh show -f <file_name>		it display the parent node 
  run.sh info -f <file_name> 		it display the path of the file
```
-Remove files
```
  run.sh remove -f <file_n>
  run.sh remove -fl <file_list> 
```
-Remove nodes
```
 run.sh remove -n <file_n>
 run.sh remove -pl <file_list> 
```
