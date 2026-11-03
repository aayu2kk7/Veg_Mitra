import React from 'react';
import { SystemKpis } from '../types/traffic';
import { Tooltip } from './Tooltip';

interface KpiSectionProps {
  kpis: SystemKpis;
  frameIndex: number | null;
}

export const KpiSection: React.FC<KpiSectionProps> = ({ kpis, frameIndex }) => {
  const {
    totalVehicles,
    totalVehiclesAvailable,
    averageCongestionPct,
    congestionLevel,
    averageWaitTimeSec,
    waitTimeIsEstimated,
    estimatedFuelSavedLiters,
    fuelIsEstimated
  } = kpis;

  return (
    <section className="card kpi-section-card" role="region" aria-label="Key Performance Indicators">
      <div className="card-header">
        <h3 className="card-title">Key Performance Indicators (KPIs)</h3>
        <span className="card-subtitle-tag">SYSTEM TELEMETRY</span>
      </div>

      <div className="kpi-grid">
        {/* KPI 1: [ TIME ] Avg Waiting Time */}
        <div className="kpi-card" role="article" aria-label="Average waiting time">
          <div className="kpi-header">
            <span className="kpi-bracket">[ TIME ]</span>
            <span className="kpi-name">Avg Waiting Time</span>
            <Tooltip content="Estimated queue delay based on Webster's delay equation for adaptive vs fixed signal splits. Backend YOLO detection records approach counts rather than individual vehicle wait timers.">
              <span className="info-icon" aria-label="Metric details">ℹ</span>
            </Tooltip>
          </div>
          <div className="kpi-value-row">
            <span className="kpi-number accent-cyan mono">
              {averageWaitTimeSec !== null ? `${averageWaitTimeSec.toFixed(1)} s` : 'Not available'}
            </span>
          </div>
          <div className="kpi-subtext">
            {waitTimeIsEstimated ? '*Estimated from queue delay model' : 'Directly Measured'}
          </div>
        </div>

        {/* KPI 2: [ FLOW ] Vehicles Processed */}
        <div className="kpi-card" role="article" aria-label="Vehicles processed">
          <div className="kpi-header">
            <span className="kpi-bracket">[ FLOW ]</span>
            <span className="kpi-name">Vehicles Detected</span>
            <Tooltip content="Instantaneous incoming vehicle tracks across all four approaches derived directly from YOLO detection & BoTSORT tracking.">
              <span className="info-icon" aria-label="Metric details">ℹ</span>
            </Tooltip>
          </div>
          <div className="kpi-value-row">
            <span className="kpi-number accent-mint mono">
              {totalVehiclesAvailable ? totalVehicles : '—'}
            </span>
            <span className="kpi-unit">veh</span>
          </div>
          <div className="kpi-subtext">
            {frameIndex !== null ? `Live Frame #${frameIndex}` : 'Source: Backend State'}
          </div>
        </div>

        {/* KPI 3: [ LOAD ] Congestion Level */}
        <div className="kpi-card" role="article" aria-label="Congestion Level">
          <div className="kpi-header">
            <span className="kpi-bracket">[ LOAD ]</span>
            <span className="kpi-name">Congestion Level</span>
            <Tooltip content="Mean traffic density across all 4 approaches relative to 30 vehicle/approach capacity.">
              <span className="info-icon" aria-label="Metric details">ℹ</span>
            </Tooltip>
          </div>
          <div className="kpi-value-row">
            <span className={`kpi-number density-text-${congestionLevel.toLowerCase()} mono`}>
              {congestionLevel} ({averageCongestionPct.toFixed(0)}%)
            </span>
          </div>
          <div className="kpi-subtext">
            System Mean Density: {averageCongestionPct.toFixed(1)}%
          </div>
        </div>

        {/* KPI 4: [ ECO ] Fuel / Emission Savings */}
        <div className="kpi-card" role="article" aria-label="Estimated fuel savings">
          <div className="kpi-header">
            <span className="kpi-bracket">[ ECO ]</span>
            <span className="kpi-name">Estimated Fuel Saved</span>
            <Tooltip content="Theoretical fuel savings model: estimates 15-20% idling reduction compared to an uncoordinated 60s fixed-time controller (assumes 0.8 L/hr idle consumption).">
              <span className="info-icon" aria-label="Metric details">ℹ</span>
            </Tooltip>
          </div>
          <div className="kpi-value-row">
            <span className="kpi-number accent-mint mono">
              {estimatedFuelSavedLiters !== null ? `${estimatedFuelSavedLiters.toFixed(2)} L` : '—'}
            </span>
          </div>
          <div className="kpi-subtext">
            {fuelIsEstimated ? '*Estimated reduction vs fixed-time cycle' : 'Verified Savings'}
          </div>
        </div>
      </div>
    </section>
  );
};
