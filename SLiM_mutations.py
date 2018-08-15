## Read the output file from SLiM (SLiM format).
## Separate the mutation calls from the genome calls, and write these to separate files ( .mut & .gen ).
## Using the genomes calls, calculate how many Neandertal varaints/mutations each genome carries
## Write the pct_Neand introgressed basses for each genome to a separate file ( .NeandPct )

from __future__ import print_function
import sys
import argparse
import gzip
import os
from operator import itemgetter
from itertools import groupby

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--file", action="store", type=str, dest="filename", help="SLiM infile for parsing")
parser.add_argument("-l", "--length", action="store", type=float, dest="sim_len", help="Length of simulated chrom")
args = parser.parse_args()
######

infile = args.filename
sim_len = args.sim_len
#fname, ext = os.path.splitext(infile)


slim_file = open(args.filename, 'r')
slim_NeandBed_file = gzip.open(infile+'.Neand.bed.gz', 'wb')
#slim_NeandPct_file = gzip.open(filename+'.NeandPct.gz', 'wb')

##slim_mut_file = gzip.open(filename+'.mut.gz', 'wb')
##slim_genom_file = gzip.open(filename+'.gen.gz', 'wb')


#slim_NeandPct_file_header = '\t'.join(['pop_gen_ID','count_mut_Hum','count_mut_Neand','total_muts','sum_mut_Hum_Neand','Pct_Neand_bases'])
#slim_NeandPct_file.write(slim_NeandPct_file_header+'\n')
######


#Write the mutation list to a separate file

mutations_dict = {}
for line in slim_file:
	if line.startswith('#'):
		continue
	elif line.startswith('Mutations:'):
		#slim_mut_file.write(line)
		continue
	elif line.startswith('Genomes:'):
		#slim_genom_file.write(line)
		break
	else:	#Write mutation lines to a new files .mut
		#slim_mut_file.write(line)
		
		# Collect ID and population source for all the listed mutations
		## Mutations:
		## 21 2700451 m1 140 0 0.5 p1 1599 100
		## 211 2895042 m1 872 0 0.5 p1 7223 43
		## 58 2917023 m1 676 0 0.5 p1 7855 100
		## 92 2963173 m1 959 0 0.5 p1 9189 51
		## 1) temp_ID 2) perm_ID 3) mut_type 4) base_position 5) select_coeff 6) dom_coeff 7) subpop_origin 8) gen_origin 9) prevalance
		
		mutation_data = line.strip('\n').split(' ')
		
		mut_id = mutation_data[0]
		mut_id_perm = mutation_data[1]
		mut_type = mutation_data[2]
		mut_pos = mutation_data[3]
		mut_sc = mutation_data[4]
		mut_dc = mutation_data[5]
		mut_poporg = mutation_data[6]
		mut_genorg = mutation_data[7]
		mut_prev = mutation_data[8]
		
		# Add the mutations to the dictionary of mutations (key:value pairing)
		# key = mutation_temp_ID
		# value = list of: mutation_type, mutation_position, subpop_origin, generation_origin
		mutations_dict.update({mut_id: list((mut_type, int(mut_pos), mut_poporg, int(mut_genorg)))})
slim_file.close()		
#slim_mut_file.close()
######

##### CREAT .NeandPct.gz FILE #####
### Write the genomes to a separate file and calculate how many Neand variants are present in the population
#slim_file = open(args.filename, 'r')
#for line in slim_file:
#	if line.startswith('Genomes:'):
#		#slim_genom_file.write(line)
#		continue
#	elif line.startswith('p'):
#		# Write the genome calls to a new file .gen
#		#slim_genom_file.write(line)
#
#		# Create a list fom the genome calls and determine how many mutations of Neand-ancestry (p4) each genome carries
#		## Genomes:
#		## p3:0 A 0 1 2 3 4 5 6 7 8 9 10 ...
#		## p3:1 A 0 96 1 2 3 4 5 6 7 8 9 ...
#		## p3:2 A 139 140 141 142 2  143 144 ...
#		## p3:3 A 0 1 2 3 4 6 167 7 8 ...
#		## 1) population 2) genome_id 3) Autosome 4) list of mutations
#		
#		genome_data = line.strip('\n').split(' ')
#		
#		# For each genome, count the number of Hum and Neand mutations based on mutations population_of_origin, then report this number
#		pop_gen_ID = genome_data[0]
#		mut_Hum = 0
#		mut_Neand = 0
#		
#		for i in range(2,len(genome_data)):
#			mut_i = genome_data[i] 				# mutation_i is at position i in the genom_data line
#			mut_poporg = mutations_dict[mut_i][2]		# look up the mutation in the dictionary by mutation_temp_id to get pop_of_origin
#			mut_type = mutations_dict[mut_i][0]
#			if mut_poporg!='p4':				# if the origin IS NOT in the Neand population ; count it as a Human mutation
#				mut_Hum+=1
#			elif mut_poporg=='p4' and mut_type=='m2':	# if the origin IS in the Neand population ; count it as a Neand mutation
#				mut_Neand+=1
#		genome_counts = '\t'.join([pop_gen_ID, str(mut_Hum), str(mut_Neand), str(len(genome_data)-2), str(int(mut_Hum)+int(mut_Neand)), str( float(mut_Neand)/float(sim_len) )])
#		slim_NeandPct_file.write(genome_counts+'\n')		# Report the number of Human specific and Neand specific mutations for each genome
#
##slim_genom_file.close()
#slim_NeandPct_file.close()
#slim_file.close()
######


##### CREAT BED FILE #####
# Read the genome file
# collect only the Neand mutations
# replace mutation_temp_id with mutation_position
# calculate the length/position of Neand haplotypes

#slim_genom_file = gzip.open(filename+'.gen.gz', 'rb')						# open the genome file

slim_file = open(args.filename, 'r')
Neand_mutations_dict = {}		# create an empty dictionary for listing ind_id (key) and Neand_mutations (list as value)
#for line in  slim_genom_file:
for line in slim_file:
	if line.startswith('#'):
		continue
	elif line.startswith('Mutations:'):
		continue
	elif line.startswith('Genomes:'):
		continue
	elif line.startswith('p'):
		genome_data = line.strip('\n').split(' ')
		pop_gen_ID = genome_data[0]
		
		Neand_mut_pos_list = [] 						# for each individual, create an empty list to hold the Neandertal mutations
		for i in range(2,len(genome_data)):
			mut_i = genome_data[i]						# pull out a specific mutation
			mut_poporg = mutations_dict[mut_i][2]				# identify that mutations pop_of_origin (AFR, NEAND, EUR, ASN)
			mut_type = mutations_dict[mut_i][0]				# identify the mutation type (m1,m2,m3)
			mut_pos = mutations_dict[mut_i][1]				# look up its position in the mutations dictionary
			if mut_poporg=='p4':						# If the origin IS in the Neand population; 
				Neand_mut_pos_list.append(mut_pos)			# and add it to the Neand_mutation_list

		Neand_mut_pos_list.sort()						# sort the mutation positions into ascending order
		Neand_mutations_dict.update( {pop_gen_ID: Neand_mut_pos_list} )		# add the ind_id and Neand_mutation_list to the Neand_mutation_dictionary
		#print pop_gen_ID, Neand_mut_pos_list
		
for ind, positions in Neand_mutations_dict.items():					# for each individual, Neand_mutation_list pairing
	if len(positions) > 0:								# if the individual had >0 Neand mutations
		first = last = positions[0]
		for n in positions[1:]:							# read through the positions of Neand mutations and identify those in sequence
			if n - 1 == last:
				last = n
			else:
				introg_hap = '\t'.join([str(ind),str(first),str(last)])	# If you find a sequence of Neand mutations, write them in bed format
				slim_NeandBed_file.write(introg_hap+'\n')
				first = last = n
		introg_hap = '\t'.join([str(ind),str(first),str(last)])
		slim_NeandBed_file.write(introg_hap+'\n')				# write the ind_id and start, end position of the introgressed Neand haplotype to the bedfile
											# NOTE: the haplotypes may look split up because of more ancient Neand mutations, 
											# i.e. mutation that arose separate from the "tagging SNPs" instance
											# Therefore, you need to sort and merge the bedfile before proceeding, as there will be haplotypes
											# that are touching, but are called separately.

#slim_genom_file.close()
slim_file.close()
slim_NeandBed_file.close()
