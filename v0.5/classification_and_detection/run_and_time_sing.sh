#!/bin/bash

source run_common.sh

singularitycmd=singularity
imageurl="library://fenz/mlperf/inference-v0.5:class_and_det"
image="mlperf_infer-v0.5_class_and_det"
IMAGEDIR=${IMAGEDIR:-$HOME}

if [ $device == "gpu" ]; then
    image=$image"-gpu.sif"
    imageurl=$imageurl"-gpu"
    runtime="--nv"
    GPUS=${GPUS:-all}
    CUDA_VISIBLE_DEVICES=$GPUS
else
    image=$image"-intelcpu.sif"
    imageurl=$imageurl"-intelcpu"
fi

if [ ! -f $IMAGEDIR/$image ]; then
    singularity pull $IMAGEDIR/$image $imageurl
fi

# copy the config to cwd so the docker contrainer has access
cp ../mlperf.conf .

OUTPUT_DIR=`pwd`/output/$name
if [ ! -d $OUTPUT_DIR ]; then
    mkdir -p $OUTPUT_DIR
fi

export opts="--config ./mlperf.conf --profile $profile $common_opt --model $model_path \
    --dataset-path $DATA_DIR --output $OUTPUT_DIR $extra_args $EXTRA_OPS $@"

echo "Clearing caches."
sudo /bin/bash -c "sync && echo 3 | tee /proc/sys/vm/drop_caches"

$singularitycmd run $runtime\
  -B $DATA_DIR:$DATA_DIR -B $MODEL_DIR:$MODEL_DIR \
  -B $OUTPUT_DIR:/output\
  $IMAGEDIR/$image /mlperf/run_helper.sh 2>&1 | tee $OUTPUT_DIR/output.txt
