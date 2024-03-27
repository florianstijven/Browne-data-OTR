#!/bin/bash
#
#SBATCH --job-name=browne-madrs
#SBATCH --ntasks=1 --cpus-per-task=36 --mem-per-cpu=5000M
#SBATCH --time=12:00:00
#SBATCH --cluster=genius
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -A lp_doctoralresearch

export OMP_NUM_THREADS=1

module unuse /apps/leuven/skylake/2018a/modules/all
module use /apps/leuven/skylake/2021a/modules/all

module purge
module load GSL
module load CMake
module load R

Rscript OTR-estimation-vsc-outcome.R madrs



