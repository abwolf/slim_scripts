#!/bin/bash

#SBATCH --get-user-env
#SBATCH --mem=10G
#SBATCH --time 22:00:00
#SBATCH --qos=1day
#SBATCH --output=slrun.SLiM.calc_admix_prop.single_mutations.sh.%A_%a.o
source ~/.bashrc

date

mdl=$( echo Tenn )

echo $SLURM_JOB_NAME
echo $SLURM_ARRAY_TASK_ID
echo $mdl
echo ''

#Define recombination rate
for recomb in 0.5e-8 1.0e-8 1.3e-8; do
	#Define selection coefficient
	for selec in -0.001 -0.005 -0.01 -0.05 -0.1 -0.5 -0.8; do
		zcat Tenn_deleterious_output.admix_*.chr_ALL.m3_1.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz \
			| awk 'BEGIN {OFS="\t"} {bp=$3-$2 ; sum+=bp} END {print "'$recomb'", "'$selec'", sum/3046/100/10000000}' \
			>> admix.log
	done
done
