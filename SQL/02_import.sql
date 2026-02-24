-- Import danych: używamy polecenia LOAD DATA INFILE, aby zaimportować dane z plików CSV do tabel olist_orders i olist_order_items
-- Praca z lokalnymi ścieżkami: zmień poniższe ścieżki na własne przed uruchomieniem
LOAD DATA INFILE 'path/to/file' 
INTO TABLE olist_orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

LOAD DATA INFILE 'path/to/file.csv' 
INTO TABLE olist_order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;