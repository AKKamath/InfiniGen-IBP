SHELL := /bin/bash
run_expt:
	pushd speedup/scripts/figure14/ && \
	bash run.sh > ../../../figure14.log && \
	popd && \
	python plot_fig14.py figure14.log figure14

run_live_expt:
	pushd speedup/scripts/figure14/ && \
	sh run.sh; \
	popd;
