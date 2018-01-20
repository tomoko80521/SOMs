#!/bin/bash
#SBATCH -N 1                       # Number of requested nodes
#SBATCH --time=2:30:00             # Max walltime
#SBATCH --qos=normal               # Specify normal QOS
#SBATCH --partition=shas           # Specify Summit haswell nodes
#SBATCH --output job_exec.out      # Set the output file name (default: slurm-${jobid}.out)
#SBATCH --ntasks-per-node=12      # Use 12 cores per node, ~64GB of memory
##SBATCH --exclusive                # Use whole node

vars=("sic" "sit")
model="IPSL-CM5A-LR"
#model=("CCSM4" "HadGEM2-CC" "HadGEM2-ES" "MIROC5" "MIROC-ESM" "NorESM1-M")

#vars=("ta" "ua" "va" "zg")

final="final_run."
for (( i = 0; i < ${#vars[@]}; ++i ))
do
  for (( j = 0; j < ${#model[@]}; ++j ))
  do
    sed -e "s/my_var/"${vars[$i]}"/" \
        -e "s/my_model/"${model[$j]}"/" regrid_sice.ncl > final_run.ncl
    ncl < final_run.ncl
    #mvfinal=$final${vars[$i]}
    #mv final_run.ncl $mvfinal
    rm -rf final_run.ncl
  done
done

exit 0
