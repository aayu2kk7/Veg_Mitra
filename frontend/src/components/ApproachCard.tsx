import React from 'react';
import { ApproachStats } from '../types/traffic';
import { Tooltip } from './Tooltip';

interface ApproachCardProps {
  stats: ApproachStats;
}

export const ApproachCard: React.FC<ApproachCardProps> = ({ stats }) => {
  const {
    road,
    directionLabel,
    icon,
    count,
    smoothedCount,
    densityPct,
    densityLevel,
    isGreen,
    signalAspect
  } = stats;

  const getAspectBadge = () => {
    switch (signalAspect) {
      case 'GREEN':
        return { label: 'GREEN (GO)', className: 'aspect-pill-green' };
      case 'AMBER':
        return { label: 'AMBER', className: 'aspect-pill-amber' };
      case 'RED':
      default:
        return { label: 'RED (STOP)', className: 'aspect-pill-red' };
    }
  };

  const aspect = getAspectBadge();

  return (
    <div 
      className={`approach-card ${isGreen ? 'approach-card-active' : ''}`}
      role="article"
      aria-label={`${road} corridor traffic statistics`}
    >
      <div className="approach-card-header">
        <div className="road-title-wrap">
          <span className="road-dir-icon" aria-hidden="true">{icon}</span>
          <span className="road-name">{road}</span>
        </div>
        <span className={`signal-aspect-pill ${aspect.className}`}>
          {aspect.label}
        </span>
      </div>

      <div className="approach-metric-body">
        {/* Main Big Number: Live Vehicle Count */}
        <div className="count-display-group">
          <div className="count-primary">
            <span className="count-num mono">{count}</span>
            <span className="count-unit">veh</span>
          </div>

          <div className="count-smoothed-row">
            <span className="smoothed-label">Smoothed:</span>
            <span className="smoothed-val mono">{smoothedCount.toFixed(1)}</span>
            <Tooltip content="10-frame rolling average of incoming vehicle tracks, preventing noise from temporary occlusions.">
              <span className="info-icon" aria-label="Info">ℹ</span>
            </Tooltip>
          </div>
        </div>

        {/* Density Gauge / Bar */}
        <div className="density-section">
          <div className="density-header-row">
            <span className="density-title">
              Density:
              <Tooltip content="Calculated as (smoothed_counts / 30 vehicle road capacity) * 100%.">
                <span className="info-icon" aria-label="Info">ℹ</span>
              </Tooltip>
            </span>
            <span className={`density-val-text density-text-${densityLevel.toLowerCase()} mono`}>
              {densityPct.toFixed(1)}% ({densityLevel})
            </span>
          </div>

          <div 
            className="density-progress-track"
            role="progressbar"
            aria-valuenow={densityPct}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label={`${road} road traffic density ${densityPct}%`}
          >
            <div 
              className={`density-progress-fill fill-${densityLevel.toLowerCase()}`}
              style={{ width: `${Math.min(100, Math.max(4, densityPct))}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
