#!/bin/bash
#SBATCH -N 1                       # Number of requested nodes
#SBATCH --time=2:30:00             # Max walltime
#SBATCH --qos=normal               # Specify normal QOS
#SBATCH --partition=shas           # Specify Summit haswell nodes
#SBATCH --output job_exec.out      # Set the output file name (default: slurm-${jobid}.out)
#SBATCH --ntasks-per-node=12      # Use 12 cores per node, ~64GB of memory
##SBATCH --exclusive                # Use whole node

vars="psl"
invars="psl"
model="HadGEM2-CC"
byr="1974"
eyr="1979"
#attr="noleap"     ### CCSM4, IPSL-CM5A-LR, MIROC5, NorESM1-M
attr="360_day"     ### HadGEM2-CC, HadGEM2-ES
#attr="gregorian"     ### MIROC-ESM

final="final_run."
echo start:`date`
for (( i = 0; i < ${#vars[@]}; ++i ))
  do
  for (( j = 0; j < ${#model[@]}; ++j ))
  do
    sed -e "s/my_var/"${vars[$i]}"/" \
            -e "s/my_model/"${model[$j]}"/" \
            -e "s/my_byr/"$byr"/" \
            -e "s/my_eyr/"$eyr"/" \
            -e "s/my_attr/"$attr"/" \
            -e "s/my_in_var/"${invars[$i]}"/" create_running_mean_3dim.ncl> final_run.ncl
    ncl < final_run.ncl
    #mvfinal=$final${vars[$i]}
    #mv final_run.ncl $mvfinal
    #rm -rf final_run.ncl
  done
done

echo end:`date`

exit 0
