#$ -S /bin/bash
#$ -l mfree=5G

echo $SGE_TASK_ID
length=$(echo 1000000)
mu=$( echo 2e-8 )	# original 2e-8 , scale up to simulate larger windows
recomb=$( echo 1e-8 )	# original 1e-8 , scale up to simulate larger windows
mig_rate=$( echo 0.02 ) # total admixture, 2%
mig_rate_per_gen=$( awk 'BEGIN {print '$mig_rate'/10 }' ) # admixture rate for 10 generations
file=$( echo Tenn_deleterious_output.admix_"$mig_rate".chr_"$SGE_TASK_ID" )
fileP2=$( echo $file.p2.slim )
fileP3=$( echo $file.p3.slim )
sample_P2=$(echo 1000)
sample_P3=$(echo 1000)
prob=$( echo 1.00 ) # frequency of m2/neutral mutation along chromosome (1-prob = freq of deleterious mutation along chrom)
selec=$( echo -0.001 ) # selection coefficeint of deleterious mutation (type m3)
PROJ=$(echo ~/AkeyRotation/SimulatedDemographic/SLiM/bin)
model=$(echo Tennessen_model_DeleteriousMutation.slim)

echo RUN SLIM
echo $model
echo -e $length $mu $recomb $mig_rate
time slim -d d_mig=$mig_rate_per_gen -d d_len=$length -d d_mu=$mu -d d_recomb=$recomb -d d_selec=$selec -d d_prob=$prob -d d_seed=${RANDOM}${SGE_TASK_ID} -d d_sampleP2=$sample_P2 -d d_sampleP3=$sample_P3 -d "d_outfileP2='"$fileP2"'" -d "d_outfileP3='"$fileP3"'" $PROJ/$model

echo ''
echo PARSE SLIMFILE
python $PROJ/SLiM_mutations.py -f $fileP2 -l $length
python $PROJ/SLiM_mutations.py -f $fileP3 -l $length

echo ''
echo SORT-MERGE BED FILE
cat $fileP2.Neand.bed $fileP3.Neand.bed \
	| awk 'BEGIN {OFS="\t"} {if($2<$3) print$0}' \
	| sort-bed - \
	| bedops --merge - \
	| awk 'BEGIN {OFS="\t"} {print "'$SGE_TASK_ID'",$2,$3,$1}' \
	> $file.ALL.slim.Neand.sort.merge.bed

echo ''
echo fin
echo ''
