#!/bin/bash

#SBATCH --get-user-env
#SBATCH --mem=10G
#SBATCH --time 22:00:00
#SBATCH --qos=1day
#SBATCH --output=slrun.SLiM.combine_replicates.sh.%A_%a.o
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
	for selec in -0.0001 -0.0005 -0.001 -0.005 -0.01 -0.05 -0.08; do
		#Define admixture proportion
	#	if (( $(bc <<<"$selec > -0.005") )); then
	#		mig_rate=$(echo 0.02)
	#	elif (( $(bc <<<"$selec == -0.005") )); then
	#		mig_rate=$(echo 0.03)
	#	elif (( $(bc <<<"$selec == -0.01") )); then
	#		mig_rate=$(echo 0.04)
	#	elif (( $(bc <<<"$selec == -0.05") )); then
	#		mig_rate=$(echo 0.15)
	#	elif (( $(bc <<<"$selec == -0.08") )); then
	#		mig_rate=$(echo 0.5)
	#	fi
		if (( $(bc <<<"$selec > -0.005") )); then
			mig_rate=$(echo 0.02)
		elif (( $(bc <<<"$selec == -0.005") )); then
			mig_rate=$(echo 0.05)
		elif (( $(bc <<<"$selec == -0.01") )); then
			mig_rate=$(echo 0.1)
		elif (( $(bc <<<"$selec == -0.05") )); then
			mig_rate=$(echo 0.5)
		fi

		#Check that file exists for parameter set
		if [ -e "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz ]; then
			echo ALL_file ALREADY EXISTS: "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
		
		elif [ -e "$mdl"_deleterious_output.admix_"$mig_rate".chr_"1".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz ] ; then
			
			echo "$mdl"_deleterious_output.admix_"$mig_rate".chr_"1".m3_10.selec_"$selec".recomb_"$recomb"
			
			echo COMBINE REPLICATES
			cat \
				"$mdl"_deleterious_output.admix_"$mig_rate".chr_[0-9]*.m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz \
				> "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
			
			echo ADD PARAMETER COLUMNS TO FILE
			zcat \
				"$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz \
				| awk 'BEGIN {OFS="\t"} {print $0, "'$mig_rate'", "'$selec'", "'$recomb'"}' \
				| gzip -c - \
				> "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged2.gz
			
			echo REMOVE ORIGINAL COMBINED FILE
			rm "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
			echo RENAME NEW COMBINED FILE
			mv "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged2.gz \
				"$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
			
			if [ -e "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz ] ; then
				echo "$mdl"_deleterious_output.admix_"$mig_rate".chr_"ALL".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
				echo ''
			fi
		else
			echo WARNING: MISSING "$mdl"_deleterious_output.admix_"$mig_rate".chr_"1".m3_10.selec_"$selec".recomb_"$recomb".ALL.slim.Neand.bed.merged.gz
			echo ''
		fi
	done
done

echo FIN
date
