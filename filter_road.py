import geopandas as gpd

def filtrer_et_couper_routes(input_roads, input_districts, output_shapefile):
    print(f"Chargement des routes OSM : {input_roads}...")
    try:
        gdf_roads = gpd.read_file(input_roads)
    except Exception as e:
        print(f"Erreur de chargement des routes : {e}")
        return

    print(f"Chargement des frontières (Districts) : {input_districts}...")
    try:
        gdf_districts = gpd.read_file(input_districts)
    except Exception as e:
        print(f"Erreur de chargement des districts : {e}")
        return

    # 1. ALIGNEMENT DES SYSTÈMES DE COORDONNÉES (CRUCIAL)
    print("Vérification des systèmes de projection (CRS)...")
    if gdf_roads.crs != gdf_districts.crs:
        print(f"Alignement des CRS : Conversion des routes vers {gdf_districts.crs}...")
        gdf_roads = gdf_roads.to_crs(gdf_districts.crs)

    # 2. FILTRAGE DES TYPES DE VOIES
    print("Filtrage des voies piétonnes/cyclables...")
    voies_a_exclure = [
        'footway', 'pedestrian', 'cycleway', 'steps', 
        'path', 'track', 'bridleway', 'service'
    ]
    gdf_voitures = gdf_roads[~gdf_roads['fclass'].isin(voies_a_exclure)]
    print(f"Routes automobiles conservées avant découpage : {len(gdf_voitures)}")

    # 3. DÉCOUPAGE SPATIAL (CLIPPING)
    print("Découpage (clipping) des routes avec l'emporte-pièce de Gipuzkoa... (Cela peut prendre 1 à 2 minutes)")
    gdf_gipuzkoa_roads = gpd.clip(gdf_voitures, gdf_districts)
    print(f"Routes restantes après découpage : {len(gdf_gipuzkoa_roads)}")

    # 4. SAUVEGARDE
    print(f"Sauvegarde en cours vers : {output_shapefile}...")
    gdf_gipuzkoa_roads.to_file(output_shapefile)
    
    print("Terminé avec succès ! 🎉 Le fichier est parfait pour GAMA.")

if __name__ == "__main__":
    fichier_routes_osm = r"C:\Users\pierr\Desktop\Projet1_Gipuzkoa\pais-vasco-260608-free\gis_osm_roads_free_1.shp"
    
    fichier_districts = r"C:\Users\pierr\Desktop\Projet1_Gipuzkoa\includes\gipuzkoa_distritos.shp" 
    
    fichier_sortie = r"C:\Users\pierr\Desktop\Projet1_Gipuzkoa\road_pais_vasco_clean\road_pais_vasco_clean.shp"
    
    filtrer_et_couper_routes(fichier_routes_osm, fichier_districts, fichier_sortie)