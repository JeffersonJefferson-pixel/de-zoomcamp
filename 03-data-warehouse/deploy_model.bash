bq --project_id terraform-demo-429506 extract -m demo_dataset.tip_model gs://terraform-demo-429506-terra-bucket/tip_model
mkdir /tmp/model
gsutil cp -r gs://terraform-demo-429506-terra-bucket/tip_model /tmp/model
mkdir -p serving_dir/tip_model/1
cp -r /tmp/model/tip_model/* serving_dir/tip_model/1
docker pull tensorflow/serving
docker run -p 8501:8501 --mount type=bind,source=`pwd`/serving_dir/tip_model,target=/models/tip_model -e MODEL_NAME=tip_model -t -d tensorflow/serving