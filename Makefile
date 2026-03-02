SHELL := /bin/bash
OUTPUT ?= $(CURDIR)/figure14.log
run_expt:
	pushd speedup/scripts/figure14/ && \
	bash run.sh > ${OUTPUT} && \
	popd && \
	python plot_fig14.py ${OUTPUT} figure14

run_small_expt:
	pushd speedup/scripts/figure14/ && \
	bash run_small.sh > ${OUTPUT} && \
	popd && \
	python plot_fig14.py ${OUTPUT} figure14

run_live_expt:
	pushd speedup/scripts/figure14/ && \
	sh run.sh; \
	popd;
