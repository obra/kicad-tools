# Kicad Automation Tools

## What's in the package 

This project packages up a number of productivity-enhancing tools for KiCad (https://kicad.org), primarily
focused on automating generation of fabrication outputs and commandline productivity for projects tracked in git.

### Fabrication outputs

`make fabrication-outputs` wil automatically create the following outputs in an output directory:

* Schematics in PDF and SVG formats
* BOM as a .csv file
* Interactive HTML BOM file
* Layout files in DXF, Gerber (including drill files), PDF, and SVG. 

All of this is built on other projects:

* [InteractiveHtmlBom](https://github.com/openscopeproject/InteractiveHtmlBom)
* [kicad-automation-script](https://github.com/productize/kicad-automation-scripts)
* [splitflap](https://github.com/scottbez1/splitflap)
* [kiplot](https://github.com/johnbeard/kiplot)


## Installation

### Prerequisites

As of this writing, these tools target KiCad 5.1, running in a Docker container. While Docker does add a small amount of overhead, it helps compartmentalize the complexity of orchestrating these tools and (most importantly) makes it possible to generate schematic output from `eeschema` by running KiCad on a known configuration of an Ubuntu machine with a headless virtual X server.

Dockerization makes it possible to run these tools consistently on different platforms; macOS and Linux have been tested, Windows should also work though that is as-yet untested.

Before setting up this package, you should have both Docker and git installed on your workstation.

1. Download and install this package somewhere on your system. For the sake of these instructions, we will assume you placed it in /opt/kicad-tools/
2. Build and deploy the local docker container.
	```
	cd /opt/kicad-tools
	git submodule update --init
	make
	```

This will spin for a while, downloading Ubuntu, KiCad, and the various tools we use. 

Alternatively, you can use the pre-built image from Github Container Registry:

    ```
    docker image tag ghcr.io/obra/kicad-tools:latest kicad-automation
    ```

If you get an error about being unable to connect to Docker, your Docker configuration
may require you to 'sudo' to run Docker. In that case
```sudo make```

Eventually, you should see something like 'Successfully built 6476202f4575'

3. Add our 'bin' directory to your shell's path. Typically, you'd do that by adding the line
`export PATH=/opt/kicad-tools/bin:$PATH` to your `.bashrc` or its equivalent.

If you needed to run `sudo make` before, you should also add the line ```export DOCKER_NEEDS_SUDO=1``` just below the PATH line.

You will need to restart your shell before it picks up any changes to your `.bashrc` or equivalent. 

If you'd prefer to be able to run Docker containers without `sudo`, 
you can find instructions for that here: 
https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user

4. On macOS, install 'realpath' using:
    ```
    brew install coreutils
    ```


You can verify that everything you've done so far is working by typing 
`kicad-docker-run hostname`

You should see something like this:

```$ kicad-docker-run hostname
0230e9b27ebb
```

If you don't get an error, things are on the right track.

## Configuring a project

### Makefile

A sample Makefile is distributed with this package. You can find it in the 'etc' directory.

```cp /opt/git-tools/etc/Makefile ./Makefile```

WARNING: DO NOT BLINDLY RUN THAT COMMAND IF YOU ALREADY HAVE A MAKEFILE.

### Git

To enable automatic graphical diffs of PCB layouts, you need to teach git how to handle
.kicad_pcb files

```
# echo "*.kicad_pcb diff=kicad_pcb" >> `git rev-parse --show-toplevel`/.gitattributes
# git config diff.kicad_pcb.command /opt/kicad-tools/bin/git-pcbdiff
```


## Caching

Generating diff-able PNGs of schematics and boards is a fairly slow operation. Because of that, we
cache the generated files. By default, they're cached in /tmp. Each board and schematic is uniquely identified in the cache, so it's safe to share a cache across multiple projects.

You may want to consider persisting the cache across reboots.

To configure the PCB image cache, set the environment variable `BOARD_CACHE_DIR`. For example, you could add this to your `.bashrc`

```
export BOARD_CACHE_DIR=$HOME/.kicad-tools/cache/boards
```

To configure the schematic image cache, set the environment variable `SCHEMATIC_CACHE_DIR`. For example, you could add this to your `.bashrc`

```
export SCHEMATIC_CACHE_DIR=$HOME/.kicad-tools/cache/schematics
```



## Usage

### Generating build artifacts

By default, all build artifacts are created in a subdirectory of the 'out' directory of your project.
To customize the name of the subdirectory artifacts are created in, set the `BOARD_SNAPSHOT_LABEL` environment variable.

To customize the output directory, set the `OUTPUT_PATH` environment variable.

To generate a whole package of fabrication outputs, 

```
$ make fabrication-outputs
```

To generate SVG schematics
```
$ make schematic-svg
```

To generate PDF schematics
```
$ make schematic-pdf
```

To generate gerbers, pdfs, dxfs, and svgs of your layout
``` 
$ make gerbers
```

To generate a CSV bom
```
$ make bom
```

To generate an HTML interactive BOM
```
$ make interactive-bom
```

If you need to log into the docker instance to debug something, there's a makefile target for that, too

```
$ make docker-shell
```

### Visual "diffs" between versions of a .kicad_pcb file

If you've configured git as described above, the regular `git diff` tool will show you a visual diff between two versions of a .kicad_pcb file.

In the future, this functionality may move to only running if you use `git difftool -gui`

To show the difference between your current checkout and the `HEAD` of your current branch, run

```
$ git diff HEAD my_board.kicad_pcb
```


### Visual "diffs" between versions of a .sch file

Due to some limitations in the information `git` provides to external git diff tools, you need to use a special command to compare schematics.

To compare the current checkout to the `HEAD` of your current branch

```
$ git schematic-diff HEAD my_board.sch
```

To compare the version of my_board.sch in `master` to the version as of tag `rev1`

```
$ git schematic-diff master rev1 my_board.sch
```

### Generate Production Files for JLCPCB

You can generate zipped gerbers and BOM placement files that can be used
directly with JLCPCB for board assembly. Use the JLCPCB-specific target, like
this:

    make fabrication-outputs-jlcpcb

This will create a directory under `out/jlcpcb` that contains a zip file of
the gerbers, the BOM parts file, and the parts placement file. These are the
files you will upload to JLCPCB for board fabrication and assembly.

This feature makes use of the scripts from
[JLCKicadTools](https://github.com/matthewlai/JLCKicadTools). For details about
how to use it, see
[the blog post](https://dubiouscreations.com/2019/10/21/using-kicad-with-jlcpcb-assembly-service)
referenced from that repo README.

You will need to do some preparations in advance. You need to see the blog
post, but the short version is:

1. Select your parts from the [JLCPCB Parts Library](https://jlcpcb.com/parts)
2. In your schematic, add a field containing the LCSC part number (begins with
   "C"). I suggest naming the field something like "LCSCStockCode" but the
   specific name is not important). Do this for every component you want to be
   assembled by JLCPCB.
3. Create a subdirectory in your project directory, named `jlcpcb`. In that
   directory place a file named `cpl_rotations_db.csv`. You can find a template
   for this file from
   [here](https://github.com/matthewlai/JLCKicadTools/blob/master/jlc_kicad_tools/cpl_rotations_db.csv)
4. **Required Manual Step** - Open pcbnew and generate a footprint position
   file:

    * *File->Fabrication Outputs->Footprint Position File*
    * CSV Format, units mm, "single file for board"
    * (In the future this step should be automated)

5. You can make edits in the rotations file if your parts are not placed with
   the correct orientation when you upload to JLCPCB. You can find more
   information about this from the blog post mentioned above. Unfortunately,
   the parts orientation process is a little bit trial and error. You need to
   upload the files to JLCPCB and look at the rendered component placements and
   make sure they are correct. Then make corrections using the rotations file
   and try again.

### Capturing a Screencast of Schematic and BOM Operations

For the `bom`, `schematic-pdf`, and `schematic-svg` targets, it is possible to
generate a screencast of the GUI operations performed in the docker container.
This may be helpful to debug problems with the expected output.

To enable this, add `DO_SCREENCAST=1` to your make command line, like this:

    make bom DO_SCREENCAST=1

You will end up with a `.ogv.` file in the output directory. You can view the
screencast with VLC or other tool that can decode `.ogv` files.
