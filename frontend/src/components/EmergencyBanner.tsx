import React from 'react';
import { Tooltip } from './Tooltip';

interface EmergencyBannerProps {
  emergencyActive: boolean;
  emergencyRoad: string | null;
  emergencyClass: string | null;
  isDemoMode: boolean;
}

export const EmergencyBanner: React.FC<EmergencyBannerProps> = ({
  emergencyActive,
  emergencyRoad,
  emergencyClass,
  isDemoMode
}) => {
  if (emergencyActive) {
    return (
      <div className="emergency-banner-alert" role="alert" aria-live="assertive">
        <div className="emergency-pulse-indicator" aria-hidden="true">
          <span className="emergency-siren-dot"></span>
        </div>
        <div className="emergency-content">
          <div className="emergency-header-row">
            <span className="emergency-badge">EMERGENCY PREEMPTION ACTIVE</span>
            {isDemoMode && <span className="demo-sim-tag">[Simulated Action]</span>}
          </div>
          <p className="emergency-detail-msg">
            High-priority vehicle detected: <strong>{emergencyClass?.toUpperCase() || 'EMERGENCY VEHICLE'}</strong> approaching on{' '}
            <strong>{emergencyRoad?.toUpperCase() || 'ACTIVE'} CORRIDOR</strong>. Standard signal timing suspended; continuous GREEN granted to clear intersection.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="emergency-banner-calm" role="status">
      <div className="calm-status-wrap">
        <span className="calm-shield-icon" aria-hidden="true">🛡</span>
        <div className="calm-text-group">
          <span className="calm-title">No Emergency Detected</span>
          <span className="calm-desc">
            Standard adaptive density cycle running.
            <Tooltip content="Note: Baseline YOLOv8 weights (car, motorcycle, bus, truck) lack custom emergency classes. Emergency priority is triggered via specialized fine-tuned models or external priority broadcasts.">
              <span className="info-icon" aria-label="Detection disclaimer">ℹ</span>
            </Tooltip>
          </span>
        </div>
      </div>
      <span className="calm-badge">NORMAL CYCLING</span>
    </div>
  );
};
