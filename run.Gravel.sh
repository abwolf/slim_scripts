#$ -S /bin/bash
#$ -l mfree=10G

echo $SGE_TASK_ID
length=$(echo 10000)
fileP2=$(echo Gravel_output.p2_postadmixture.$SGE_TASK_ID.slim)
fileP3=$(echo Gravel_output.p3_postadmixture.$SGE_TASK_ID.slim)
sample_P2=$(echo 1000)
sample_P3=$(echo 1000)
mig_rate=$( awk 'BEGIN {print 0.02/10 }' ) # 2% for 10 generations
path=$(echo ~/AkeyRotation/SimulatedDemographic/SLiM/bin)
model=$(echo Gravel_model.txt)

echo RUN SLIM
echo $model
slim -d d_mig=$mig_rate -d d_len=$length -d d_seed=${RANDOM}${SGE_TASK_ID} -d d_sampleP2=$sample_P2 -d d_sampleP3=$sample_P3 -d "d_outfileP2='"$fileP2"'" -d "d_outfileP3='"$fileP3"'" $path/$model

echo ''
echo PARSE SLIMFILE
python $path/SLiM_mutations.py -f $fileP2 -l $length
python $path/SLiM_mutations.py -f $fileP3 -l $length

echo ''
echo fin
echo ''
