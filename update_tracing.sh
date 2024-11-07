#!/bin/bash

./scripts/trace_on.sh && \
	./run_trace.sh && \
	source data_processing/.venv/bin/activate && \
	python data_processing/tracing.py && \
	python data_processing/visualize.py
