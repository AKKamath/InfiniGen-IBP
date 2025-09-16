SHELL := /bin/bash
run_expt:
	pushd speedup/scripts/figure14/ && \
	sh run.sh > ../../../figure14.log; \
	popd;

run_live_expt:
	pushd speedup/scripts/figure14/ && \
	sh run.sh; \
	popd;
