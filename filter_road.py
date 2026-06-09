import geopandas as gpd

def filtrer_routes_voitures(input_shapefile, output_shapefile):
    print(f"Charge files : {input_shapefile}...")
    
    # 1. Charger le shapefile dans un GeoDataFrame
    try:
        gdf = gpd.read_file(input_shapefile)
    except Exception as e:
        print(f"Error : {e}")
        return

    print(f"Number of road in beginning : {len(gdf)}")

    voies_a_exclure = [
        'footway',     # Chemins piétons
        'pedestrian',  # Zones piétonnes
        'cycleway',    # Pistes cyclables
        'steps',       # Escaliers
        'path',        # Petits sentiers
        'track',       # Chemins de terre/forestiers
        'bridleway',   # Chemins équestres
        'service'      # Voies de service (souvent privées ou très lentes)
    ]

    print("Filter")
    gdf_voitures = gdf[~gdf['fclass'].isin(voies_a_exclure)]

    print(f"Number road : {len(gdf_voitures)}")
    print(f"Road delete : {len(gdf) - len(gdf_voitures)}")

    print(f"Save: {output_shapefile}...")
    gdf_voitures.to_file(output_shapefile)
    
    print("Finish")

if __name__ == "__main__":
    fichier_entree = r"C:\Users\pierr\Desktop\Projet1_Gipuzkoa\pais-vasco-260608-free\gis_osm_roads_free_1.shp"
    fichier_sortie = r"C:\Users\pierr\Desktop\Projet1_Gipuzkoa\road_pais_vasco_clean\road_pais_vasco_clean.shp"
    
    filtrer_routes_voitures(fichier_entree, fichier_sortie)