: '
UVM_PATH=$PWD/../../uvm
export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH
for SCHEME in "uvm" "uvm_h2o"
do
  g++ $UVM_PATH/allocate.cpp -o allocate.so --shared -fPIC -I$CUDA_HOME/include
  CMD="--embed_dim 5120 --ffn_dim 20480 --enable_bias --n_head 40 --do_layer_norm_before --n_layer 40 --bsz 20 --prompt_len 1920 --gen_len 128 --runs 1"
  
  if [ "$SCHEME" = "uvm_h2o" ]
  then 
    CMD=$CMD" --is_h2o --h2o_ratio 0.2"
  fi
  python $UVM_PATH/transformer.py $CMD
  rm allocate.so
done
'
FLEXGEN_PATH=$PWD/../../flexgen
for SCHEME in "ibp_compress" #"ibp" "ibp_compress" "infinigen" #"ibp_validate" "ibp_compress" "ibp" "original" #"int4" "h2o" 
do
  rm $FLEXGEN_PATH/flexgen/flex_opt.py
  rm $FLEXGEN_PATH/flexgen/flex_gemma.py
  rm $FLEXGEN_PATH/flexgen/pytorch_backend.py
  if [ "$SCHEME" = "int4" ]
  then
    ln -s ../original/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
    ln -s ../original/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
  elif [ "$SCHEME" = "ibp" ] || [ "$SCHEME" = "ibp_compress" ] || [ "$SCHEME" = "ibp_validate" ]
  then
    ln -s ../infinigen/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
    ln -s ../infinigen/flex_gemma.py $FLEXGEN_PATH/flexgen/flex_gemma.py
    ln -s ../infinigen/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
  else
    ln -s ../$SCHEME/flex_opt.py $FLEXGEN_PATH/flexgen/flex_opt.py
    ln -s ../$SCHEME/pytorch_backend.py $FLEXGEN_PATH/flexgen/pytorch_backend.py
  fi

  MODEL="google/gemma-7b-pytorch"
  TYPE="flex_gemma"
  #MODEL="facebook/opt-6.7b"

  CMD="--model ${MODEL} --percent 100 0 0 100 0 100 --overlap false --gpu-batch-size 20 --num-gpu-batches 1 --prompt-len 1920 --gen-len 128 --warmup-input-path pg19_firstbook.txt --test-input-path pg19_firstbook.txt"
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
  fi
  echo "python -m flexgen.${TYPE} ${CMD}"
  python -m flexgen.${TYPE} $CMD
  sleep 10
done
