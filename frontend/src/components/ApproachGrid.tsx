import React from 'react';
import { RoadName, ApproachStats } from '../types/traffic';
import { ALL_ROADS } from '../services/trafficAdapter';
import { ApproachCard } from './ApproachCard';

interface ApproachGridProps {
  approaches: Record<RoadName, ApproachStats>;
}

export const ApproachGrid: React.FC<ApproachGridProps> = ({ approaches }) => {
  return (
    <div className="card traffic-info-card" role="region" aria-label="Traffic Information by Approach">
      <div className="card-header">
        <h3 className="card-title">Traffic Information</h3>
        <span className="card-subtitle-tag">4 APPROACHES</span>
      </div>

      <div className="approach-grid-layout">
        {ALL_ROADS.map(road => {
          const stats = approaches[road];
          if (!stats) return null;
          return <ApproachCard key={road} stats={stats} />;
        })}
      </div>
    </div>
  );
};
