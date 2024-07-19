# An Amino Acid Ionic Liquids (AAILs) Supplement for the Original CL&P and CL&Pol
----

## Description
----
This repository contains the nonpolarizable and polarizable force field parameters and files for amino acid ionic liquids (AAILs), which are compatible with the [CL&P](https://github.com/paduagroup/clandp), [CL&Pol](https://github.com/paduagroup/clandpol), and [fftool](https://github.com/paduagroup/fftool). Most parameter files and scripts in this repository are similar to those in CL&P and CL&Pol, except for `pol_param/modified_lj.data` and `scripts/modifyLJ`, which are used to modify the Lennard-Jones sigma parameters to mitigate the overestimated electrostatic acctraction between the bare hydrogens/small ions and negatively charged atoms.

If you use these parameters, please cite the following papers:

\[my citation\]

## Usage of the new script `modifyLJ`
----
The `pol_param/modified_lj.data` file contains atom type pairs whose the Lennard-Jones interaction's sigma parameter needs to be modified. The `scripts/modifyLJ` script is used to modify the Lennard-Jones sigma parameters according to the `modified_lj.data` file. The script will read the `pair-sc.lmp` file (the polarizable LAMMPS pair potential files, which each line contains the LJ parameters for each atom type pair and comments indicating their atom type names)

- **usage**: `modifyLJ [-ip INPUTPAIRFILENAME] [-op OUTPUTPAIRFILENAME] [-lj MODIFIEDLJFILENAME]`

- **options**:
  - `-ip INPUTPAIRFILENAME`: the input LAMMPS pair potential file, default is `pair-sc.lmp`
  - `-op OUTPUTPAIRFILENAME`: the output LAMMPS pair potential file, default is `pair-sc-m.lmp`
  - `-lj MODIFIEDLJFILENAME`: the modified Lennard-Jones sigma parameters file, default is `pol_param/modified_lj.data`

## How to use
----
To build nonpolarizable and polarizable LAMMPS inputs for AAILs using this supplement, please follow the following steps: (use [Cho][Ala] as an example, assume that [**Packmol**](https://m3g.github.io/packmol/) has been installed)

1. copy all structure files (here, `cholinium.zmat` and `ala.zmat`), force field files (`des.ff` and `ala.ff`), and `fftool` script, into the working folder. 

2. use `fftool` script to generate the **Packmol** input file for the system with 100 cholinium and 100 alanine molecules within the box with length of 35 Angstroms:

    `fftool 100 cholinium.zmat 100 ala.zmat -b 35`

3. use **Packmol** to generate the initial configuration:

    `packmol < pack.inp`

4. use `fftool` to build the input files for LAMMPS containing the force field and the coordinates, use `-l` to indicate LAMMPS format, and `-a` to indicate to write all I-J pairs, instead of only I-I pairs; this step will generate `data.lmp` and `pair.lmp` for further polarizable force field generation usage:

    `fftool 100 cholinium.zmat 100 ala.zmat -b 35 -l -a`

5. to further generate the polarizable system, copy `polarizer`, `scaleLJ`, `coul_tt`, `modifyLJ` scripts, and `alpha.ff`, `fragment.ff`, `modified_lj.data` files into current working folder.

6. use `polarizer` to generate the polarizable LAMMPS data file:

    `polarizer -f alpha.ff data.lmp data-p.lmp`

7. use `scaleLJ` to scale the Lennard-Jones sigma parameters according to the SAPT calculation, use `-q` option to make sure we are using the SAPT values instead of the predicted values. `fragment.inp` is a input file that identifies the atomic types corresponding to each fragment, here are `ch` and `ala` two fragments:

    `scaleLJ -f fragment.ff -a alpha.ff -i fragment.inp -ip pair.lmp -op pair-scq.lmp -q`

8. use `coul_tt` to add TT damping between dipoles and bare hydrogens/small ions, in this case, the atom types of bare hydrogens are 8 and 10, and the default TT damping factor $b_{tt}=4.5$ is used:

    `coul_tt -d data-p.lmp -a 8 10 --btt 4.5`

9. lastly, use `modifyLJ` to modify the Lennard-Jones sigma parameters:

    `modifyLJ -ip pair-scq.lmp -op pair-scq-m.lmp -lj modified_lj.data`