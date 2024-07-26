-- Query public available table
SELECT station_id, name FROM 
  bigquery-public-data.new_york_citibike.citibike_stations
LIMIT 100;

-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `terraform-demo-429506.demo_dataset.external_yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris  = ['gs://terraform-demo-429506-terra-bucket/ny_taxi_data/tpep_pickup_date=2021-01-*']
);

-- check yellow trip data
SELECT * FROM terraform-demo-429506.demo_dataset.external_yellow_tripdata limit 10;

-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE terraform-demo-429506.demo_dataset.yellow_tripdata_non_partitioned AS 
SELECT * FROM terraform-demo-429506.demo_dataset.external_yellow_tripdata;

-- Create a partitioned table from external table
CREATE OR REPLACE TABLE terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned
PARTITION BY
  DATE(tpep_pickup_datetime) AS
SELECT * FROM terraform-demo-429506.demo_dataset.external_yellow_tripdata;

-- Impact of partition
-- Query scans 18.99 MB of data
SELECT DISTINCT(VendorID)
FROM terraform-demo-429506.demo_dataset.yellow_tripdata_non_partitioned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-01-15';

-- Query scans 8.88 MB of data 
SELECT DISTINCT(VendorID)
FROM terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-01-15';

-- look into partitions
SELECT table_name, partition_id, total_rows
FROM `demo_dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_trip_partitioned'
ORDER BY total_rows DESC;

-- Create a partitioned and clustered table
CREATE OR REPLACE TABLE terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned_clustered
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS 
SELECT * FROM terraform-demo-429506.demo_dataset.external_yellow_tripdata;

-- Query scans 8.99 MB 
SELECT COUNT(*) as trips
FROM terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned 
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-01-15'
  AND VendorID=1;

-- Query scans 8.01 MB
SELECT COUNT(*) as trips 
FROM terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned_clustered
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-01-15'
  AND VendorID=1;