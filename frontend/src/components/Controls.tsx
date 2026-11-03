import React from 'react';
import { ConnectionMode } from '../types/traffic';
import { DEMO_SCENARIOS } from '../services/mockDataService';
import { Tooltip } from './Tooltip';

interface ControlsProps {
  mode: ConnectionMode;
  isPolling: boolean;
  isDemoMode: boolean;
  selectedScenarioId?: string;
  pollingIntervalMs: number;
  emergencyActive: boolean;
  onTogglePolling: () => void;
  onReset: () => void;
  onToggleDemoMode: (enableDemo: boolean) => void;
  onSelectScenario: (scenarioId: string) => void;
  onToggleEmergencySimulation: () => void;
  onChangePollingInterval: (intervalMs: number) => void;
}

export const Controls: React.FC<ControlsProps> = ({
  mode,
  isPolling,
  isDemoMode,
  selectedScenarioId,
  pollingIntervalMs,
  emergencyActive,
  onTogglePolling,
  onReset,
  onToggleDemoMode,
  onSelectScenario,
  onToggleEmergencySimulation,
  onChangePollingInterval
}) => {
  return (
    <div className="card control-section-card" role="region" aria-label="Control Section">
      <div className="card-header">
        <h3 className="card-title">Control Section</h3>
        <span className="card-subtitle-tag">SIMULATION DASHBOARD</span>
      </div>

      {/* Mode Toggle Bar: Live Backend vs Interactive Demo */}
      <div className="source-toggle-group">
        <span className="source-label">Data Source:</span>
        <div className="segmented-control" role="tablist">
          <button
            type="button"
            role="tab"
            aria-selected={!isDemoMode}
            className={`segment-btn ${!isDemoMode ? 'segment-active' : ''}`}
            onClick={() => onToggleDemoMode(false)}
          >
            📡 Live Backend JSON
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={isDemoMode}
            className={`segment-btn ${isDemoMode ? 'segment-active' : ''}`}
            onClick={() => onToggleDemoMode(true)}
          >
            🧪 Interactive Demo Mode
          </button>
        </div>
      </div>

      {/* Primary Action Buttons (matching final_screenshot.png layout) */}
      <div className="control-button-grid">
        <button
          type="button"
          className={`btn-action ${isPolling ? 'btn-stop' : 'btn-start'}`}
          onClick={onTogglePolling}
          aria-label={isPolling ? 'Pause dashboard telemetry' : 'Start dashboard telemetry'}
        >
          {isPolling ? 'Stop Simulation' : 'Start Simulation'}
        </button>

        <button
          type="button"
          className="btn-action btn-reset"
          onClick={onReset}
          aria-label="Reset simulation to initial state"
        >
          Reset
        </button>

        <button
          type="button"
          className={`btn-action ${emergencyActive ? 'btn-emergency-active' : 'btn-emergency'}`}
          onClick={onToggleEmergencySimulation}
          disabled={!isDemoMode}
          title={!isDemoMode ? 'Emergency simulation is available in Demo Mode. Live backend triggers depend on detection payload.' : 'Toggle simulated ambulance emergency vehicle'}
          aria-label="Toggle simulated emergency preemption in demo mode"
        >
          {emergencyActive ? 'Deactivate Emergency' : 'Emergency Mode (Demo)'}
        </button>
      </div>

      {/* Demo Scenario Selector (visible in Demo Mode) */}
      {isDemoMode && (
        <div className="demo-scenarios-panel">
          <label htmlFor="scenario-select" className="scenario-label">
            Demo Traffic Scenario:
          </label>
          <select
            id="scenario-select"
            className="scenario-dropdown"
            value={selectedScenarioId || DEMO_SCENARIOS[0].id}
            onChange={(e) => onSelectScenario(e.target.value)}
          >
            {DEMO_SCENARIOS.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Telemetry Polling Speed Slider */}
      <div className="polling-interval-row">
        <div className="polling-label-group">
          <span className="control-helper-title">Refresh Interval:</span>
          <span className="polling-val-text mono">{pollingIntervalMs}ms</span>
        </div>
        <div className="interval-pills">
          {[500, 1000, 2000].map(val => (
            <button
              key={val}
              type="button"
              className={`interval-pill ${pollingIntervalMs === val ? 'interval-pill-active' : ''}`}
              onClick={() => onChangePollingInterval(val)}
            >
              {val / 1000}s
            </button>
          ))}
        </div>
      </div>

      {/* Explicit Backend Connection Notice */}
      <div className="control-disclaimer-note">
        <span className="notice-icon">ℹ</span>
        <span className="notice-text">
          <strong>Note:</strong> Start/Stop controls UI telemetry polling. To run the live vision pipeline, execute <code className="code-snippet">.\.venv\Scripts\python.exe main.py</code> in the terminal.
        </span>
      </div>

      <div className="control-tagline">
        &ldquo;Autonomous AI Signals for Greener, Flowing Cities&rdquo;
      </div>
    </div>
  );
};
