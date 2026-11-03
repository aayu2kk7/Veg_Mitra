import React from 'react';
import { ConnectionMode } from '../types/traffic';
import { Tooltip } from './Tooltip';

interface HeaderProps {
  mode: ConnectionMode;
  lastUpdated: string;
  frameIndex: number | null;
  latencyMs: number;
  isDataSourceDemo: boolean;
  onRefresh?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  mode,
  lastUpdated,
  frameIndex,
  latencyMs,
  isDataSourceDemo,
  onRefresh
}) => {
  const getStatusBadge = () => {
    switch (mode) {
      case 'live':
        return {
          label: 'LIVE BACKEND',
          className: 'badge-live',
          dotClass: 'dot-pulse-green',
          tooltip: 'Receiving live state from Python YOLO detection pipeline (output/traffic_state.json)'
        };
      case 'demo':
        return {
          label: 'DEMO SIMULATION',
          className: 'badge-demo',
          dotClass: 'dot-pulse-blue',
          tooltip: 'Operating in interactive client simulation mode with synthetic scenario data'
        };
      case 'stale':
        return {
          label: 'STALE DATA',
          className: 'badge-stale',
          dotClass: 'dot-warning',
          tooltip: 'Backend file exists but timestamp has not updated recently (> 4s). main.py may be paused or finished.'
        };
      case 'paused':
        return {
          label: 'PAUSED',
          className: 'badge-paused',
          dotClass: 'dot-gray',
          tooltip: 'Dashboard polling is paused'
        };
      case 'disconnected':
      default:
        return {
          label: 'OFFLINE / DISCONNECTED',
          className: 'badge-disconnected',
          dotClass: 'dot-red',
          tooltip: 'Cannot reach backend JSON bridge or server. Check if serve_dashboard.py or main.py is running.'
        };
    }
  };

  const status = getStatusBadge();

  return (
    <header className="dashboard-header" role="banner">
      <div className="header-brand-block">
        <div className="logo-group">
          <div className="brand-logo-icon" aria-hidden="true">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
              <rect x="5" y="2" width="14" height="20" rx="3" fill="#131e33" stroke="#253553" />
              <circle cx="12" cy="7" r="2.2" fill="#ef4444" />
              <circle cx="12" cy="12" r="2.2" fill="#f59e0b" />
              <circle cx="12" cy="17" r="2.2" fill="#10b981" />
            </svg>
          </div>
          <div>
            <h1 className="brand-title">
              Veg<span className="accent-mint">Mitra</span>
            </h1>
            <p className="brand-subtitle">AI-Based Smart Traffic Light Management System</p>
          </div>
        </div>
      </div>

      <div className="header-meta-block">
        <div className="header-tagline-row">
          <span className="system-tagline">Smarter Signals | Greener Cities | Better Tomorrows</span>
        </div>

        <div className="header-status-row">
          <Tooltip content={status.tooltip}>
            <div className={`status-pill ${status.className}`} role="status">
              <span className={`status-dot ${status.dotClass}`} aria-hidden="true" />
              <span className="status-label">{status.label}</span>
            </div>
          </Tooltip>

          <div className="system-health-chip" title="Active Engine Architecture">
            <span className="health-label">ENGINE:</span>
            <span className="health-val">{isDataSourceDemo ? 'Synthetic Demo' : 'YOLOv8 + BoTSORT'}</span>
          </div>

          <div className="system-health-chip" title="Last State Refresh Time">
            <span className="health-label">UPDATED:</span>
            <span className="health-val">{lastUpdated}</span>
          </div>

          {frameIndex !== null && (
            <div className="system-health-chip" title="Video Frame Counter">
              <span className="health-label">FRAME:</span>
              <span className="health-val">#{frameIndex}</span>
            </div>
          )}

          {latencyMs > 0 && (
            <div className="system-health-chip" title="Polling Bridge Latency">
              <span className="health-label">LATENCY:</span>
              <span className="health-val">{latencyMs}ms</span>
            </div>
          )}

          {onRefresh && (
            <button 
              className="refresh-btn"
              onClick={onRefresh}
              title="Force Refresh Data"
              aria-label="Refresh traffic state"
            >
              ↻
            </button>
          )}
        </div>
      </div>
    </header>
  );
};
