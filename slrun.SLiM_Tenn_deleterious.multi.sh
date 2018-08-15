#!/bin/bash

#SBATCH --get-user-env
#SBATCH --mem=150G
#SBATCH --time 5-0
#SBATCH --qos=1wk
#SBATCH --output=slrun.SLiM_Tenn_deleterious.multi.sh.%A_%a.o
source ~/.bashrc

date
echo $SLURM_JOB_NAME
echo $SLURM_ARRAY_TASK_ID

# alpha = 0.206 ; Beta = 15400		Boyko et al. 2008
# mu = alpha/Beta = 0.00001337662338

for recomb in 0.5e-8 1.0e-8 1.3e-8; do
	for selec in -0.005 -0.01 -0.05; do
	#for selec in -0.0001 -0.0005 -0.001 -0.005 -0.01 -0.05 -0.08; do
		#########
		length=$(echo 10000000)
		mu=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
		
		#recomb=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
		#mig_rate=$( echo 0.03 ) # total admixture, 2%
		
		if (( $(bc <<<"$selec > -0.005") )); then
			mig_rate=$(echo 0.02)
		elif (( $(bc <<<"$selec == -0.005") )); then
			mig_rate=$(echo 0.05)
		elif (( $(bc <<<"$selec == -0.01") )); then
			mig_rate=$(echo 0.1)
		elif (( $(bc <<<"$selec == -0.05") )); then
			mig_rate=$(echo 0.5)
		#elif (( $(bc <<<"$selec == -0.08") )); then
		#	mig_rate=$(echo 0.5)
		fi

		mig_rate_per_gen=$( awk 'BEGIN {print '$mig_rate'/10 }' ) # admixture rate for 10 generations
		
		file=$( echo Tenn_deleterious_output.admix_"$mig_rate".chr_"$SLURM_ARRAY_TASK_ID".m3_10.selec_"$selec".recomb_"$recomb" )
		fileP2=$( echo $file.p2.slim )
		fileP3=$( echo $file.p3.slim )
		
		sample_P2=$(echo 1006)
		sample_P3=$( awk 'BEGIN {print 1008 + 978 + 54}' ) # EAS + SAS + PNG
		
		#freq=$( awk 'BEGIN {print '$1'/'$length'}' ) # frequency of m3 mutations based on simulated length ; $1=input number of desired m3 mutations 
		#prob=$( awk 'BEGIN {print 1-'$freq'}' ) # frequency of m2 (neutral) mutation along chromosome ; 1k SNPs for 10Mb genomic region
		
		#selec=$( echo -0.00001 )
		#selec_alpha=$( echo 0.206 )
		#selec_beta=$( echo 15400 )
		#selec_mu=$( awk 'BEGIN {print ('$selec_alpha'/'$selec_beta') * -1}' )
		
		prob=$( echo 1.0 )
		
		PROJ=$(echo ~/SimulatedDemographic/SLiM/)
		model=$(echo Tennessen_model_DeleteriousMutation.slim.11_01_2017)	# removes late accelerated population growth
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
		
		#echo ''
		#echo GZIP SLIMFILE
		#time gzip $fileP2
		#time gzip $fileP3
		
		echo ''
		echo PARSE SLIMFILE
		python $PROJ/bin/SLiM_mutations.py -f $fileP2 -l $length
		python $PROJ/bin/SLiM_mutations.py -f $fileP3 -l $length
		
		echo''
		echo REMOVE SLIMFILE
		time rm $fileP2 $fileP3
		
		echo ''
		echo SORT-MERGE BED FILE
		zcat $fileP2.Neand.bed.gz $fileP3.Neand.bed.gz \
			| awk 'BEGIN {OFS="\t"} {if($2<$3) print$0}' \
			| sort-bed - \
			| bedops --merge - \
			| awk 'BEGIN {OFS="\t"} {print "'$SLURM_ARRAY_TASK_ID'",$2,$3,$1}' \
			| gzip -c - \
			> $file.ALL.slim.Neand.bed.merged.gz
		echo ''
		echo fin
	done
done
echo ''
echo FIN
date
