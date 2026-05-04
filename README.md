# Wildfire Risk Modeling Exercise — Cell2Fire W

**UL Research Institutes | Wildfire Commons | 2026**

Wildfire spread simulation using [Cell2Fire W](https://github.com/fire2a/C2F-W) with the Scott & Burgan 40-class fuel model (`--sim S`), applied to two synthetic exercise scenarios: **Town of Forests** (Module A) and **Town of Prairies** (Module B).

---

## Setup

```bash
git clone https://github.com/AlvaroGalvan1/wildfire-c2fw-exercise.git
cd wildfire-c2fw-exercise
chmod +x install.sh
./install.sh
```

`install.sh` will:
1. Install Python dependencies from `requirements.txt`
2. Install system dependencies (`g++`, `libboost`, `libtiff`)
3. Clone and compile C2F-W from source
4. Create the runtime directory structure

> **On Wildfire Commons:** Use the Git Extension panel to clone this repo, then click **Install requirements.txt**. Run `install.sh` from a terminal cell in the notebook.

---

## Add Exercise Data

After setup, add the exercise data from the Wildfire Commons UI:

```
data-raw/
├── forest/    ← Forest scenario TIFs, GeoJSONs, weather CSV
└── prairie/   ← Prairie scenario TIFs, GeoJSONs, weather CSV
```

Use **Add Files to Current Folder** in the Wildfire Commons file panel to populate these directories. Data is not committed to this repo.

---

## Run the Notebooks

Run in order for each town:

| Notebook | Purpose | Report Section |
|---|---|---|
| `01_data_exploration.ipynb` | Visualize all raw inputs | Inputs Used |
| `02_data_transformation.ipynb` | Reproject → C2F-W instance folder | Workflow + Assumptions |
| `03_run_simulation.ipynb` | Execute Cell2Fire W | Model Architecture |
| `04_results_and_outputs.ipynb` | Burn probability, exposure, export | Outputs + Deliverables |

Select the town at the top of each notebook:
```python
TOWN = "forest"   # or "prairie"
```

---

## Repository Structure

```
wildfire-c2fw-exercise/
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_data_transformation.ipynb
│   ├── 03_run_simulation.ipynb
│   └── 04_results_and_outputs.ipynb
├── config/
│   ├── forest.yaml          # forest scenario parameters
│   └── prairie.yaml         # prairie scenario parameters
├── src/
│   └── utils.py             # shared helper functions
├── data-raw/                # exercise data (not in git)
├── instance/                # C2F-W inputs (generated)
├── results/                 # simulation outputs (generated)
├── plots/                   # figures (generated)
├── install.sh               # environment setup script
├── requirements.txt
└── README.md
```

---

## Model

- **Simulator:** Cell2Fire W (C2F-W) — [fire2a/C2F-W](https://github.com/fire2a/C2F-W)
- **Fuel model:** Scott & Burgan 40-class (`--sim S`)
- **Grid:** ~27m cells, EPSG:5070 (CONUS Albers)
- **Mode:** Single deterministic run (nsims=1) → scalable to probabilistic (nsims=100+)

---

## Contact

- Exercise questions: FireRisk@ul.org
- Wildfire Commons: info@wildfirecommons.org
