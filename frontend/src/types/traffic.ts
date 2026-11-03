/**
 * VegMitra Traffic Management System - Type Definitions
 * 
 * Defines strict types for backend traffic state payloads,
 * UI view-models, connection states, and simulation parameters.
 */

export type RoadName = 'North' | 'South' | 'East' | 'West';

export type SignalAspect = 'RED' | 'AMBER' | 'GREEN';

export type CongestionCategory = 'LOW' | 'MODERATE' | 'HIGH' | 'CRITICAL';

export type ConnectionMode = 'live' | 'demo' | 'paused' | 'disconnected' | 'stale';

/**
 * Raw JSON payload exported by Python pipeline (detector.py / main.py)
 * to output/traffic_state.json.
 */
export interface RawTrafficStatePayload {
  timestamp?: number;
  frame_index?: number;
  counts?: Partial<Record<RoadName, number>>;
  smoothed_counts?: Partial<Record<RoadName, number>>;
  density?: Partial<Record<RoadName, number>>;
  selected_green_road?: RoadName | string | null;
  emergency_active?: boolean;
  emergency_road?: string | null;
  emergency_class?: string | null;
  total_vehicles?: number;
  green_hold_remaining?: number;
}

/**
 * Normalized per-approach statistics for UI presentation.
 */
export interface ApproachStats {
  road: RoadName;
  directionLabel: string; // e.g. "North Corridor"
  icon: string;           // e.g. "▲"
  count: number;          // Raw detection count (integer)
  smoothedCount: number;  // 10-frame rolling average
  densityPct: number;     // Calculated density percentage (0-100)
  densityLevel: CongestionCategory;
  isGreen: boolean;
  signalAspect: SignalAspect;
}

/**
 * High-level system KPIs.
 */
export interface SystemKpis {
  totalVehicles: number;
  totalVehiclesAvailable: boolean;
  averageCongestionPct: number;
  congestionLevel: CongestionCategory;
  averageWaitTimeSec: number | null; // null if not directly measured
  waitTimeIsEstimated: boolean;
  estimatedFuelSavedLiters: number | null; // null or clearly marked estimate
  fuelIsEstimated: boolean;
}

/**
 * Complete normalized view-model consumed by the dashboard components.
 */
export interface DashboardViewModel {
  timestamp: number | null;
  formattedTime: string;
  frameIndex: number | null;
  approaches: Record<RoadName, ApproachStats>;
  selectedGreenRoad: RoadName | null;
  greenHoldRemaining: number;
  isHoldingGreen: boolean;
  emergencyActive: boolean;
  emergencyRoad: string | null;
  emergencyClass: string | null;
  decisionExplanation: string;
  decisionIsEstimated: boolean;
  kpis: SystemKpis;
  isDataSourceDemo: boolean;
  dataQualityNotes: string[];
}

/**
 * UI State for controls and connection management.
 */
export interface DashboardControlState {
  mode: ConnectionMode;
  pollingIntervalMs: number;
  isPolling: boolean;
  activeScenarioId?: string;
  lastSuccessfulFetch: Date | null;
  fetchLatencyMs: number;
  errorMessage?: string;
}

/**
 * Demo scenario template for the mock data engine.
 */
export interface DemoScenario {
  id: string;
  name: string;
  description: string;
  counts: Record<RoadName, number>;
  smoothedCounts: Record<RoadName, number>;
  densities: Record<RoadName, number>;
  selectedRoad: RoadName;
  holdTime: number;
  emergencyActive: boolean;
  emergencyRoad?: string;
  emergencyClass?: string;
}
