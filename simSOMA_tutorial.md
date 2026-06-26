# simSOMA tutorial

This tutorial explains how to install and run `simSOMA` from the GitHub repository. It is intended for users who want copy-and-paste commands for a local Linux machine or for a simple cluster login node using `tmux`. The repository contains the simulator code, run scripts, example configuration files, and example topology inputs. Simulation outputs are generated locally when the pipeline is run; they are not part of the repository.

The workflow has eight steps:

1. Clone or update the GitHub repository.
2. Set up the Python environment.
3. Prepare a topology JSON file, either directly or by converting branch/organ CSV files.
4. Prepare a simulation config JSON file.
5. Run the simulation locally or on a cluster.
6. Inspect the output tables.
7. Optionally transform VAF spectra into observation-model outputs.
8. Optionally extract fixed, intermediate, private, and sharedness statistics.

All commands below assume that they are run from the top-level `simSOMA` repository folder unless stated otherwise.

---

## 1. Get the repository from GitHub

Clone the repository once on each machine where you want to run `simSOMA`. A clone is a local working copy of the GitHub repository. It contains the code and example files needed to run the simulator.

Using SSH:

```bash
mkdir -p "$HOME/Projects"
cd "$HOME/Projects"
git clone git@github.com:jlab-code/simSOMA.git
cd simSOMA
```

Using HTTPS:

```bash
mkdir -p "$HOME/Projects"
cd "$HOME/Projects"
git clone https://github.com/jlab-code/simSOMA.git
cd simSOMA
```

If the repository is private, the GitHub account or SSH key used on that machine must have access to `jlab-code/simSOMA`.

For later sessions, return to the same local clone:

```bash
cd "$HOME/Projects/simSOMA"
```

To update an existing clone with the latest version from GitHub, run:

```bash
git pull
```

Running `simSOMA` creates local files such as `.venv/`, `simSOMA_output/`, and log files. These files remain on the machine where the run was performed. They are ignored by Git and are not uploaded to GitHub.

---

## 2. Repository folder structure

After cloning, the repository has the following layout:

```text
simSOMA/
|-- README.md              # short GitHub landing page
|-- LICENSE                # MIT license
|-- CITATION.cff           # citation metadata
|-- CHANGELOG.md           # release notes
|-- VERSION                # current software version
|-- requirements.txt
|-- requirements.lock.txt
|-- simSOMA_corefunc/      # simulator source code, including topology checking
|-- simSOMA_scripts/       # setup, local-run, cluster-run, and utility scripts
|-- simSOMA_configs/       # simulation configuration files
|-- simSOMA_inputs/
|   |-- examples/          # tutorial inputs, quick-test topology, CSV examples
|   |-- templates/         # reusable topology templates
|   `-- topologies/        # main simulation topology files
|-- simSOMA_docs/          # stable design notes
`-- docs/                  # short repository documentation and links
```

During setup and simulation runs, additional local folders are created:

```text
.venv/                    # project-local Python environment
simSOMA_output/           # generated simulation outputs
```

These folders can be deleted and regenerated. They are not part of the distributed code repository.

---

## 3. Set up the Python environment

The same environment setup is used on a laptop and on a cluster. `simSOMA` builds one project-local virtual environment:

```text
simSOMA/.venv
```

Run the setup script once from the project root:

```bash
bash simSOMA_scripts/01_setup_env.sh
```

The setup script expects Python 3.11. If Python 3.11 is not already visible, it tries to use Conda directly, without requiring `conda init`. It creates or reuses the Conda environment `simsoma311`, then builds `.venv` from that Python.

After setup, the simulator should use:

```text
.venv/bin/python
```

You normally do not need to activate `.venv` manually. The run scripts use it automatically.

If your cluster uses a non-standard Conda installation, provide the Conda setup file explicitly:

```bash
export CONDA_SH=$HOME/miniconda3/etc/profile.d/conda.sh
bash simSOMA_scripts/01_setup_env.sh
unset CONDA_SH
```

If you want to force a specific Python 3.11 interpreter, use:

```bash
PYTHON_BIN=/path/to/python3.11 bash simSOMA_scripts/01_setup_env.sh
```

Check the version and source-file checksums:

```bash
bash simSOMA_scripts/02_version_report.sh
```

---

## 4. Check the topology

Before running a simulation, plot the topology JSON and verify that the branching structure and sampled organs are correct. This step does not require a simulation config file. If you prefer to enter the topology as branch and organ CSV tables, first convert those tables to a topology JSON as described in the topology-input section below, then run the topology check on the generated JSON.

Run the topology check. 

```bash
TOPO=simSOMA_inputs/examples/quick_test_2organs_topology.json
bash simSOMA_scripts/check_topology.sh "$TOPO"
```

For the quick-test topology, the output is written to a subfolder named after the topology JSON file:

```text
simSOMA_output/topology_check/quick_test_2organs_topology/topology_plot.png
simSOMA_output/topology_check/quick_test_2organs_topology/topology_plot.pdf
simSOMA_output/topology_check/quick_test_2organs_topology/topology_plot_layout.csv
simSOMA_output/topology_check/quick_test_2organs_topology/topology_plot_report.json
```

Open the PNG or PDF. Continue only after checking that the branch structure and sampled organs match the intended topology.

This folder is intentionally keyed by topology filename, not by simulation config. Different config files may use the same topology, and it is often useful to check a topology before writing any config file. Existing files with the same names are overwritten when the same topology is checked again. This is intentional: the folder is a live check of the current topology JSON file.

An explicit output folder can still be set with `OUTDIR`:


---

## 5. Anatomy of a topology input file

simSOMA uses one standard user-facing topology JSON file. This JSON can be written manually, or it can be generated from two simpler CSV files. The simulation config always points to the JSON file; the CSV converter is only a preprocessing helper.

```text
branch/organ CSV files  ->  user-friendly topology JSON  ->  internal step-based topology
```

### Option A: write the user-friendly topology JSON directly

A topology JSON contains two main blocks:

```json
{
  "unit": "years",
  "tree_coordinate_max": 10.0,
  "tree_age": 10.0,
  "branches": [],
  "events": []
}
```

The `unit` field can be `steps`, `years`, or `meters`. The coordinates themselves are interpreted through the usual config fields `topology.mapping_unit` and `topology.mapping_rate`. For consistency, the JSON `unit` and config `mapping_unit` should describe the same coordinate system.

#### Branches

Each branch has an `id`, a `parent`, a branch `length`, and branch-axis coordinates. The coordinates are deliberately general; they may represent time, distance, or another branch-axis coordinate.

```json
{
  "id": "B0_trunk",
  "parent": null,
  "length": 10.0,
  "start": 0.0,
  "end": 10.0,
  "start_age": 0.0,
  "end_age": 10.0,
  "branch_order": 0
}
```

Important fields:

```text
id            unique branch name
parent        parent branch ID, or null for the root/trunk
length        branch length in the topology unit
start         branch-axis coordinate where this branch begins
end           branch-axis coordinate where this branch ends
start_age     backward-compatible plotting alias for start
end_age       backward-compatible plotting alias for end
branch_order  branch order used for plotting and summaries
```

The `start_age` and `end_age` names are retained as legacy plotting aliases. They are aliases for the general `start` and `end` coordinates and do not imply that the topology must be measured in years. The topology-check plotter labels the axis according to the declared `unit`.

#### Events

Events specify branch formation or sampled organs. Each event must provide either a relative position `pos` from 0 to 1 along the branch, or a branch-local coordinate `time` in the same unit as `length`. The recommended form is to provide `pos`, because this is unambiguous after CSV conversion.

A branch event:

```json
{
  "branch": "B0_trunk",
  "pos": 0.5,
  "type": "branch",
  "target": "B1_lateral",
  "position": 5.0,
  "age": 5.0
}
```

An organ event:

```json
{
  "branch": "B1_lateral",
  "pos": 1.0,
  "type": "organ",
  "target": "O_lateral_tip",
  "position": 10.0,
  "age": 10.0,
  "terminal_tip": true
}
```

Important fields:

```text
branch        branch on which the event occurs
pos           relative position along that branch, from 0 to 1
type          "branch" or "organ"
target        child branch ID or sampled organ ID
position      absolute branch-axis coordinate used for human readability
age           backward-compatible plotting alias for position
terminal_tip  whether an organ is sampled at the end of its branch segment
```

For a branch event, `target` must match the `id` of a branch listed in the `branches` block. The `age` field is retained as a legacy plotting alias for the general `position` field and does not restrict the topology to age or years.

### Option B: enter the topology as branch and organ CSV files

Many users find it easier to first describe the topology with two CSV files. The branch CSV defines branch segments. The organ CSV defines sampled organs on those branch segments.

The recommended branch CSV headers are:

```csv
branch_id,parent_id,start,end
B0_trunk,,0,10
B1_lateral,B0_trunk,5,10
```

The recommended organ CSV headers are:

```csv
organ_id,branch_id,position
O_trunk_tip,B0_trunk,10
O_lateral_tip,B1_lateral,10
```

Here, `start`, `end`, and `position` are general coordinates along the same branch axis. They can represent years, meters, or another user-defined axis. The CSV files are therefore unit-neutral. The biological interpretation is set later by the topology JSON `unit` field and by the config fields `mapping_unit` and `mapping_rate`.

For convenience, the converter also accepts older or more informal aliases:

```text
Branch CSV aliases:
  id        -> branch_id
  parent    -> parent_id
  start_age -> start
  end_age   -> end

Organ CSV aliases:
  id     -> organ_id
  branch -> branch_id
  age    -> position
```

Convert the CSV files to the standard topology JSON with the Python converter:

```bash
python simSOMA_scripts/convert_topology_csv_to_json.py \
  --branches simSOMA_inputs/examples/example_topology_branches.csv \
  --organs simSOMA_inputs/examples/example_topology_organs.csv \
  --out simSOMA_inputs/examples/example_topology_from_csv.json \
  --unit years
```

The shell helper provides the same conversion with shorter syntax:

```bash
bash simSOMA_scripts/run_convert_topology_csv_to_json.sh \
  simSOMA_inputs/examples/example_topology_branches.csv \
  simSOMA_inputs/examples/example_topology_organs.csv \
  simSOMA_inputs/examples/example_topology_from_csv.json \
  years
```

Use `meters` instead of `years` if the branch-axis coordinates are distances:

```bash
bash simSOMA_scripts/run_convert_topology_csv_to_json.sh \
  simSOMA_inputs/examples/example_topology_branches.csv \
  simSOMA_inputs/examples/example_topology_organs.csv \
  simSOMA_inputs/examples/example_topology_from_csv.json \
  meters
```

Then check the generated topology JSON:

```bash
TOPO=simSOMA_inputs/examples/example_topology_from_csv.json
bash simSOMA_scripts/check_topology.sh "$TOPO"
```

Finally, point the usual simulation config to the generated JSON:

```json
"topology": {
  "topology_json": "simSOMA_inputs/examples/example_topology_from_csv.json",
  "mapping_unit": "years",
  "mapping_mode": "deterministic",
  "mapping_rate": 5.0
}
```

No config-schema changes are required. The converter simply creates the same user-friendly JSON format that can also be written manually.

---

## 6. Anatomy of a config JSON file

A simulation config file tells `simSOMA` which topology to use, which parameters to scan, and where outputs should go.

The quick-test config is:

```text
simSOMA_configs/quick_test_2organs.json
```

### Run block

```json
"run": {
  "experiment_name": "quick_test_2organs",
  "outdir_root": "simSOMA_output",
  "seed": 1
}
```

Important fields:

```text
experiment_name   name of the output folder
outdir_root       parent output folder; in the Git repository this is `simSOMA_output` in the project root
seed              base random seed
```

### Topology block

```json
"topology": {
  "topology_json": "simSOMA_inputs/examples/quick_test_2organs_topology.json",
  "mapping_unit": "years",
  "mapping_mode": "deterministic",
  "mapping_rate": 5.0
}
```

Important fields:

```text
topology_json   path to the topology JSON
mapping_unit    steps, years, or meters
mapping_mode    deterministic or poisson
mapping_rate    self-renewal divisions per topology unit
```

If `mapping_unit` is `years` or `meters`, `mapping_rate` is required.

### Simulation block

```json
"simulation": {
  "mode": "grid_parameter",
  "n_sim": 1,
  "summaries": true,
  "vaf_nbins": 20
}
```

The cleaned workflow uses `grid_parameter` mode. Fixed parameters are specified as one-element value lists. Parameter scans are specified as multi-value lists.

Example fixed parameter:

```json
"m": {
  "values": [4]
}
```

Example parameter scan:

```json
"m": {
  "values": [4, 8, 12]
}
```

### Biological parameter reference

The main scan parameters are stored under `simulation.modules`. Each parameter is written as a JSON object with a `values` list. A one-element list fixes the parameter. A multi-value list creates a grid scan over those values.

```text
simulation.modules.<module>.<parameter>.values
```

For example, this scans three values of `m` and keeps `rho` fixed:

```json
"self_renewal": {
  "m": { "values": [4, 8, 12] },
  "rho": { "values": [0.25] }
}
```

The main biological parameters are listed below. This tutorial denotes `sam_boundary_cells` by `C`, matching the notation used in the accompanying manuscript.

```text
self_renewal.m
  Number of long-lived apical stem-cell (ASC) positions in the simulated niche.
  Manuscript notation: m.

self_renewal.rho
  ASC turnover parameter. In each self-renewal round, rho is the probability that
  one symmetric replacement / displacement event occurs. Larger values increase
  lineage turnover and can increase fixation within the ASC niche.
  Manuscript notation: rho.

self_renewal.mu_year
  Legacy implementation field for the mutation input per topology unit. If the
  topology unit is years, this is the mutation input per year; if the topology
  unit is meters, it is the mutation input per meter. Internally, simSOMA converts
  this to a per-division mutation input by dividing by topology.mapping_rate. In
  the bundled configs, this is usually used as a relative mutation input because
  the simulator focuses on VAF spectra and sharing patterns.
  Manuscript notation: mu_unit; internal per-division value: mu_div.

self_renewal.victim_locality
  Locality of the displaced ASC during replacement. A value of 0 gives globally
  uniform displacement across the niche. Larger values make displacement more
  local; value 1 corresponds to nearest-neighbor displacement.

self_renewal.bias_mode
  How branch-local self-renewal bias is specified. The bundled manuscript configs
  usually use "fixed".

self_renewal.branch_bias_value
  Fixed branch-local bias value when bias_mode is "fixed". The bundled manuscript
  configs usually use 0.0, meaning no branch-local bias.

self_renewal.branch_bias_mean
  Mean branch-local bias when bias_mode uses a drawn bias value.

self_renewal.branch_bias_kappa
  Concentration parameter for drawn branch-local bias values.

pre_branching.sam_boundary_cells
  Target number of peripheral/SAM-boundary cells generated before branch or organ
  founder sampling. This controls the size of the local amplified cell population
  from which founders are sampled. Current configs require sam_boundary_cells >= m.
  Manuscript/tutorial notation: C.

branching.branch_precursor_number
  Requested number of branch founder/precursor cells sampled from the amplified
  SAM-boundary population to establish a new branch SAM. Conceptually, the
  realized/effective branch founder count is capped by the requested number, the
  number of ASC positions, and the SAM-boundary population size. In manuscript
  notation, this is requested P_b with P_b^eff = min(P_b, m, C). In the current
  valid configs C >= m, so the driver-level cap min(branch_precursor_number, m)
  is equivalent. The realized value is recorded as
  branch_precursor_number_realized_cells.

organ.organ_precursor_number
  Requested number of organ founder/precursor cells sampled from the amplified
  SAM-boundary population to establish an organ. The current driver caps the
  realized value at min(organ_precursor_number, sam_boundary_cells,
  organ_total_cells). In normal configs this equals the requested value. The
  realized value is recorded as organ_precursor_number_realized_cells.
  Manuscript notation: requested P_o.

organ.organ_total_cells
  Final number of cells in the simulated terminal organ before sequencing
  subsampling. The realized value is recorded as organ_total_cells_realized.
  Manuscript/tutorial notation: O.

organ.seq_fraction
  Fraction of terminal organ cells sampled as observed/sequenced cells. The number
  of sampled cells is ceil(seq_fraction * organ_total_cells), bounded between 1
  and organ_total_cells. The realized value is recorded as sequenced_cells_used.
```

A compact module block therefore looks like this:

```json
"modules": {
  "self_renewal": {
    "m": { "values": [4, 8, 12] },
    "rho": { "values": [0.0, 0.25, 1.0] },
    "mu_year": { "values": [1.0] },
    "victim_locality": { "values": [0.0] },
    "bias_mode": { "values": ["fixed"] },
    "branch_bias_value": { "values": [0.0] },
    "branch_bias_mean": { "values": [0.0] },
    "branch_bias_kappa": { "values": [1.0] }
  },
  "pre_branching": {
    "sam_boundary_cells": { "values": [64] }
  },
  "branching": {
    "branch_precursor_number": { "values": [1, 4, 16] }
  },
  "organ": {
    "organ_precursor_number": { "values": [1, 8] },
    "organ_total_cells": { "values": [64, 4096] },
    "seq_fraction": { "values": [1.0] }
  }
}
```

### Optional phyllotaxy settings

Phyllotaxy is configured in the `topology` block, not in `simulation.modules`. The bundled no-phyllotaxy configs use `mode: "off"`. The spiral-phyllotaxy configs use `mode: "spiral"`.

```json
"phyllotaxy": {
  "mode": "off",
  "divergence_angle_deg": 137.5,
  "tie_tol": 1e-9
}
```

```text
phyllotaxy.mode
  Phyllotaxy overlay mode. Allowed values are off, random, spiral, distichous,
  tristichous, and decussate. Use off if no phyllotactic placement should be
  imposed.

phyllotaxy.divergence_angle_deg
  Divergence angle in degrees for spiral phyllotaxy. The bundled spiral configs
  use 137.5 degrees.

phyllotaxy.tie_tol
  Tolerance for grouping events that occur at effectively the same developmental
  position before assigning phyllotactic placement.
```

### Output and export options

The main output/export options are stored directly under `simulation`:

```text
simulation.n_sim
  Number of replicate simulations per parameter combination.

simulation.summaries
  Whether summary tables are computed. This should normally be true.

simulation.vaf_nbins
  Number of bins for legacy binned VAF summaries. The main recommended VAF
  output is the exact allele-count spectrum, not the legacy binned table.

simulation.summary_private_shared
  Whether private/shared summary statistics are computed.

simulation.store_full_results
  Whether full replicate-level internal JSON result objects are retained. This
  can create large output folders and is usually false.

simulation.export_raw_vafs
  Whether raw VAF rows are exported. This can create large files and is usually
  false.

simulation.export_vaf_count_spectra
  Whether exact allele-count/VAF spectra are exported. This is the recommended
  VAF output and should normally be true.

simulation.export_sharing_summaries
  Whether aggregated among-organ sharing summaries are exported. This should
  normally be true.

simulation.export_replicate_sharing_summaries
  Whether replicate-level sharing summaries are exported. Useful for downstream
  uncertainty calculations, but larger than aggregated summaries.

simulation.export_legacy_binned_vaf_summaries
  Whether old aggregated binned-VAF summary files are exported. Usually false.

simulation.export_legacy_binned_vaf_replicates
  Whether old replicate-level binned-VAF files are exported. Usually false.
```

A typical compact output block is:

```json
"simulation": {
  "mode": "grid_parameter",
  "n_sim": 10,
  "summaries": true,
  "vaf_nbins": 20,
  "summary_private_shared": true,
  "store_full_results": false,
  "export_raw_vafs": false,
  "export_vaf_count_spectra": true,
  "export_sharing_summaries": true,
  "export_replicate_sharing_summaries": true,
  "export_legacy_binned_vaf_summaries": false,
  "export_legacy_binned_vaf_replicates": false
}
```

### Topology-check plotting options

The `check.topology_plot` block controls the appearance of topology-check figures. These settings do not change the simulation. Most users can leave them unchanged. Commonly edited settings are:

```text
check.topology_plot.enabled
  Whether the topology-check plot is produced during check steps.

check.topology_plot.fig_width, check.topology_plot.fig_height
  Figure size in inches.

check.topology_plot.dpi
  Output resolution.

check.topology_plot.y_ticks
  Tick labels shown on the topology-coordinate axis. Use "auto" for automatic
  ticks, or provide a comma-separated string such as "0,50,100,150,200". If
  manual ticks are outside the plotted coordinate range, simSOMA ignores them
  and falls back to automatic ticks to avoid compressing small tutorial plots.

check.topology_plot.y_label
  Axis label for the topology-check plot. Use "auto" to derive the label from
  the topology JSON unit. For example, years are labeled as "Age (years)",
  meters as "Position (meters)", and steps as "Self-renewal steps".

check.topology_plot.show_nonterminal_organs
  Whether organs that are not terminal tips should be shown in the topology
  check plot.

check.topology_plot.title
  Plot title.
```

---

## 7. Run the quick smoke test

The fastest end-to-end test is:

```bash
bash simSOMA_scripts/run_quick_test.sh
```

The script does three things:

```text
1. Ensures .venv exists, using the same setup script as above if needed.
2. Plots the quick-test topology.
3. Runs a one-split quick simulation.
```

The main result folder is:

```text
simSOMA_output/quick_test_2organs/grid_parameter/
```

---

## 8. Run a config locally

For normal local use, run:

```bash
CFG=simSOMA_configs/quick_test_2organs.json
bash simSOMA_scripts/run_config_local.sh "$CFG"
```

For a small local split run, assign the config and options first, then call the runner. This keeps each command line short and safe to copy from the PDF.

```bash
CFG=simSOMA_configs/simulation_04_organ_formation_rough.json
export N_SPLITS=4
export N_PARALLEL_JOBS=2
export RUN_CHECK=yes
bash simSOMA_scripts/run_config_local.sh "$CFG"
unset N_SPLITS N_PARALLEL_JOBS RUN_CHECK
```

Useful options:

```text
N_SPLITS          number of split jobs
N_PARALLEL_JOBS   number of parallel local jobs
RUN_CHECK         yes/no; run topology/config check before simulation
CLEANUP_SPLITS    yes/no; remove split folders after merging
SPLIT_AXIS        parameter is the usual setting
```

For a first run, keep `RUN_CHECK=yes`. This uses the same topology-check script described above. Rechecking the same topology overwrites the generated `topology_plot.*` files for that topology.

---

## 9. Run on a cluster

On the cluster, clone the same Git repository once, or update an existing clone before running. For a first clone using SSH:

```bash
cd "$HOME"
git clone git@github.com:jlab-code/simSOMA.git
cd simSOMA
```

For an existing clone:

```bash
cd "$HOME/simSOMA"
git pull
```

If the repository is still private, the cluster must use a GitHub account or SSH key that has access to `jlab-code/simSOMA`.

Use the same setup step as on a laptop:

```bash
bash simSOMA_scripts/01_setup_env.sh
```

The cluster wrapper then starts the run inside a detached `tmux` session. It does not require a scheduler. If `.venv` is missing, the wrapper calls the same setup script once before starting `tmux`; no separate cluster-specific environment setup is used. If `RUN_CLUSTER_CHECK=yes`, the wrapper uses the same topology-check script and overwrites the generated topology-check files for the same topology.

From the project root on the cluster, assign the config and options first, then call the cluster wrapper:

```bash
CFG=simSOMA_configs/quick_test_2organs.json
export PROJECT_DIR="$PWD"
export SESSION=simsoma_test
export N_SPLITS=20
export N_PARALLEL_JOBS=4
export RUN_CLUSTER_CHECK=yes
bash simSOMA_scripts/cluster_prepare_and_start.sh "$CFG"
unset PROJECT_DIR SESSION N_SPLITS N_PARALLEL_JOBS RUN_CLUSTER_CHECK
```

For a larger run, increase `N_SPLITS` and `N_PARALLEL_JOBS`, for example:

```bash
CFG=simSOMA_configs/simulation_01_topology_depth_fine.json
export PROJECT_DIR="$PWD"
export SESSION=simsoma_simulation_01
export N_SPLITS=300
export N_PARALLEL_JOBS=20
export CLEANUP_SPLITS=yes
export SPLIT_AXIS=parameter
export RUN_CLUSTER_CHECK=yes
bash simSOMA_scripts/cluster_prepare_and_start.sh "$CFG"
unset PROJECT_DIR SESSION N_SPLITS N_PARALLEL_JOBS
unset CLEANUP_SPLITS SPLIT_AXIS RUN_CLUSTER_CHECK
```

Monitor the run:

```bash
tail -f cluster_run.log
```

Attach to the `tmux` session:

```bash
tmux attach -t simsoma_simulation_01
```

Detach from `tmux` without stopping the run:

```text
Ctrl-b, then d
```

List relevant running processes:

```bash
pgrep -a -u "$USER" -f '00_pipeline.sh|launch_grid_splits.py|run_from_config.py'
```

---

## 10. Main output files

After a successful run, the main output folder is:

```text
simSOMA_output/<experiment_name>/grid_parameter/
```

For the quick test:

```bash
OUT="simSOMA_output/quick_test_2organs/grid_parameter"
ls -lh "$OUT"
```

Important files:

```text
parameter_sets.csv
aggregated_summaries.csv
organ_aggregated_summaries.csv
sharing_aggregated_summaries.csv
vaf_count_spectrum_aggregated_summaries.csv
sharing_replicate_summaries.csv.gz
vaf_count_spectrum_replicate_summaries.csv.gz
manifest.json
split_plan.json
```

### Parameter sets

```bash
python - <<'PY'
import pandas as pd

out = "simSOMA_output/quick_test_2organs/grid_parameter"
params = pd.read_csv(f"{out}/parameter_sets.csv")
print(params.head())
print("Number of parameter sets:", len(params))
PY
```

### Organ-level summaries

```bash
python - <<'PY'
import pandas as pd

out = "simSOMA_output/quick_test_2organs/grid_parameter"
org = pd.read_csv(f"{out}/organ_aggregated_summaries.csv")
print(org.head())
print(org.columns.tolist())
PY
```

### VAF count spectra

```bash
python - <<'PY'
import pandas as pd

out = "simSOMA_output/quick_test_2organs/grid_parameter"
vaf = pd.read_csv(f"{out}/vaf_count_spectrum_aggregated_summaries.csv")
print(vaf.head())
print(vaf.columns.tolist())
PY
```

The VAF spectrum table is the main output for allele-count/VAF distributions. It stores exact allele-count spectra and can be re-binned downstream.

### Variant sharing summaries

```bash
python - <<'PY'
import pandas as pd

out = "simSOMA_output/quick_test_2organs/grid_parameter"
sharing = pd.read_csv(f"{out}/sharing_aggregated_summaries.csv")
print(sharing.head())
print(sharing.columns.tolist())
PY
```

---

## 11. Transform VAF spectra with an observation model

The main simulator output represents a layer-equivalent developmental VAF spectrum. In some applications, the biological source of mutations and the way reads are observed are not the same thing. For example, a tissue may contain several independently mutating histogenic layers, and reads may be interpreted from a phased or collapsed assembly. The observation-model transform is a post-processing step. It does not rerun the developmental simulation and it does not modify the original `grid_parameter/` files. Instead, it reads an existing simSOMA output folder and writes a derived folder under:

```text
simSOMA_output/<experiment_name>/observation_model_transforms/<scenario_name>/
```

The transform treats the simulated spectrum as a layer-equivalent template. For a multi-layer model, the template is copied to the requested source layers, and those copied variants are treated as distinct layer-specific mutations. The transform therefore does not assume that the same mutation is present in all layers.

For deterministic layer weighting, the observed VAF is:

```text
observed_vaf = source_vaf * effective_layer_contribution * phase_factor
```

In manuscript notation, `source_vaf` corresponds to the developmental source-layer VAF `v_io^(k)`, `effective_layer_contribution` corresponds to the layer contribution `a_k^(s)`, and `phase_factor` corresponds to the phasing factor `eta_s`. The transformed observed VAF is therefore:

```text
v_tilde_io^(k,s) = eta_s * a_k^(s) * v_io^(k)
```

For bulk sampling, `effective_layer_contribution` is the user-specified layer weight and the weights across layers should sum to 1. For layer-specific sampling, the target layer is observed with contribution 1.0 and non-target layers are not retained in the layer-specific output. The phase factor is 1.0 for phased observations and 0.5 for unphased observations.


### Three-layer bulk-unphased example

This example transforms the quick-test output into a three-layer bulk-unphased observation model with layer contributions L1 = 0.10, L2 = 0.70, and L3 = 0.20.

```bash
RUN=simSOMA_output/quick_test_2organs
SCENARIO=three_layer_bulk_unphased_L1_0p1_L2_0p7_L3_0p2
LAYERS=L1,L2,L3
WEIGHTS=0.10,0.70,0.20
SAMPLING=bulk
PHASE=unphased

export OVERWRITE=yes
CMD=(bash simSOMA_scripts/run_observation_model_transform.sh)
CMD+=("$RUN" "$SCENARIO" "$LAYERS" "$WEIGHTS")
CMD+=("$SAMPLING" "$PHASE")
"${CMD[@]}"
unset OVERWRITE
```

The output folder is:

```text
simSOMA_output/quick_test_2organs/observation_model_transforms/three_layer_bulk_unphased_L1_0p1_L2_0p7_L3_0p2/
```

Check the generated files:

```bash
OUT=simSOMA_output/quick_test_2organs/observation_model_transforms/three_layer_bulk_unphased_L1_0p1_L2_0p7_L3_0p2
ls -lh "$OUT"
```

Expected files:

```text
observed_vaf_count_spectrum_aggregated_summaries.tsv
observed_vaf_count_spectrum_replicate_summaries.tsv.gz
observation_model_metadata.tsv
manifest.tsv
README.txt
```

Inspect the transformed aggregated spectrum:

```bash
head -n 20 "$OUT/observed_vaf_count_spectrum_aggregated_summaries.tsv" | column -t -s $'\t'
```

Inspect the transform metadata:

```bash
cat "$OUT/observation_model_metadata.tsv" | column -t -s $'\t'
cat "$OUT/manifest.tsv" | column -t -s $'\t'
```

Check the expected transformation for fixed source-layer variants:

```bash
python - <<'PY'
import pandas as pd

out = "simSOMA_output/quick_test_2organs/observation_model_transforms/three_layer_bulk_unphased_L1_0p1_L2_0p7_L3_0p2"
d = pd.read_csv(f"{out}/observed_vaf_count_spectrum_aggregated_summaries.tsv", sep="\t")
fixed = d[d["source_vaf"].round(6).eq(1.0)]
cols = ["source_layer", "source_vaf", "effective_layer_contribution", "phase_factor", "observed_vaf"]
print(fixed[cols].drop_duplicates().sort_values("source_layer").to_string(index=False))
PY
```

For this bulk-unphased example, source-layer fixed variants should be shifted to approximately:

```text
L1: 1.0 * 0.10 * 0.5 = 0.05
L2: 1.0 * 0.70 * 0.5 = 0.35
L3: 1.0 * 0.20 * 0.5 = 0.10
```

### Layer-specific example

This example observes only L2 in an unphased assembly. The effective layer contribution is 1.0 because the sample is layer-specific; the unphased factor is 0.5.

```bash
RUN=simSOMA_output/quick_test_2organs
SCENARIO=three_layer_L2_layer_specific_unphased
LAYERS=L1,L2,L3
WEIGHTS=0.10,0.70,0.20
SAMPLING=layer_specific
PHASE=unphased
TARGET=L2

export OVERWRITE=yes
CMD=(bash simSOMA_scripts/run_observation_model_transform.sh)
CMD+=("$RUN" "$SCENARIO" "$LAYERS" "$WEIGHTS")
CMD+=("$SAMPLING" "$PHASE" --target-layer "$TARGET")
"${CMD[@]}"
unset OVERWRITE
```

A source-layer fixed variant in L2 should be transformed as:

```text
observed_vaf = 1.0 * 1.0 * 0.5 = 0.5
```

The original simulation output remains unchanged. To remove only transformed observation outputs, delete the corresponding scenario folder under `observation_model_transforms/`.


---

## 12. Extract formula statistics

The formula-statistics extractor is a post-processing step that summarizes the VAF and sharing spectra into the statistics used in the manuscript: fixed fraction, intermediate fraction, private fraction, and normalized sharedness. It does not rerun the simulation and does not modify the primary output tables. These statistics are analysis summaries, not developmental hyperparameters. The extractor is designed to run on an experiment folder. It automatically looks for the primary simSOMA output and, if present, all observation-model transform folders with standardized table names. For the primary simSOMA output, the VAF used for fixed and intermediate calls is:

```text
formula_vaf = sampled_vaf
```

For observation-model transformed outputs, fixed and intermediate calls are made relative to the expected fixed VAF under that observation scenario:

```text
formula_vaf = observed_vaf / expected_fixed_observed_vaf
```

Thus, a layer-fixed mutation in a bulk-unphased scenario is classified as fixed at the VAF expected after layer weighting and phasing, not only at raw observed VAF = 1. The `LOW_THRESHOLD` parameter is therefore a relative threshold. For example, `LOW_THRESHOLD=0.05` means 5% of the scenario-specific fixed VAF.

Private fraction and normalized sharedness are computed per focal organ. They are cross-organ statistics because they use the sharing degree of each variant across all sampled organs, but each organ-level output row answers the question: among variants observed in this organ, what fraction is private, and how broadly shared are they?


Run the extractor on an experiment folder:

```bash
RUN=simSOMA_output/quick_test_2organs
bash simSOMA_scripts/run_extract_formula_statistics.sh "$RUN"
```

This command searches for:

```text
simSOMA_output/<experiment_name>/grid_parameter/vaf_count_spectrum_aggregated_summaries.csv
simSOMA_output/<experiment_name>/observation_model_transforms/*/observed_vaf_count_spectrum_aggregated_summaries.tsv
```

If multiple observation scenarios are present, the extractor runs on all of them. Existing `formula_statistics_tables/` folders are overwritten. The primary-output statistics are written to:

```text
simSOMA_output/<experiment_name>/grid_parameter/formula_statistics_tables/
```

Observation-transform statistics are written inside each scenario folder:

```text
simSOMA_output/<experiment_name>/observation_model_transforms/<scenario_name>/formula_statistics_tables/
```

Each statistics folder contains:

```text
organ_level_formula_statistics.tsv
parameter_set_formula_statistics_summary.tsv
statistic_definitions.tsv
extraction_run_summary.tsv
```

The experiment folder also receives a manifest of all processed sources:

```text
formula_statistics_extraction_manifest.tsv
```

### Output levels

The extractor writes two analysis levels.

```text
organ_level_formula_statistics.tsv
  One row per set_id x organ_id.
  This is the detailed diagnostic table.

parameter_set_formula_statistics_summary.tsv
  One row per set_id x statistic.
  This is the figure-ready table.
```

The parameter-set summary is built from the organ-level table. For each `set_id` and each statistic, the extractor averages the organ-level values across sampled organs and computes their standard deviation, minimum, median, and maximum. The summary columns are `organ_mean`, `organ_sd`, `organ_min`, `organ_median`, `organ_max`, and `n_organs_with_stat`. The summary table is therefore conditioned only on the fixed combinatorial parameter setting, represented by `set_id`. The input parameter values for that `set_id` are then copied from:

```text
simSOMA_output/<experiment_name>/grid_parameter/parameter_sets.csv
```

This means that the summary table keeps true config/grid input parameters, such as `m`, `rho`, `sam_boundary_cells`, `branch_precursor_number`, `organ_precursor_number`, `organ_total_cells`, and `seq_fraction`, but it does not group by organ-derived descriptors. For example, `n_bottlenecks_root_to_organ` is an organ-level descriptor, not a simulation input parameter, and should not split the parameter-set summary.

For Figure-style plotting, use:

```text
parameter_set_formula_statistics_summary.tsv
```

and plot:

```text
organ_mean  = point or line value
organ_sd    = organ-to-organ standard deviation
```

For the bundled quick test, there is one parameter combination and two sampled organs. The expected summary table therefore has:

```text
1 parameter setting x 4 statistics = 4 rows
n_organs_with_stat = 2 for each statistic
```

For a larger grid scan, the expected number of rows is:

```text
number of parameter combinations x number of statistics
```

With the default four statistics, this is:

```text
number of parameter combinations x 4
```

### Inspect the output

Inspect the generated files:

```bash
RUN=simSOMA_output/quick_test_2organs
find "$RUN" -path '*/formula_statistics_tables/*' -type f -print
find "$RUN" -name 'formula_statistics_extraction_manifest.tsv' -print
```

Inspect the primary organ-level statistics:

```bash
RUN=simSOMA_output/quick_test_2organs
STATS="$RUN/grid_parameter/formula_statistics_tables"
head -n 20 "$STATS/organ_level_formula_statistics.tsv" | column -t -s $'\t'
```

Inspect the parameter-set-level summary:

```bash
RUN=simSOMA_output/quick_test_2organs
STATS="$RUN/grid_parameter/formula_statistics_tables"
head -n 20 "$STATS/parameter_set_formula_statistics_summary.tsv" | column -t -s $'\t'
```

Check how many parameter combinations and organs were summarized:

```bash
python - <<'PY'
import pandas as pd

run = "simSOMA_output/quick_test_2organs"
params = pd.read_csv(f"{run}/grid_parameter/parameter_sets.csv")
summary = pd.read_csv(f"{run}/grid_parameter/formula_statistics_tables/parameter_set_formula_statistics_summary.tsv", sep="\t")

print("Number of parameter combinations:", len(params))
print("Statistics in summary:", sorted(summary["statistic"].unique()))
print("Rows in summary table:", len(summary))
print("n_organs_with_stat values:", sorted(summary["n_organs_with_stat"].dropna().unique()))
PY
```

Inspect the statistic definitions:

```bash
RUN=simSOMA_output/quick_test_2organs
STATS="$RUN/grid_parameter/formula_statistics_tables"
cat "$STATS/statistic_definitions.tsv" | column -t -s $'\t'
```

If an observation-model transform exists, inspect its summary in the same way:

```bash
RUN=simSOMA_output/quick_test_2organs
SCENARIO=three_layer_bulk_unphased_L1_0p1_L2_0p7_L3_0p2
STATS="$RUN/observation_model_transforms/$SCENARIO/formula_statistics_tables"
head -n 20 "$STATS/parameter_set_formula_statistics_summary.tsv" | column -t -s $'\t'
cat "$STATS/statistic_definitions.tsv" | column -t -s $'\t'
```

Use a different relative low-VAF threshold if needed:

```bash
RUN=simSOMA_output/quick_test_2organs
export LOW_THRESHOLD=0.05
bash simSOMA_scripts/run_extract_formula_statistics.sh "$RUN"
unset LOW_THRESHOLD
```

Optional fixed filters can be passed through `FIXED_FILTERS`, for example:

```bash
RUN=simSOMA_output/quick_test_2organs
export LOW_THRESHOLD=0.05
export FIXED_FILTERS="--fixed rho=0 --fixed m=min,max"
bash simSOMA_scripts/run_extract_formula_statistics.sh "$RUN"
unset LOW_THRESHOLD FIXED_FILTERS
```

## 13. Clean reruns

If you rerun with the same `experiment_name`, remove the previous output first:

```bash
rm -rf simSOMA_output/quick_test_2organs
rm -rf simSOMA_output/quick_test_2organs__psplit_*
```

Then rerun:

```bash
CFG=simSOMA_configs/quick_test_2organs.json
bash simSOMA_scripts/run_config_local.sh "$CFG"
```

For publication-scale or cluster-scale runs, it is often safer to use a new `experiment_name` rather than overwriting an old result. These generated output folders are ignored by Git and should remain local unless you deliberately archive them elsewhere.

---

## 14. Common problems

### `.venv` is missing

Run the setup script from the project root:

```bash
bash simSOMA_scripts/01_setup_env.sh
```

### Python version is rejected

The default workflow expects Python 3.11. First try the standard setup command:

```bash
bash simSOMA_scripts/01_setup_env.sh
```

If Conda is installed in a non-standard location, provide `CONDA_SH` explicitly:

```bash
export CONDA_SH=$HOME/miniconda3/etc/profile.d/conda.sh
bash simSOMA_scripts/01_setup_env.sh
unset CONDA_SH
```

If you already know the path to a Python 3.11 interpreter, provide it explicitly:

```bash
PYTHON_BIN=/path/to/python3.11 bash simSOMA_scripts/01_setup_env.sh
```

Do not use `SIMSOMA_ALLOW_OTHER_PYTHON=1` for normal runs. It is only an emergency override for users who deliberately accept non-reproducible Python versions.

### The config path is not found

Make sure you are in the Git repository root:

```bash
pwd
ls simSOMA_configs
```

Then run with a path relative to the project root:

```bash
CFG=simSOMA_configs/quick_test_2organs.json
bash simSOMA_scripts/run_config_local.sh "$CFG"
```

If you are in an older non-Git copy such as `simSOMA_beta`, stop and switch to the Git-controlled repository before running or editing the pipeline.

### `git pull` or `git clone` fails on the private repository

If the repository is still private, the machine must authenticate to GitHub with an account or SSH key that has access to `jlab-code/simSOMA`.

For SSH clones, test access with:

```bash
ssh -T git@github.com
```

For HTTPS clones, GitHub may require a personal access token rather than a password.

### The topology check was overwritten

Topology checks are written to `simSOMA_output/topology_check/<topology_json_name>/`. Rerunning the check for the same topology overwrites the previous `topology_plot.*` files. This is intentional, because the folder represents the current version of that topology file.

To preserve multiple versions, either rename the topology JSON file or set a custom output folder:

```bash
TOPO=simSOMA_inputs/examples/quick_test_2organs_topology.json
export OUTDIR=simSOMA_output/topology_check/my_saved_check
bash simSOMA_scripts/check_topology.sh "$TOPO"
unset OUTDIR
```

### A `tmux` session already exists

Attach to it:

```bash
tmux attach -t simsoma_test
```

or choose a different session name:

```bash
CFG=simSOMA_configs/quick_test_2organs.json
export SESSION=simsoma_test_02
bash simSOMA_scripts/cluster_prepare_and_start.sh "$CFG"
unset SESSION
```
