# File Tagger Tool
### Overview
The File Tagger Tool is a command-line interface (CLI) utility designed to simplify file management in bioinformatics labs. This tool addresses the challenge of efficiently locating files within complex directory structures commonly found in server-based environments with extensive datasets.

### Problem Statement
In bioinformatics labs, server systems often house vast amounts of data organized in numerous directories and subdirectories. Locating specific files without knowing their names can be a daunting task, and traditional methods like the 'locate' command may prove ineffective. Manually traversing directories using the 'cd' command is time-consuming.

### Solution
The File Tagger Tool provides an effective solution by implementing a hierarchical ontology structure using a MySQL database. Users can create and manage nodes representing categories and associate files with these nodes. This approach streamlines the process of organizing and retrieving files, making it significantly more efficient.

### Key Features
- Hierarchical Node Structure: Create a hierarchical structure of nodes to represent the organization of files. Nodes can be nested to create a meaningful ontology.

- Tagging Files: Tag files to specific nodes, making it easy to categorize and locate them later. The tool provides commands to add files to nodes based on the file's relevance.

- Command-Line Interface: Access the tool through a user-friendly command-line interface, allowing for quick and efficient interaction.

### Getting Started
1. Set Up Database:

- Create a new MySQL database.
- Set a username and password for the database.
- Edit the init.sql file with your MySQL username and password.

2. Run SQL Script: Execute the SQL script to set up the necessary database structure.

```
mysql -u your_username -p < init.sql>
```

3. Installation: Clone the repository and install the required dependencies.
```
git clone https://github.com/fgcsl/file_tagger
cd file-tagger
```

4. Usage: Run the tool and start organizing your files.

### Usage Example 
#### Usage: run.sh <command> [options]

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


