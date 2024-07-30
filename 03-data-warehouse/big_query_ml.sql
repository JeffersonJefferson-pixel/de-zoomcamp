-- Select columns of interest
SELECT passenger_count, trip_distance, PULocationID, DOLocationID, payment_type, fare_amount, tolls_amount, tip_amount
FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned` WHERE fare_amount != 0;

-- Create an ML table with appropriate type
CREATE OR REPLACE TABLE `terraform-demo-429506.demo_dataset.yellow_tripdata_ml` (
  `pasenger_count` INTEGER,
  `trip_distance` FLOAT64,
  `PULocationID` STRING,
  `DOLocationID` STRING,
  `payment_type` STRING,
  `fare_amount` FLOAT64,
  `tolls_amount` FLOAT64,
  `tip_amount` FLOAT64
) AS (
  SELECT passenger_count, trip_distance, cast(PULocationID AS STRING), CAST(DOLocationID AS STRING), 
  CAST(payment_type AS STRING), fare_amount, tolls_amount, tip_amount
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_partitioned` WHERE fare_amount != 0
);

-- Create model with default setting
CREATE OR REPLACE MODEL `terraform-demo-429506.demo_dataset.tip_model`
OPTIONS
(
  model_type = 'linear_reg',
  input_label_cols = ['tip_amount'],
  DATA_SPLIT_METHOD='AUTO_SPLIT'
) AS (
  SELECT * 
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_ml`
  WHERE tip_amount IS NOT NULl
);

-- Check features
SELECT * FROM ML.FEATURE_INFO(MODEL `terraform-demo-429506.demo_dataset.tip_model`);

-- Evaluate the model
SELECT *
FROM ML.EVALUATE(MODEL `terraform-demo-429506.demo_dataset.tip_model`, (
  SELECT * 
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_ml`
  WHERE tip_amount IS NOT NULL
));

-- Predict
SELECT * 
FROM ML.PREDICT(MODEL `terraform-demo-429506.demo_dataset.tip_model`, (
  SELECT * 
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_ml`
  WHERE tip_amount IS NOT NULL
));

-- Predict and explain 
SELECT * 
FROM ML.EXPLAIN_PREDICT(MODEL `terraform-demo-429506.demo_dataset.tip_model`, (
  SELECT * 
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_ml`
  WHERE tip_amount IS NOT NULL
), STRUCT(3 AS top_k_features));


-- Hyper param tuning
CREATE OR REPLACE MODEL `terraform-demo-429506.demo_dataset.tip_hyperparam_model`
OPTIONS (
  model_type = 'linear_reg',
  input_label_cols=['tip_amount'],
  DATA_SPLIT_METHOD='AUTO_SPLIT',
  num_trials=5,
  max_parallel_trials=2,
  l1_reg=hparam_range(0, 20),
  l2_reg=hparam_candidates([0, 0.1, 1, 10])
) AS (
  SELECT * 
  FROM `terraform-demo-429506.demo_dataset.yellow_tripdata_ml`
  WHERE tip_amount IS NOT NULL 
);