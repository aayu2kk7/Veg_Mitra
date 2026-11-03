import os
import random
import numpy as np
import pandas as pd

def generate_traffic_features_dataset(output_csv='traffic_ml/traffic_features.csv', n_samples=600, seed=42):
    random.seed(seed)
    np.random.seed(seed)

    records = []
    
    # Simulate diverse intersection traffic observation periods (e.g. 1-minute window stats)
    for i in range(n_samples):
        # Time of day: 0=Night (0-6), 1=Morning Rush (7-10), 2=Midday (11-15), 3=Evening Rush (16-20), 4=Late Night (21-23)
        time_slot = random.choices([0, 1, 2, 3, 4], weights=[0.1, 0.3, 0.2, 0.3, 0.1])[0]
        
        # In rush hours, base vehicle presence is higher
        if time_slot in [1, 3]:
            base_cars = np.random.randint(15, 45)
            base_motorcycles = np.random.randint(5, 25)
            base_buses = np.random.randint(2, 8)
            base_trucks = np.random.randint(1, 6)
            avg_speed_kmh = np.random.uniform(10.0, 28.0)  # Slow in rush hour
        elif time_slot == 2:
            base_cars = np.random.randint(8, 22)
            base_motorcycles = np.random.randint(3, 12)
            base_buses = np.random.randint(1, 4)
            base_trucks = np.random.randint(2, 8)
            avg_speed_kmh = np.random.uniform(25.0, 45.0)
        else: # Night / Off-peak
            base_cars = np.random.randint(1, 10)
            base_motorcycles = np.random.randint(0, 5)
            base_buses = np.random.randint(0, 2)
            base_trucks = np.random.randint(0, 4)
            avg_speed_kmh = np.random.uniform(40.0, 65.0)

        total_vehicles = base_cars + base_motorcycles + base_buses + base_trucks
        
        # Lane occupancy percentage based on physical road capacity (max capacity ~ 60)
        lane_occupancy_pct = min(100.0, (total_vehicles / 60.0) * 100.0 + np.random.normal(0, 2))
        lane_occupancy_pct = max(0.0, round(lane_occupancy_pct, 1))

        # Traffic density index
        traffic_density = min(100.0, round((total_vehicles / 55.0) * 100.0, 1))

        # Determine true traffic congestion level ground truth:
        # LOW (< 30% density), MEDIUM (30% - 65% density), HIGH (> 65% density)
        if traffic_density < 30.0:
            traffic_level = 'LOW'
        elif traffic_density <= 65.0:
            traffic_level = 'MEDIUM'
        else:
            traffic_level = 'HIGH'

        records.append({
            'car_count': base_cars,
            'motorcycle_count': base_motorcycles,
            'bus_count': base_buses,
            'truck_count': base_trucks,
            'total_vehicles': total_vehicles,
            'avg_speed_kmh': round(avg_speed_kmh, 1),
            'lane_occupancy_pct': lane_occupancy_pct,
            'time_slot': time_slot,
            'traffic_density': traffic_density,
            'traffic_level': traffic_level
        })

    df = pd.DataFrame(records)
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    df.to_csv(output_csv, index=False)
    print(f'[Tabular ML] Generated dataset with {len(df)} samples saved to: {output_csv}')
    print('[Tabular ML] Class distribution:')
    print(df['traffic_level'].value_counts())
    return df

if __name__ == '__main__':
    generate_traffic_features_dataset()
