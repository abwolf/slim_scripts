#!/bin/bash

#SBATCH --get-user-env
#SBATCH --mem=100G
#SBATCH --time 5-0
#SBATCH --qos=1wk
#SBATCH --output=slrun.SLiM_Tenn_deleterious.sh.%A_%a.o
source ~/.bashrc

date
echo $SLURM_JOB_NAME
echo $SLURM_ARRAY_TASK_ID

#########
length=$(echo 10000000)
mu=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
recomb=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
mig_rate=$( echo 0.02 ) # total admixture, 2%
mig_rate_per_gen=$( awk 'BEGIN {print '$mig_rate'/10 }' ) # admixture rate for 10 generations
file=$( echo Tenn_deleterious_output.admix_"$mig_rate".chr_"$SLURM_ARRAY_TASK_ID" )
fileP2=$( echo $file.p2.slim )
fileP3=$( echo $file.p3.slim )
sample_P2=$(echo 1006)
sample_P3=$(echo 1008)
prob=$( echo 1 ) # frequency of m2(neutral) mutation along chromosome (1-prob = freq of deleterious mutation along chrom)
selec=$( echo -0.001 ) # selection coefficeint of deleterious mutation (type m3)

PROJ=$(echo ~/SimulatedDemographic/SLiM/)
model=$(echo Tennessen_model_DeleteriousMutation.slim)
##########

echo ''
echo RUN SLIM
echo $model
echo -e Length: $length    Mu: $mu    Recomb: $recomb    Mig_rate: $mig_rate    Prob_neutral_mutations: $prob    Non_neutral_selection_coef: $selec 
time slim \
	-d d_mig=$mig_rate_per_gen \
	-d d_len=$length -d d_mu=$mu -d d_recomb=$recomb \
	-d d_selec=$selec \
	-d d_prob=$prob \
	-d d_seed=${RANDOM}${SLURM_ARRAY_TASK_ID} \
	-d d_sampleP2=$sample_P2 \
	-d d_sampleP3=$sample_P3 \
	-d "d_outfileP2='"$fileP2"'" \
	-d "d_outfileP3='"$fileP3"'" \
	$PROJ/bin/$model

echo ''
echo PARSE SLIMFILE
time python $PROJ/bin/SLiM_mutations.py -f $fileP2 -l $length
time python $PROJ/bin/SLiM_mutations.py -f $fileP3 -l $length

echo ''
echo SORT-MERGE BED FILE
time zcat $fileP2.Neand.bed.gz $fileP3.Neand.bed.gz \
	| awk 'BEGIN {OFS="\t"} {if($2<$3) print$0}' \
	| sort-bed - \
	| bedops --merge - \
	| awk 'BEGIN {OFS="\t"} {print "'$SLURM_ARRAY_TASK_ID'",$2,$3,$1}' \
	| gzip -c - \
	> $file.ALL.slim.Neand.sort.merge.bed.gz

echo ''
echo FIN
date
