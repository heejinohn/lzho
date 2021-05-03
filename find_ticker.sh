#!/bin/bash
#$ -N ticker
#$ -t 2012-2020
#$ -j y    # join output and error
source ~/virtualenv/lzho/bin/activate
python ~/project/lzho/ticker-$SGE_TASK_ID.py
