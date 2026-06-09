# Gipuzkoa Mobility: From Big Data to Multi-Agent Simulation

This repository contains a Data Engineering and Spatial Analysis pipeline designed to process massive mobility datasets from the Spanish Ministry of Transport (MITMA). The goal is to transform heavy, raw Origin-Destination (OD) matrices into actionable formats for interactive 3D visualizations (Kepler.gl / deck.gl) and Agent-Based Modeling (GAMA Platform).

The project focuses on the Gipuzkoa province (Basque Country), specifically analyzing rush-hour commuting and dynamic population flows.

## Repository Structure & File Descriptions

### 1. Python Processing Scripts (ETL & GIS)

* **`1_preparation_flux_kepler.py`**
    * *Purpose:* Processes the massive raw mobility CSV in chunks to prevent RAM overload.
    * *Action:* Maps origin/destination IDs to WGS84 GPS coordinates, aggregates trips, and formats time periods (e.g., converting '8' to '08:00:00') so Kepler.gl can read it as an animated timeline.
* **`2_moteur_simulation_unifie.py`**
    * *Purpose:* The core simulation engine preparing data for both visualization and GAMA.
    * *Action:* Handles complex CRS reprojections (EPSG:4326 GPS to EPSG:25830 UTM), applies spatial nudges to align POIs with shapefile bounding boxes, and generates individual trip events with randomized departure times (JSON output).
* **`3_transformation_reseau_routier.py`**
    * *Purpose:* Prepares the physical road network for the GAMA simulation platform.
    * *Action:* Applies spatial translations and Y-axis scaling to shift the geographical coordinates into a localized cartesian grid (setting the top-left corner to 0,0), which is mandatory for most multi-agent rendering engines.
* **`4_suivi_population_dynamique.py`**
    * *Purpose:* Calculates real-time population density.
    * *Action:* Ingests base census data and creates a chronological ledger of departures (-) and arrivals (+). It outputs a 10-minute interval dataset showing the exact population balance for every district throughout the day.

### 2. Configuration & Version Control

* **`.gitignore`**
    * Ensures that massive data files (`.csv`, `.shp`, `.tar`) are excluded from version control to prevent repository bloat and Git timeout errors.

### 3. Generated Outputs (Locally)

*Note: Due to GitHub file size limits, the following generated files and raw inputs are not pushed to this repository.*

* `sim_trips_final.json`: The GeoJSON LineString dataset used to render animated "comet" trails in Kepler.gl/deck.gl.
* `population_dynamique_reelle.csv`: The temporal ledger used to animate district population changes.
* `roads_gipuzkoa_complet.shp`: The transformed road network graph ingested by the GAMA Platform.

## How to Run Python Scripts Locally

1.  Clone this repository.
2.  Create an `includes/` and `road_gipuzkoa/` folder at the root.
3.  Place your MITMA open data CSVs and official Shapefiles in these folders.
4.  Install dependencies: `pip install pandas geopandas shapely pyproj`
5.  Execute the scripts in numerical order.
6.  Import the resulting `.json` and `.csv` files into [Kepler.gl](https://kepler.gl/demo) to view the spatiotemporal animations.

## How to Run the GAMA Simulation (GUI Mode)

To run the agent-based simulation with full visual rendering on your local machine:

1. Open the **GAMA Platform** desktop application (version 2025.06 recommended).
2. Import this repository folder into your GAMA Workspace.
3. Navigate to the `models/` directory and open `visualisation_flux.gaml`.
4. Click the **Run** button (green play icon in the top toolbar) to instantiate the `RegionalTrafficAnalysis` experiment.
5. In the simulation parameters panel under *Traffic Settings*, adjust the **Flow Display Percentage (%)** slider (recommended values: `0.5%` to `5.0%` to optimize rendering performance on local hardware).
6. Click the **Play** button in the simulation control interface to start the visual execution.

## Tech Stack
* **Data Processing:** Python 3, Pandas (Chunking/Aggregations)
* **Geospatial Analysis:** GeoPandas, Shapely, PyProj (UTM/WGS84)
* **Visualization & Simulation:** Kepler.gl (deck.gl architecture), GAMA Platform (GAML)
