# Filename: in.equil.cont.npt.restart.sh
# NVT template for continuous polarizable systems
# Commands to include in the LAMMPS input stack
units real 
boundary p p p


atom_style full
bond_style harmonic
angle_style harmonic
dihedral_style opls


# adapt the pair_style command as needed
pair_style hybrid/overlay lj/cut/coul/long 15.0 15.0 coul/long/cs 15.0 thole 2.600 15.0 coul/tt 4 15.0
pair_modify tail yes
kspace_style pppm 1.0e-5 

# define variables
variable stage string equil1-npt-300                      # stage name
variable tstartsystem equal 300                           # system start temperature
variable tstopsystem equal 300                           # system stop temperature
variable tdrude equal 1.0                        # drude temperature
variable psystem equal 1.0                          # pressure
variable tstep equal 1                           # timestep in fs
variable mdstep equal 2000000                     # MD steps
variable numchunks equal "round(v_mdstep/10)"    # number of chunks repeated averaged
variable thermofreq equal 1000                   # frequency of outputing thermo
variable shakefreq equal 0
variable dumpfreq equal 100000
variable ifresetts equal true                  # if reset timestep, either `true` or `false`
variable newtimestep equal 0              # if reset timestep, the desired new timestep is set here

# restart from data file or restart file
read_data data-p.lmp

# handle 1-2,1-3,1-4 interaction
special_bonds lj/coul 0.0 0.0 0.5 # use after read data, if used before reading data, it will use the default 0.0 0.0 0.0 

# pair coeff
include pair-drude.lmp
include pair-scq-m.lmp
include pair-tt.lmp



# write out restart file
restart 10000 ${stage}.restart ${stage}.restart.bk 

# convenient atom groups (for shake, thermostats...)
group gANION type  9:16
group gCATION type 1:8
group gCORE type 1 2 4 5 7 9 11 13 15 16
group gDRUDE type 17 18 19 20 21 22 23 24 25 26
group gATOMS type 1:16


# identify each atom type: [C]ore, [D]rude, [N]on-polarizable
fix fDRUDE all drude C C N C C N C N C N C N C N C C D D D D D D D D D D

# store velocity information of ghost atoms
comm_modify vel yes

# minimize energy; DO NOT use minimize for systems containing RIGID bodies, fix rigid is not evoked during minimization and will change the conformation of the rigid body
# minimize 1.0e-4 1.0e-6 100 1000

# increase the number of neighbour for each atom using keyword `one 10000` if necessary, especially for systems containing drude oscillator
neighbor 2.0 bin
neigh_modify delay 0 every 1 check yes one 10000

# timestep to integrate motions
timestep ${tstep}

# re-balance the load of processors
balance 1.1 shift z 20 1.02

#####################
## NVT run ###

# reset timestep or not
if "${ifresetts}" then "reset_timestep ${newtimestep}"

# dump trajectory
# 1. unwrapped
dump TRAJ1 all custom ${dumpfreq} ${stage}-unwrap.lammpstrj id type mol element q xu yu zu
dump_modify TRAJ1 sort id element N C H C C H O H N H C H C H C O X X X X X X X X X X
# 2, wrapped
# dump TRAJ2 all custom ${dumpfreq} ${stage}.lammpstrj id type mol q x y z
# dump_modify TRAJ1 sort id

# fix command using for temperature-group dual-Nose Hoover thermostat for polarizable, SHAKE for C-H bonds
#  * if using fix shake the group-ID must not include Drude particles; use group ATOMS
fix fTSTAT all tgnpt/drude temp ${tstartsystem} ${tstopsystem} 100.0 1.0 20.0 iso ${psystem} ${psystem} 1000.0
fix fSHAKE gATOMS shake 0.0001 20 ${shakefreq} b 2 5 6 8 10 
fix fMOMENTUM all momentum 100 linear 1 1 1



# output thermo information
thermo ${thermofreq}
thermo_style custom step temp f_fTSTAT[1] f_fTSTAT[2] f_fTSTAT[3] etotal ke pe epair evdwl ecoul elong etail ebond vol press spcpu lx ly lz



run ${mdstep}

write_restart ${stage}_final.restart
write_data ${stage}_final.data pair ij




unfix fMOMENTUM
unfix fSHAKE
unfix fTSTAT
unfix fDRUDE
undump TRAJ1

