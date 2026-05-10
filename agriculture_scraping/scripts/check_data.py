"""
Vérifier les données collectées
"""

import pandas as pd
import os

def check_collected_data():
    """
    Vérifier toutes les données collectées
    """
    data_folder = "data/raw"
    
    files = {
        'Climat (journalier)': 'climate_data_openmeteo.csv',
        'Climat (annuel)': 'climate_data_yearly.csv',
        'FAOSTAT': 'faostat_data.csv',
        'Sol': 'soil_data.csv'
    }
    
    print("=" * 60)
    print("📊 VÉRIFICATION DES DONNÉES COLLECTÉES")
    print("=" * 60)
    
    for name, filename in files.items():
        filepath = os.path.join(data_folder, filename)
        
        print(f"\n{'─' * 60}")
        print(f"📁 {name} : {filename}")
        print(f"{'─' * 60}")
        
        if os.path.exists(filepath):
            df = pd.read_csv(filepath)
            print(f"✅ Fichier trouvé")
            print(f"   • Lignes : {len(df)}")
            print(f"   • Colonnes : {len(df.columns)}")
            print(f"   • Colonnes : {', '.join(df.columns.tolist())}")
            print(f"\n   Aperçu :")
            print(df.head(3).to_string())
        else:
            print(f"❌ Fichier non trouvé")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    check_collected_data()
    