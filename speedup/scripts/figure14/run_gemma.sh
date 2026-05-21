TYPE="flex_gemma"
MODEL_LIST="google/gemma-7b-pytorch"

FLEXGEN_PATH=$PWD/../../flexgen
for MODEL in $MODEL_LIST
do
  for SCHEME in "original" # #"original" #"infinigen" #"ibp_compress" #"original" "flex-ibp" # #"ibp" "ibp_compress" #"infinigen" #"ibp" "ibp_compress" "infinigen"
  do
    rm $FLEXGEN_PATH/flexgen/flex_opt.py
    rm $FLEXGEN_PATH/flexgen/flex_gemma.py
    rm $FLEXGEN_PATH/flexgen/pytorch_backend.py
    if [ "$SCHEME" = "int4" ]
    then
      ln -s ../original/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
      ln -s ../original/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
    elif [ "$SCHEME" = "ibp" ] || [ "$SCHEME" = "ibp_compress" ] || [ "$SCHEME" = "ibp_validate" ] || [ "$SCHEME" = "infinigen" ]
    then
      ln -s ../infinigen/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
      ln -s ../infinigen/flex_gemma.py $FLEXGEN_PATH/flexgen/flex_gemma.py
      ln -s ../infinigen/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
    elif [ "$SCHEME" = "flex-ibp" ]
    then
      ln -s ../original/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
      ln -s ../original/flex_gemma.py $FLEXGEN_PATH/flexgen/flex_gemma.py
      ln -s ../original/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
    else
      ln -s ../$SCHEME/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
      ln -s ../$SCHEME/flex_gemma.py $FLEXGEN_PATH/flexgen/flex_gemma.py
      ln -s ../$SCHEME/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
    fi

    CMD="--model ${MODEL} --overlap false --gpu-batch-size 20 --num-gpu-batches 1 --prompt-len 128 --gen-len 20 --warmup-input-path pg19_firstbook.txt --test-input-path pg19_firstbook.txt"
    if [ "$MODEL" = "facebook/opt-30b" ]
    then
      CMD=$CMD" --percent 70 30 0 100 100 0"
    else
      CMD=$CMD" --percent 100 0 0 100 100 0"
    fi
    if [ "$SCHEME" = "int4" ]
    then
      CMD=$CMD" --compress-cache"
    elif [ "$SCHEME" = "h2o" ]
    then
      CMD=$CMD" --max-num-kv 415 --hh-ratio 0.1 --hh-all"
    elif [ "$SCHEME" = "infinigen" ]
    then
      CMD=$CMD" --alpha 4 --partial-weight-ratio 0.2 --max-num-kv 400"
    elif [ "$SCHEME" = "ibp_compress" ]
    then
      CMD=$CMD" --alpha 4 --partial-weight-ratio 0.2 --max-num-kv 400 --ibp=compress"
    elif [ "$SCHEME" = "ibp_validate" ]
    then
      CMD=$CMD" --alpha 4 --partial-weight-ratio 0.2 --max-num-kv 400 --ibp=validate"
    elif [ "$SCHEME" = "ibp" ]
    then
      CMD=$CMD" --alpha 4 --partial-weight-ratio 0.2 --max-num-kv 400 --ibp=transfer"
    elif [ "$SCHEME" = "flex-ibp" ]
    then
      CMD=$CMD" --ibp=compress"
    fi
    echo "python -m flexgen.${TYPE} ${CMD}"
    python -m flexgen.${TYPE} $CMD
    sleep 10
  done
done
