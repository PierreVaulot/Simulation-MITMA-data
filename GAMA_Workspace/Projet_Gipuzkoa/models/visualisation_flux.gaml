model GipuzkoaRegionalTraffic

global {
    // --- 1. DATA SOURCES ---
    file shape_districts <- file("../includes/gipuzkoa_distritos.shp");
    file shape_roads <- file("../includes/road_gipuzkoa/road_gipuzkoa.shp"); 
    file csv_traffic_flows <- csv_file("../includes/flux_gipuzkoa_final.csv", ",");
    file csv_points <- csv_file("../includes/points_region_prets.csv", true);
    file filter_admin <- file("../includes/KATASTROA_CATASTRO/GUNEAK_ZONAS/GUNEAK_ZONAS.shp");
    file filter_urban <- file("../includes/KATASTROA_CATASTRO/HIRILUR_URBANO/HIRILUR_URBANO.shp");
    file filter_rural <- file("../includes/KATASTROA_CATASTRO/LANDALUR_RUSTICA/LANDALUR_RUSTICA.shp");

    geometry shape <- envelope(shape_districts);
    graph road_network;

    // --- 2. CONFIGURATION PARAMETERS ---
    float display_percentage <- 4.0; 
    
    bool show_admin_layer <- false;
    bool show_urban_layer <- false;
    bool show_rural_layer <- false;

    init {
        // --- 3. TEMPORAL SETUP ---
        starting_date <- date("2025-02-14 08:00:00");
        step <- 5 #s; 
        
        // --- 4. SPATIAL INITIALIZATION ---
        write ">>> Initializing spatial environment...";
        create district from: shape_districts with: [zone_id::string(read("ID"))]; 
        
        // Initialisation des couches de filtres
        create admin_zone from: filter_admin;
        create urban_zone from: filter_urban;
        create rural_zone from: filter_rural;
        
        map<string, district> district_index <- district as_map (each.zone_id::each);

        write ">>> Building regional road network...";
        create road from: shape_roads;
        road_network <- as_edge_graph(road);

        write ">>> Loading Points of Interest...";
        matrix data_pts <- matrix(csv_points);
        loop i from: 0 to: data_pts.rows - 1 {
            create point_of_interest {
                location <- {float(data_pts[0, i]), float(data_pts[1, i])};
            }
        }

        // --- 5. TRAFFIC DATA INGESTION ---
        matrix flow_data <- matrix(csv_traffic_flows);
        int total_records <- flow_data.rows - 1;
        
        loop i from: 1 to: total_records {
            if (int(flow_data[1, i]) = 8) {
                string origin_id <- string(flow_data[2, i]);       
                string dest_id <- string(flow_data[3, i]);      
                int passenger_count <- int(float(flow_data[13, i])); 

                if (origin_id in district_index.keys and dest_id in district_index.keys) {
                    if (passenger_count > 0) {
                        create trip_scheduler {
                            total_passengers <- passenger_count;
                            int departure_delay <- rnd(3600);
                            depart_at <- starting_date + departure_delay; 
                            origin_zone <- district_index[origin_id];
                            dest_zone <- district_index[dest_id];
                        }
                    }
                }
            }
        }
        write ">>> System Ready.";
    }

    reflex telemetry_logger when: current_date.second = 0 {
        write "[Sim Time: " + string(current_date.hour) + ":" + string(current_date.minute) + "] | [Active Vehicles: " + length(commuter) + "]";
    }
}

// --- SPECIES DEFINITIONS ---

species admin_zone {
    aspect default {
        draw shape color: rgb(100, 100, 255, 60) border: #blue;
    }
}

species urban_zone {
    aspect default {
        draw shape color: rgb(255, 100, 100, 80) border: #red;
    }
}

species rural_zone {
    aspect default {
        draw shape color: rgb(100, 255, 100, 80) border: #green;
    }
}

species trip_scheduler {
    int total_passengers;
    date depart_at;
    district origin_zone;
    district dest_zone;

    reflex dispatch_vehicles when: current_date >= depart_at {
        int vehicles_to_spawn <- round(total_passengers * (display_percentage / 100.0));
        if (vehicles_to_spawn > 0) {
            create commuter number: vehicles_to_spawn {
                location <- any_location_in(myself.origin_zone);
                target <- any_location_in(myself.dest_zone);
            }
        }
        do die; 
    }
}

species district {
    string zone_id;
    aspect default { draw shape color: rgb(240, 240, 240) border: #silver; }
}

species point_of_interest {
    aspect default { draw circle(600) color: rgb(30, 144, 255, 40); }
}

species road {
    aspect default { draw shape color: rgb(110, 110, 110) width: 1.0; }
}

species commuter skills: [moving] {
    point target;
    reflex move {
        do goto target: target speed: 80 #km/#h on: road_network;
        if (location distance_to target < 50 #m) { do die; }
    }
    aspect default {
        draw circle(300) color: rgb(255, 0, 0, 40); 
        draw triangle(400) color: #red border: #white width: 2 rotate: heading + 90;
    }
}

// --- EXPERIMENT / GUI ---

experiment RegionalTrafficAnalysis type: gui {
    
    parameter "Flow Display Percentage (%)" var: display_percentage min: 0.1 max: 100.0 step: 0.5 category: "Traffic Settings";
    parameter "Filter : Admin Zones" var: show_admin_layer category: "Map Filters";
    parameter "Filter : Urban Zones" var: show_urban_layer category: "Map Filters";
    parameter "Filter : Rural Zones" var: show_rural_layer category: "Map Filters";

    output {
        display "Regional Map" type: java2D background: #white {
            species district aspect: default;
            
            species admin_zone aspect: default visible: show_admin_layer;
            species urban_zone aspect: default visible: show_urban_layer;
            species rural_zone aspect: default visible: show_rural_layer;
            
            species point_of_interest aspect: default;
            species road aspect: default;
            species commuter aspect: default;
        }
    }
}