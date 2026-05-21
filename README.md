# Wildfire Risk Modeling Exercise — Cell2Fire W

**UL Research Institutes | Wildfire Science & Technology Commons | 2026**

Wildfire spread simulation using Cell2Fire W (C2F-W) with the Scott & Burgan 40-class fuel model (`--sim S`), applied to two synthetic exercise scenarios provided by the Exercise Planning & Conduct Team.

---

## Scenarios

| Module | Town | Terrain | Vegetation | Deadline |
| :--- | :--- | :--- | :--- | :--- |
| **A** | Town of Forests | Mountainous, variable elevation | High tree density, WUI intermix | April 21, 2026 |
| **B** | Town of Prairies | Flat, consistent elevation | Lower tree density, WUI interface | May 21, 2026 |

Each scenario covers a 5km x 5km area with synthetic spatial data including building footprints, surface fuels, tree lists, ignition points, and synoptic weather observations.

---

## Results

| Town | Grid | Burned Area | Buildings Exposed | Runtime |
| :--- | :--- | :--- | :--- | :--- |
| **Town of Forests** | 253 x 250 @ 26.9m | 263.2 ha | 332 / 4,498 (7.4%) | ~2.3s |
| **Town of Prairies** | 213 x 210 @ 27.6m | 683.0 ha | 96 / 2,090 (4.6%) | ~3s |

> **Simulation mode:** single deterministic run (`nsims=1`), 12-hour duration, Scott & Burgan fuel model.

---

## Setup

```bash
git clone [https://github.com/AlvaroGalvan1/wildfire-c2fw-exercise.git](https://github.com/AlvaroGalvan1/wildfire-c2fw-exercise.git)
cd wildfire-c2fw-exercise
chmod +x install.sh
./install.sh
```

`install.sh` handles:
* Python dependencies (`requirements.txt`)
* System dependencies (`g++`, `libboost`, `libtiff`)
* Cloning and compiling C2F-W from source
* Creating the runtime directory structure

> **Note:** On Wildfire Commons, use the Git Extension panel to clone, then run `./install.sh` from a terminal cell.

### Add Exercise Data

Populate these directories using the Wildfire Commons UI (*Add Files to Current Folder*). Data files are not committed to this repo.

```text
data-raw/
├── forest/
│   ├── forest-surface-fuels-and-surface-data/
│   ├── forest-ignition/
│   ├── forest-weather-data/
│   └── forest-building-data/
└── prairie/
    ├── prairies-surface-fuels-and-surface-data/  ← note: prairies (plural)
    ├── prairie-ignition/
    ├── prairie-weather-data/
    └── prairie-building-data/
```

### Run the Notebooks

Set `TOWN = "forest"` or `TOWN = "prairie"` at the top of each notebook. Run in order:

| Notebook | Purpose | Report Section |
| :--- | :--- | :--- |
| `01_data_exploration.ipynb` | Visualise all raw inputs | Inputs Used |
| `02_data_transformation.ipynb` | Reproject -> C2F-W instance folder | Workflow + Assumptions |
| `03_run_simulation.ipynb` | Execute Cell2Fire W | Model Architecture |
| `04_results_and_outputs.ipynb` | Fire perimeter, exposure, export | Outputs + Deliverables |

> **Important:** Always *Restart Kernel and Run All Cells* — do not run cells out of order.

---

## Repository Structure

```text
wildfire-c2fw-exercise/
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_data_transformation.ipynb
│   ├── 03_run_simulation.ipynb
│   └── 04_results_and_outputs.ipynb
├── config/
│   ├── forest.yaml
│   └── prairie.yaml
├── src/
│   └── utils.py
├── data-raw/                # exercise data (not tracked)
├── instance/                # C2F-W inputs (generated, not tracked)
├── results/                 # simulation outputs (generated, not tracked)
├── plots/                   # figures (generated, not tracked)
├── C2F-W/                   # compiled simulator (not tracked)
├── install.sh
├── requirements.txt
└── README.md
```

---

## Data Transformation Pipeline

| Step | Input | Output | Method |
| :--- | :--- | :--- | :--- |
| **1** | Elevation (EPSG:4326) | Reference grid (EPSG:5070, ~27m) | Bilinear resampling |
| **2** | SB40 fuel raster | `fuels.asc` | Nearest-neighbour (categorical) |
| **3** | Elevation | `elevation.asc` | Bilinear resampling |
| **4** | Rhof 1hr, Depth, Moist 1hr | CBD, CBH, FMC layers | Bilinear; FMC fraction -> % |
| **5** | Aligned elevation | Slope & aspect | Sobel filter; boundary eroded 1px |
| **6** | CBD | CCF | 95th-percentile normalisation |
| **7** | Synoptic weather CSV | `Weather.csv` | 10-min -> hourly mean; mph -> km/h |
| **8** | Ignition GeoJSON | `Ignitions.csv` | WGS84 -> EPSG:5070 -> row-major cell index |
| **9** | C2F-W `--gen-data` | `Data.csv` patched | Slope, aspect, CBD, CBH, FMC, CCF |

---

## Inputs Used

The following table lists only the specific datasets consumed by the C2F-W model and pipeline:

| File | Status | Description / Usage |
| :--- | :--- | :--- |
| `*_SB40.tif` | Used | Primary fuel classification |
| `*_elevation.tif` | Used | Reference grid; slope/aspect derived |
| `*_rhof1.tif` | Used | Proxy for canopy bulk density |
| `*_depth.tif` | Used | Proxy for canopy base height |
| `*_moist1.tif` | Used | Per-cell surface fuel moisture |
| `*_ignition.geojson` | Used | Ignition cell location |
| `*_Synoptic_Weather_Data.csv` | Used | Hourly wind and humidity driving Rate of Spread (ROS) |
| `*_generated_buildings_fireprops.geojson` | Used | Post-processing building exposure analysis only |

---

## Outputs

| File | Format | CRS | Description |
| :--- | :--- | :--- | :--- |
| `burn_extent.tif` | GeoTIFF | EPSG:5070 | Binary burn raster (1 = burned, 0 = unburned) |
| `fire_arrival_time.tif` | GeoTIFF | EPSG:5070 | Per-cell fire arrival timestep (1–12); nodata = unburned |
| `fire_perimeter.geojson` | GeoJSON | EPSG:4326 | Vectorised outer boundary of burned area |
| `building_exposure.geojson` | GeoJSON | EPSG:4326 | All buildings with exposed field (1 = within perimeter) |

> All four outputs are also available as hosted feature layers in ArcGIS Online.

---

## Model Specifications

* **Simulator:** Cell2Fire W
* **Fuel model:** Scott & Burgan 40-class (`--sim S`)
* **CRS:** EPSG:5070 (CONUS Albers Equal Area)
* **Grid resolution:** ~27m
* **Mode:** Deterministic (`nsims=1`) -> scalable to probabilistic (`nsims=100+`)
* **Compiled on:** Ubuntu 24.04 (Noble), g++, libboost, libtiff

---

## Contact

* **Exercise questions:** FireRisk@ul.org
* **Wildfire Commons:** info@wildfirecommons.org
```