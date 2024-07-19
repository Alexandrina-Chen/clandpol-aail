#!/bin/bash

#-------------------------------------------------------------#
# example for builing a CHOALA system with 100 ion pairs
#-------------------------------------------------------------#

chmod u+x fftool polarizer scaleLJ coul_tt modifyLJ

#-------------------------------------------#
# First, the nonpolarizable system
#-------------------------------------------#

# 1. generate Packmol input
./fftool 100 cholinium.zmat 100 ala.zmat -b 40
# 2. run Packmol to generate the initial configuration
packmol < pack.inp
# 3. use fftool to generate the LAMMPS data file using the force field files and the initial configuration
./fftool 100 cholinium.zmat 100 ala.zmat -b 40 -l -a

#-------------------------------------------#
# Second, the polarizable system
#-------------------------------------------#

# 1. generate the polarizable LAMMPS data file including DPs according atom poalrizabilities
./polarizer -f alpha.ff data.lmp data-p.lmp
# 2. scale the LJ parameters according to SAPT results
./scaleLJ -f fragment.ff -a alpha.ff -i fragment.inp -ip pair.lmp -op pair-scq.lmp -q
# 3. add TT damping to bare hydrogen atoms
./coul_tt -d data-p.lmp -a 8 10 --btt 4.5
# 4. modify LJ parameters for strong h-bonds
./modifyLJ -ip pair-scq.lmp -op pair-scq-m.lmp -lj modified_lj.data