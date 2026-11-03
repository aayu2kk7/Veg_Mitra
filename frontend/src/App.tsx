import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  ConnectionMode,
  DashboardViewModel,
  RawTrafficStatePayload
} from './types/traffic';
import { adaptTrafficState } from './services/trafficAdapter';
import { MockTrafficSimulationEngine, DEMO_SCENARIOS } from './services/mockDataService';
import { Header } from './components/Header';
import { IntersectionView } from './components/IntersectionView';
import { SignalStatusCard } from './components/SignalStatusCard';
import { ApproachGrid } from './components/ApproachGrid';
import { Controls } from './components/Controls';
import { EmergencyBanner } from './components/EmergencyBanner';
import { KpiSection } from './components/KpiSection';

export const App: React.FC = () => {
  // State for data source & controls
  const [isDemoMode, setIsDemoMode] = useState<boolean>(false);
  const [isPolling, setIsPolling] = useState<boolean>(true);
  const [pollingIntervalMs, setPollingIntervalMs] = useState<number>(1000);
  const [selectedScenarioId, setSelectedScenarioId] = useState<string>(DEMO_SCENARIOS[0].id);

  // Connection & telemetry health
  const [connectionMode, setConnectionMode] = useState<ConnectionMode>('live');
  const [lastFetchTime, setLastFetchTime] = useState<Date | null>(null);
  const [latencyMs, setLatencyMs] = useState<number>(0);
  const [consecutiveErrors, setConsecutiveErrors] = useState<number>(0);

  // Core view-model initialized with empty/default state
  const [viewModel, setViewModel] = useState<DashboardViewModel>(() => adaptTrafficState({}, false));

  // Simulation engine instance
  const simulationEngineRef = useRef<MockTrafficSimulationEngine>(new MockTrafficSimulationEngine());
  const lastStateTimestampRef = useRef<number | null>(null);
  const staleTimerRef = useRef<number>(0);

  // Endpoints to check for live traffic_state.json
  const STATE_ENDPOINTS = [
    '/api/traffic-state',
    '../output/traffic_state.json',
    '/output/traffic_state.json',
    'output/traffic_state.json'
  ];

  /**
   * Fetches real backend JSON payload from server or local file
   */
  const fetchBackendState = useCallback(async (): Promise<boolean> => {
    const t0 = performance.now();
    let payload: RawTrafficStatePayload | null = null;
    let endpointSuccess = false;

    for (const url of STATE_ENDPOINTS) {
      try {
        const resp = await fetch(url, {
          cache: 'no-store',
          headers: { 'Accept': 'application/json' }
        });
        if (resp.ok) {
          payload = await resp.json();
          endpointSuccess = true;
          break;
        }
      } catch {
        // Try next fallback endpoint
      }
    }

    const t1 = performance.now();
    setLatencyMs(Math.round(t1 - t0));

    if (endpointSuccess && payload) {
      setLastFetchTime(new Date());
      setConsecutiveErrors(0);

      // Check for stale data (timestamp unchanged over multiple cycles)
      if (payload.timestamp && payload.timestamp === lastStateTimestampRef.current) {
        staleTimerRef.current += 1;
        if (staleTimerRef.current >= 4) {
          setConnectionMode('stale');
        } else {
          setConnectionMode('live');
        }
      } else {
        staleTimerRef.current = 0;
        lastStateTimestampRef.current = payload.timestamp || null;
        setConnectionMode('live');
      }

      const adapted = adaptTrafficState(payload, false);
      setViewModel(adapted);
      return true;
    } else {
      setConsecutiveErrors(prev => prev + 1);
      if (consecutiveErrors >= 2) {
        setConnectionMode('disconnected');
      }
      return false;
    }
  }, [consecutiveErrors]);

  /**
   * Runs single tick of demo simulation engine
   */
  const tickDemoSimulation = useCallback(() => {
    const dt = pollingIntervalMs / 1000;
    const rawDemoPayload = simulationEngineRef.current.tick(dt);
    const adapted = adaptTrafficState(rawDemoPayload, true);
    setViewModel(adapted);
    setConnectionMode('demo');
    setLastFetchTime(new Date());
    setLatencyMs(4);
  }, [pollingIntervalMs]);

  /**
   * Polling loop effect
   */
  useEffect(() => {
    if (!isPolling) {
      setConnectionMode('paused');
      return;
    }

    let isMounted = true;

    const runCycle = async () => {
      if (!isMounted) return;

      if (isDemoMode) {
        tickDemoSimulation();
      } else {
        const success = await fetchBackendState();
        // If cannot connect after 3 consecutive tries and never succeeded, offer automatic demo preview
        if (!success && consecutiveErrors > 3 && !lastFetchTime) {
          console.warn('Backend traffic_state.json unreachable. Switching to Demo Preview.');
          setIsDemoMode(true);
        }
      }
    };

    // Run immediately once
    runCycle();

    // Setup interval
    const intervalId = window.setInterval(runCycle, pollingIntervalMs);

    return () => {
      isMounted = false;
      window.clearInterval(intervalId);
    };
  }, [isPolling, isDemoMode, pollingIntervalMs, fetchBackendState, tickDemoSimulation, consecutiveErrors, lastFetchTime]);

  /**
   * Handlers for user controls
   */
  const handleTogglePolling = () => {
    setIsPolling(prev => !prev);
  };

  const handleReset = () => {
    if (isDemoMode) {
      simulationEngineRef.current = new MockTrafficSimulationEngine();
      tickDemoSimulation();
    } else {
      fetchBackendState();
    }
  };

  const handleToggleDemoMode = (enableDemo: boolean) => {
    setIsDemoMode(enableDemo);
    if (enableDemo) {
      simulationEngineRef.current = new MockTrafficSimulationEngine();
      simulationEngineRef.current.setScenario(selectedScenarioId);
      tickDemoSimulation();
    } else {
      setConsecutiveErrors(0);
      fetchBackendState();
    }
  };

  const handleSelectScenario = (scenarioId: string) => {
    setSelectedScenarioId(scenarioId);
    simulationEngineRef.current.setScenario(scenarioId);
    tickDemoSimulation();
  };

  const handleToggleEmergencySimulation = () => {
    if (!isDemoMode) return;
    simulationEngineRef.current.toggleSimulatedEmergency('South');
    tickDemoSimulation();
  };

  const handleChangePollingInterval = (intervalMs: number) => {
    setPollingIntervalMs(intervalMs);
  };

  const activeApproachStats = viewModel.selectedGreenRoad
    ? viewModel.approaches[viewModel.selectedGreenRoad]
    : undefined;

  return (
    <div className="dashboard-root">
      <div className="dashboard-content-container">
        {/* Top Navigation & Status Header */}
        <Header
          mode={connectionMode}
          lastUpdated={viewModel.formattedTime}
          frameIndex={viewModel.frameIndex}
          latencyMs={latencyMs}
          isDataSourceDemo={viewModel.isDataSourceDemo}
          onRefresh={fetchBackendState}
        />

        {/* Stale / Disconnected Notice (if applicable) */}
        {connectionMode === 'stale' && (
          <div className="alert-strip alert-strip-warning" role="alert">
            <span className="alert-icon">⚠️</span>
            <span>
              <strong>Backend Telemetry Stale:</strong> The values shown reflect the latest frame from{' '}
              <code>output/traffic_state.json</code>. The detection pipeline (<code>main.py</code>) may have completed or is paused.
            </span>
          </div>
        )}

        {connectionMode === 'disconnected' && !isDemoMode && (
          <div className="alert-strip alert-strip-danger" role="alert">
            <span className="alert-icon">🔌</span>
            <span>
              <strong>Backend Bridge Offline:</strong> Could not read <code>output/traffic_state.json</code>. Run{' '}
              <code>python serve_dashboard.py</code> in terminal or switch to <strong>Interactive Demo Mode</strong> below.
            </span>
            <button
              type="button"
              className="alert-btn"
              onClick={() => handleToggleDemoMode(true)}
            >
              Switch to Demo Mode
            </button>
          </div>
        )}

        {/* Emergency Vehicle Status Banner */}
        <EmergencyBanner
          emergencyActive={viewModel.emergencyActive}
          emergencyRoad={viewModel.emergencyRoad}
          emergencyClass={viewModel.emergencyClass}
          isDemoMode={viewModel.isDataSourceDemo}
        />

        {/* Main 2-Column Dashboard Layout */}
        <main className="dashboard-main-grid">
          {/* Left Column: Intersection Map Visualization */}
          <section className="dashboard-left-col">
            <IntersectionView
              approaches={viewModel.approaches}
              selectedGreenRoad={viewModel.selectedGreenRoad}
              greenHoldRemaining={viewModel.greenHoldRemaining}
              emergencyActive={viewModel.emergencyActive}
              emergencyRoad={viewModel.emergencyRoad}
              emergencyClass={viewModel.emergencyClass}
            />
          </section>

          {/* Right Column: Telemetry & Controls */}
          <aside className="dashboard-right-col">
            <SignalStatusCard
              selectedGreenRoad={viewModel.selectedGreenRoad}
              greenHoldRemaining={viewModel.greenHoldRemaining}
              decisionExplanation={viewModel.decisionExplanation}
              decisionIsEstimated={viewModel.decisionIsEstimated}
              activeApproachStats={activeApproachStats}
              emergencyActive={viewModel.emergencyActive}
              emergencyRoad={viewModel.emergencyRoad}
            />

            <ApproachGrid approaches={viewModel.approaches} />

            <Controls
              mode={connectionMode}
              isPolling={isPolling}
              isDemoMode={isDemoMode}
              selectedScenarioId={selectedScenarioId}
              pollingIntervalMs={pollingIntervalMs}
              emergencyActive={viewModel.emergencyActive}
              onTogglePolling={handleTogglePolling}
              onReset={handleReset}
              onToggleDemoMode={handleToggleDemoMode}
              onSelectScenario={handleSelectScenario}
              onToggleEmergencySimulation={handleToggleEmergencySimulation}
              onChangePollingInterval={handleChangePollingInterval}
            />
          </aside>
        </main>

        {/* Key Performance Indicators (KPIs) Full-Width Section */}
        <KpiSection
          kpis={viewModel.kpis}
          frameIndex={viewModel.frameIndex}
        />

        {/* Compliance, Research & Safety Disclaimer Footer */}
        <footer className="dashboard-footer" role="contentinfo">
          <div className="footer-disclaimer-card">
            <div className="footer-title-row">
              <span className="disclaimer-shield">🛡</span>
              <span className="disclaimer-heading">VegMitra Academic Research &amp; Simulation System</span>
            </div>
            <p className="disclaimer-text">
              This dashboard is a simulation and visual telemetry interface for the B.Tech Computer Science research project{' '}
              <strong>VegMitra (AI-Based Adaptive Traffic Signal Management System)</strong>. Telemetry is sourced from YOLOv8 object detection on camera feeds and processed via BoTSORT tracking and algorithmic signal scheduling. It is designed exclusively for evaluation and demonstration purposes and is not connected to physical municipal traffic equipment.
            </p>
          </div>
        </footer>
      </div>
    </div>
  );
};
