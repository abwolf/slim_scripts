#!/bin/bash

#SBATCH --get-user-env
#SBATCH --mem=100G
#SBATCH --time 5-0
#SBATCH --qos=1wk
#SBATCH --output=slrun.SLiM_Tenn_deleterious_MigTest.sh.%A_%a.o
source ~/.bashrc

date
echo $SLURM_JOB_NAME
echo $SLURM_ARRAY_TASK_ID
for m in 0.02 0.05 0.1 0.15; do
	#########
	length=$(echo 10000000)
	mu=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
	recomb=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
	mig_rate=$m 		# total admixture, 2%
	mig_rate_per_gen=$( awk 'BEGIN {print '$mig_rate'/10 }' ) # admixture rate for 10 generations
	file=$( echo Tenn_deleterious_output.admix_"$mig_rate".chr_"$SLURM_ARRAY_TASK_ID" )
	fileP2=$( echo $file.p2.slim )
	fileP3=$( echo $file.p3.slim )
	sample_P2=$(echo 1006)
	sample_P3=$(echo 1008)
	prob=$( echo 1 ) # frequency of m2(neutral) mutation along chromosome (1-prob = freq of deleterious mutation along chrom)
	selec=$( echo -0.001 ) # selection coefficeint of deleterious mutation (type m3)
	
	PROJ=$(echo ~/SimulatedDemographic/SLiM/)
	model1=$(echo Tennessen_model_DeleteriousMutation.slim.11_01_2017)	# removes late accelerated population growth
	##########
	
	echo ''
	echo RUN SLIM
	echo ''
	echo $model1
	echo -e Length: $length    Mu: $mu    Recomb: $recomb    Mig_rate: $mig_rate    Prob_neutral_mutations: $prob    Non_neutral_selection_coef: $selec 
	time slim \
		-d d_mig=$mig_rate_per_gen \
		-d d_len=$length -d d_mu=$mu -d d_recomb=$recomb \
		-d d_selec=$selec \
		-d d_prob=$prob \
		-d d_seed=${RANDOM}${SLURM_ARRAY_TASK_ID} \
		-d d_sampleP2=$sample_P2 \
		-d d_sampleP3=$sample_P3 \
		-d "d_outfileP2='"$fileP2.mdl1"'" \
		-d "d_outfileP3='"$fileP3.mdl1"'" \
		$PROJ/bin/$model1
	echo ''
	sstat -j %A_%a.batch
	echo ''
done
echo FIN
date
