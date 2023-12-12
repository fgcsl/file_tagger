-- init.sql

-- Create the database
CREATE DATABASE IF NOT EXISTS <database_name>;

-- Switch to the created database
USE <database_name>;

-- Create the second table file information (path of the file)
CREATE TABLE IF NOT EXISTS tagger_file_info (
    file_path_id INT PRIMARY KEY AUTO_INCREMENT,
    file_name VARCHAR(255) NOT NULL,
    system_path TEXT NOT NULL,
    UNIQUE(file_name(255), system_path(255))
);

-- Create the third table with a foreign key reference file_name and file_parent_node
CREATE TABLE IF NOT EXISTS tagger_file_node (
    file_path_id INT,
    file_n VARCHAR(255) NOT NULL,
    fp_node VARCHAR(80) NOT NULL,
    UNIQUE(file_n, fp_node),
    FOREIGN KEY (file_path_id) REFERENCES tagger_file_info(file_path_id)
);


-- Create the first table node node relationship
CREATE TABLE IF NOT EXISTS tagger_node_node (
    id INT AUTO_INCREMENT PRIMARY KEY,
    c_node VARCHAR(80) NOT NULL,
    p_node VARCHAR(80) NOT NULL,
    UNIQUE(c_node, p_node)
);
