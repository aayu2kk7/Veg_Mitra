import React from 'react';
import { RoadName, ApproachStats } from '../types/traffic';
import { Tooltip } from './Tooltip';

interface SignalStatusCardProps {
  selectedGreenRoad: RoadName | null;
  greenHoldRemaining: number;
  decisionExplanation: string;
  decisionIsEstimated: boolean;
  activeApproachStats?: ApproachStats;
  emergencyActive: boolean;
  emergencyRoad: string | null;
}

export const SignalStatusCard: React.FC<SignalStatusCardProps> = ({
  selectedGreenRoad,
  greenHoldRemaining,
  decisionExplanation,
  decisionIsEstimated,
  activeApproachStats,
  emergencyActive,
  emergencyRoad
}) => {
  const getRoadDisplayName = () => {
    if (emergencyActive && emergencyRoad) {
      return `${emergencyRoad.toUpperCase()} (EMERGENCY)`;
    }
    if (selectedGreenRoad) {
      return `${selectedGreenRoad.toUpperCase()} CORRIDOR`;
    }
    return 'STANDBY / ROTATING';
  };

  const getSystemStatus = () => {
    if (emergencyActive) return 'PREEMPTION ACTIVE';
    if (greenHoldRemaining > 0) return 'HOLDING MINIMUM GREEN';
    return 'EVALUATING DENSITY';
  };

  return (
    <div className="card signal-status-card" role="region" aria-label="Current Traffic Signal Status">
      <div className="card-header">
        <h3 className="card-title">Current Signal Status</h3>
        <span className="card-badge-pill">ACTIVE PHASE</span>
      </div>

      <div className="signal-status-grid">
        {/* Selected Green Road Box */}
        <div className={`status-display-box green-road-box ${emergencyActive ? 'box-emergency' : ''}`}>
          <div className="box-meta-label">
            <span>CURRENT GREEN ROAD</span>
            {emergencyActive && <span className="priority-tag">OVERRIDE</span>}
          </div>
          <div className="box-main-value accent-mint">
            {activeApproachStats && <span className="road-arrow-icon">{activeApproachStats.icon}</span>}
            <span className="road-name-text">{getRoadDisplayName()}</span>
          </div>
        </div>

        {/* Time Remaining Countdown Box */}
        <div className="status-display-box timer-box">
          <div className="box-meta-label">
            <span>HOLD REMAINING</span>
            <Tooltip content="Enforced minimum green duration preventing rapid signal flickering (hysteresis guarantee)">
              <span className="info-icon" aria-label="Information">ℹ</span>
            </Tooltip>
          </div>
          <div className="box-main-value accent-cyan mono">
            {greenHoldRemaining > 0 ? `${greenHoldRemaining.toFixed(1)}s` : '0.0s'}
          </div>
        </div>
      </div>

      {/* AI Decision Explanation Banner */}
      <div className="ai-decision-panel">
        <div className="decision-header">
          <span className="decision-title">AI DECISION REASON</span>
          {decisionIsEstimated && (
            <Tooltip content="Explanation derived from relative density metrics, 10% hysteresis threshold, and minimum green hold rules.">
              <span className="estimate-badge">[Estimated Basis]*</span>
            </Tooltip>
          )}
        </div>
        <p className="decision-text">{decisionExplanation}</p>
      </div>

      {/* System Telemetry Key-Value Rows */}
      <div className="telemetry-rows">
        <div className="telemetry-row">
          <span className="telemetry-key">Selected Approach Density:</span>
          <span className="telemetry-val">
            {activeApproachStats ? (
              <span className={`density-pill density-${activeApproachStats.densityLevel.toLowerCase()}`}>
                {activeApproachStats.road} {activeApproachStats.densityPct.toFixed(1)}% ({activeApproachStats.densityLevel})
              </span>
            ) : (
              '—'
            )}
          </span>
        </div>

        <div className="telemetry-row">
          <span className="telemetry-key">Controller Logic:</span>
          <span className="telemetry-val highlight-cyan">
            Adaptive YOLO + Hysteresis (2.0%)
          </span>
        </div>

        <div className="telemetry-row">
          <span className="telemetry-key">System Operational State:</span>
          <span className={`telemetry-val ${emergencyActive ? 'highlight-red' : 'highlight-green'}`}>
            {getSystemStatus()}
          </span>
        </div>
      </div>
    </div>
  );
};
