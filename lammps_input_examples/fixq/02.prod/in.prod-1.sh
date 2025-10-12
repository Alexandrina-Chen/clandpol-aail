# Filename: in.equil.cont-nvt.sh
# NVT template for continuous non-polarizable systems
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
variable stage string prod1-nvt-298                      # stage name
variable tstartsystem equal 298                           # system start temperature
variable tstopsystem equal 298                           # system stop temperature
variable tdrude equal 1.0                        # drude temperature
variable psystem equal 1.0                          # pressure
variable tstep equal 1                           # timestep in fs
variable mdstep equal 10000000                     # MD steps
variable numchunks equal "round(v_mdstep/10)"    # number of chunks repeated averaged
variable thermofreq equal 1000                   # frequency of outputing thermo
variable shakefreq equal 0
variable dumpfreq equal 1000
variable ifresetts equal true                  # if reset timestep, either `true` or `false`
variable newtimestep equal 0              # if reset timestep, the desired new timestep is set here
variable ifnewbox equal false                    # if change box size, either `true` or `false`
variable origin_box_x equal lx
variable origin_box_y equal ly
variable origin_box_z equal lz
variable new_box_x equal 48.647940
variable new_box_y equal 48.647940
variable new_box_z equal 48.647940
variable box_scale_x equal "v_new_box_x/v_origin_box_x"
variable box_scale_y equal "v_new_box_y/v_origin_box_y"
variable box_scale_z equal "v_new_box_z/v_origin_box_z"

# restart from data file or restart file
read_restart last.restart

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
# minimize 1.0e-4 1.0e-6 100 1000


# increase the number of neighbour for each atom using keyword `one 10000` if necessary, especially for systems containing drude oscillator
neighbor 2.0 bin
neigh_modify delay 0 every 1 check yes

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
dump TRAJ1 all custom ${dumpfreq} ${stage}-unwrap.lammpstrj id type mol element q xu yu zu vx vy vz
dump_modify TRAJ1 sort id element N C H C C H O H N H C H C H C O
# 2, wrapped
# dump TRAJ2 all custom ${dumpfreq} ${stage}.lammpstrj id type mol q x y z
# dump_modify TRAJ1 sort id

# fix command using for NVT for non-rigid atoms, SHAKE for C-H bonds, RIGID for water
fix fTSTAT all nvt temp ${tstartsystem} ${tstopsystem} 100.0
fix fSHAKE all shake 0.0001 20 ${shakefreq} b 2 5 6 8 10 
fix fMOMENTUM all momentum 100 linear 1 1 1



# output thermo information
thermo ${thermofreq}
thermo_style custom step temp etotal ke pe epair evdwl ecoul elong etail ebond vol press spcpu pxx pyy pzz pxy pxz pyz lx ly lz

# if reset box size
# "run 0" is necessary to avoid possible error
# possible error: Cannot change_box after reading restart file with per-atom info. 
# This is because the restart file info cannot be migrated with the atoms. 
if "${ifnewbox}" then &
    "run 0"&
    "change_box all x scale ${box_scale_x} y scale ${box_scale_y} z scale ${box_scale_z} remap"

# compute pressure tensor
fix fPRESSTENSOR all ave/time 1 1 5 c_thermo_press[*] file ${stage}.press

# run MD
run ${mdstep}

write_restart ${stage}_final.restart
write_data ${stage}_final.data pair ij



unfix fMOMENTUM
unfix fSHAKE
unfix fTSTAT
undump TRAJ1
