# Filename: in.equil.init-npt.sh
# NPT template for initial non-polarizable systems
# Commands to include in the LAMMPS input stack
units real 
boundary p p p


atom_style full
bond_style harmonic
angle_style harmonic
dihedral_style opls


# adapt the pair_style command as needed
pair_style lj/cut/coul/long 15.0 15.0
pair_modify tail yes
kspace_style pppm 1.0e-5 


# define variables
variable stage string equil1-npt-300                      # stage name
variable tstartsystem equal 100                           # system start temperature
variable tstopsystem equal 300                           # system stop temperature
variable tdrude equal 1.0                        # drude temperature
variable psystem equal 1.0                          # pressure
variable tstep equal 0.5                           # timestep in fs
variable mdstep equal 5000000                     # MD steps
variable numchunks equal "round(v_mdstep/10)"    # number of chunks repeated averaged
variable thermofreq equal 1000                   # frequency of outputing thermo
variable shakefreq equal 1000
variable dumpfreq equal 1000000



# restart from data file or restart file
read_data data.lmp

# handle 1-2,1-3,1-4 interaction
special_bonds lj/coul 0.0 0.0 0.5 # use after read data, if used before reading data, it will use the default 0.0 0.0 0.0 

# pair coeff
include pair.lmp




# write out restart file
restart 10000 ${stage}.restart ${stage}.restart.bk 

# convenient atom groups (for shake, thermostats...)
group gANION type  9:16
group gCATION type 1:8



# minimize energy; DO NOT use minimize for systems containing RIGID bodies, fix rigid is not evoked during minimization and will change the conformation of the rigid body
minimize 1.0e-4 1.0e-6 100 1000

# increase the number of neighbour for each atom using keyword `one 10000` if necessary, especially for systems containing drude oscillator
neighbor 2.0 bin
neigh_modify delay 0 every 1 check yes

# timestep to integrate motions
timestep ${tstep}

# initialize velocities
velocity all create ${tstartsystem} 123456 mom yes rot yes dist gaussian

# re-balance the load of processors
balance 1.1 shift z 20 1.02

#####################
## NVT run ###

# reset timestep after minimization
reset_timestep 0

# dump trajectory
# 1. unwrapped
dump TRAJ1 all custom ${dumpfreq} ${stage}-unwrap.lammpstrj id type mol element q xu yu zu
dump_modify TRAJ1 sort id element N C H C C H O H N H C H C H C O
# 2, wrapped
# dump TRAJ2 all custom ${dumpfreq} ${stage}.lammpstrj id type mol q x y z
# dump_modify TRAJ1 sort id

# fix command using for NVT for non-rigid atoms, SHAKE for C-H bonds, RIGID for water
fix fTSTAT all npt temp ${tstartsystem} ${tstopsystem} 100.0 iso ${psystem} ${psystem} 1000.0
fix fSHAKE all shake 0.0001 20 ${shakefreq} b 2 5 6 8 10 
fix fMOMENTUM all momentum 100 linear 1 1 1



# output thermo information
thermo ${thermofreq}
thermo_style custom step temp etotal ke pe epair evdwl ecoul elong etail ebond vol press spcpu lx ly lz



run ${mdstep}

write_restart ${stage}_final.restart
write_data ${stage}_final.data pair ij



unfix fMOMENTUM
unfix fSHAKE
unfix fTSTAT
undump TRAJ1


