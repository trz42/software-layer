# Software layer

The software layer of the NESSI project uses [EasyBuild](https://docs.easybuild.io), [Lmod](https://lmod.readthedocs.io) and [archspec](https://archspec.readthedocs.io).

See also https://www.eessi.io/docs/software_layer .

## Accessing the software stack

You can set up your environment by sourcing the init script:

```
$ source /cvmfs/pilot.nessi.no/versions/2023.06/init/bash
Found NESSI repo @ /cvmfs/pilot.nessi.no/versions/2023.06!
Derived subdirectory for software layer: x86_64/intel/broadwell
Using x86_64/intel/haswell subdirectory for software layer
Initializing Lmod...
Prepending /cvmfs/pilot.nessi.no/versions/2023.06/software/x86_64/intel/broadwell/modules/all to $MODULEPATH...
Environment set up to use NESSI software stack, have fun!
{NESSI 2023.06} $
```

### Accessing NESSI via a container

You need Singularity version 3.7 or newer. Then, simply run

```
$ ./eessi_container.sh
```
Once you get presented the prompt `Singularity>` run the above `source` command.

If you want to build a package for the software repository, simply add the arguments `--access rw`, e.g., full command would be

```
$ ./eessi_container.sh --access rw
```
Note, not all features/arguments listed via `./eessi_container.sh --help` are implemented.

# License

The software in this repository is distributed under the terms of the
[GNU General Public License v2.0](https://opensource.org/licenses/GPL-2.0).

See [LICENSE](https://github.com/NorESSI/software-layer/blob/main/LICENSE) for more information.

SPDX-License-Identifier: GPL-2.0-only
