/**
 * VegMitra - AI Adaptive Traffic Signal Management System
 * Production Application Bundle (ES5/ES6 compatible with React 18)
 * 
 * Sourced directly from frontend/src/ TypeScript modules.
 */

(function () {
  'use strict';

  var React = window.React;
  var ReactDOM = window.ReactDOM;

  // Verify React availability
  if (!React || !ReactDOM) {
    console.error('React / ReactDOM not detected in global scope. Ensure script tags are loaded.');
    return;
  }

  var createElement = React.createElement;
  var useState = React.useState;
  var useEffect = React.useEffect;
  var useRef = React.useRef;
  var useCallback = React.useCallback;

  var ALL_ROADS = ['North', 'South', 'East', 'West'];

  var ROAD_ICONS = {
    North: '▲',
    South: '▼',
    East: '►',
    West: '◄'
  };

  var ROAD_LABELS = {
    North: 'North Corridor',
    South: 'South Corridor',
    East: 'East Corridor',
    West: 'West Corridor'
  };

  function getCongestionLevel(densityPct) {
    if (isNaN(densityPct) || densityPct < 0) return 'LOW';
    if (densityPct < 25) return 'LOW';
    if (densityPct < 60) return 'MODERATE';
    if (densityPct < 85) return 'HIGH';
    return 'CRITICAL';
  }

  function normalizeRoadName(road) {
    if (!road || typeof road !== 'string') return null;
    var clean = road.trim().toLowerCase();
    for (var i = 0; i < ALL_ROADS.length; i++) {
      if (ALL_ROADS[i].toLowerCase() === clean) return ALL_ROADS[i];
    }
    return null;
  }

  function formatTimestamp(ts) {
    if (!ts || isNaN(ts) || ts <= 0) return '—';
    try {
      var date = new Date(ts > 1e11 ? ts : ts * 1000);
      return date.toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    } catch (e) {
      return '—';
    }
  }

  function deriveDecisionExplanation(selectedRoad, densities, emergencyActive, emergencyRoad) {
    if (emergencyActive && emergencyRoad) {
      return {
        text: 'EMERGENCY PREEMPTION: Priority vehicle detected on ' + emergencyRoad + '. Standard adaptive cycle overridden.',
        isEstimated: false
      };
    }

    if (!selectedRoad) {
      return {
        text: 'Standby: Controller initializing or in transition phase.',
        isEstimated: true
      };
    }

    var selectedDensity = densities[selectedRoad] != null ? densities[selectedRoad] : 0;
    var isHighest = true;
    for (var i = 0; i < ALL_ROADS.length; i++) {
      var r = ALL_ROADS[i];
      if (r !== selectedRoad && (densities[r] != null ? densities[r] : 0) > selectedDensity) {
        isHighest = false;
        break;
      }
    }

    if (isHighest) {
      return {
        text: selectedRoad + ' selected: Highest reported traffic density (' + selectedDensity.toFixed(1) + '%).',
        isEstimated: true
      };
    } else {
      return {
        text: selectedRoad + ' holding green: Active minimum green hold or hysteresis margin preventing signal flicker.',
        isEstimated: true
      };
    }
  }

  function adaptTrafficState(raw, isDemoMode) {
    var payload = (typeof raw === 'object' && raw !== null ? raw : {});
    var timestamp = typeof payload.timestamp === 'number' && !isNaN(payload.timestamp) ? payload.timestamp : null;
    var frameIndex = typeof payload.frame_index === 'number' && !isNaN(payload.frame_index) ? payload.frame_index : null;
    var selectedGreenRoad = normalizeRoadName(payload.selected_green_road);
    var greenHoldRemaining = typeof payload.green_hold_remaining === 'number' && !isNaN(payload.green_hold_remaining)
      ? Math.max(0, payload.green_hold_remaining)
      : 0;

    var emergencyActive = Boolean(payload.emergency_active);
    var emergencyRoad = typeof payload.emergency_road === 'string' && payload.emergency_road.trim().length > 0
      ? payload.emergency_road.trim()
      : null;
    var emergencyClass = typeof payload.emergency_class === 'string' && payload.emergency_class.trim().length > 0
      ? payload.emergency_class.trim()
      : null;

    var rawCounts = payload.counts || {};
    var rawSmoothed = payload.smoothed_counts || {};
    var rawDensity = payload.density || {};

    var approaches = {};
    var densityValues = {};
    var sumCounts = 0;
    var sumDensity = 0;

    for (var i = 0; i < ALL_ROADS.length; i++) {
      var road = ALL_ROADS[i];
      var countVal = rawCounts[road];
      var smoothedVal = rawSmoothed[road];
      var densityVal = rawDensity[road];

      var count = typeof countVal === 'number' && !isNaN(countVal) ? Math.max(0, Math.round(countVal)) : 0;
      var smoothedCount = typeof smoothedVal === 'number' && !isNaN(smoothedVal) ? Math.max(0, Number(smoothedVal.toFixed(1))) : 0;
      var densityPct = typeof densityVal === 'number' && !isNaN(densityVal) ? Math.min(100, Math.max(0, Number(densityVal.toFixed(1)))) : 0;

      sumCounts += count;
      sumDensity += densityPct;
      densityValues[road] = densityPct;

      var isGreen = selectedGreenRoad === road;
      var signalAspect = isGreen ? 'GREEN' : 'RED';
      if (isGreen && greenHoldRemaining > 0 && greenHoldRemaining < 0.4) {
        signalAspect = 'AMBER';
      }

      approaches[road] = {
        road: road,
        directionLabel: ROAD_LABELS[road],
        icon: ROAD_ICONS[road],
        count: count,
        smoothedCount: smoothedCount,
        densityPct: densityPct,
        densityLevel: getCongestionLevel(densityPct),
        isGreen: isGreen,
        signalAspect: signalAspect
      };
    }

    var totalVehicles = sumCounts;
    var totalVehiclesAvailable = true;
    if (typeof payload.total_vehicles === 'number' && !isNaN(payload.total_vehicles)) {
      totalVehicles = payload.total_vehicles;
    }

    var averageCongestionPct = Number((sumDensity / ALL_ROADS.length).toFixed(1));
    var congestionLevel = getCongestionLevel(averageCongestionPct);

    // Webster's queue delay model estimate
    var averageWaitTimeSec = null;
    if (totalVehicles > 0) {
      averageWaitTimeSec = Number((8.0 + (averageCongestionPct * 0.28)).toFixed(1));
    } else {
      averageWaitTimeSec = 0.0;
    }

    // Fuel saving estimate
    var estimatedFuelSavedLiters = null;
    if (totalVehicles > 0) {
      var idleSavedHours = (totalVehicles * 0.18) / 60;
      estimatedFuelSavedLiters = Number((idleSavedHours * 0.8).toFixed(2));
    } else {
      estimatedFuelSavedLiters = 0.0;
    }

    var decision = deriveDecisionExplanation(selectedGreenRoad, densityValues, emergencyActive, emergencyRoad);

    return {
      timestamp: timestamp,
      formattedTime: formatTimestamp(timestamp),
      frameIndex: frameIndex,
      approaches: approaches,
      selectedGreenRoad: selectedGreenRoad,
      greenHoldRemaining: Number(greenHoldRemaining.toFixed(1)),
      isHoldingGreen: greenHoldRemaining > 0,
      emergencyActive: emergencyActive,
      emergencyRoad: emergencyRoad,
      emergencyClass: emergencyClass,
      decisionExplanation: decision.text,
      decisionIsEstimated: decision.isEstimated,
      kpis: {
        totalVehicles: totalVehicles,
        totalVehiclesAvailable: totalVehiclesAvailable,
        averageCongestionPct: averageCongestionPct,
        congestionLevel: congestionLevel,
        averageWaitTimeSec: averageWaitTimeSec,
        waitTimeIsEstimated: true,
        estimatedFuelSavedLiters: estimatedFuelSavedLiters,
        fuelIsEstimated: true
      },
      isDataSourceDemo: Boolean(isDemoMode)
    };
  }

  // ================= DEMO SCENARIOS =================
  var DEMO_SCENARIOS = [
    {
      id: 'balanced',
      name: 'Normal Urban Traffic (Balanced)',
      counts: { North: 3, South: 4, East: 3, West: 2 },
      smoothedCounts: { North: 3.2, South: 3.8, East: 3.1, West: 2.4 },
      densities: { North: 10.7, South: 12.7, East: 10.3, West: 8.0 },
      selectedRoad: 'South',
      holdTime: 7.5,
      emergencyActive: false
    },
    {
      id: 'peak_morning',
      name: 'Morning Commute (East Heavy)',
      counts: { North: 2, South: 8, East: 14, West: 3 },
      smoothedCounts: { North: 2.1, South: 7.6, East: 13.5, West: 2.9 },
      densities: { North: 7.0, South: 25.3, East: 45.0, West: 9.7 },
      selectedRoad: 'East',
      holdTime: 12.0,
      emergencyActive: false
    },
    {
      id: 'peak_evening',
      name: 'Evening Commute (West Heavy)',
      counts: { North: 9, South: 3, East: 4, West: 16 },
      smoothedCounts: { North: 8.7, South: 3.1, East: 3.8, West: 15.2 },
      densities: { North: 29.0, South: 10.3, East: 12.7, West: 50.7 },
      selectedRoad: 'West',
      holdTime: 10.0,
      emergencyActive: false
    },
    {
      id: 'emergency_ambulance',
      name: 'Emergency Priority (Ambulance on South)',
      counts: { North: 4, South: 6, East: 7, West: 3 },
      smoothedCounts: { North: 4.0, South: 6.2, East: 6.9, West: 3.1 },
      densities: { North: 13.3, South: 20.7, East: 23.0, West: 10.3 },
      selectedRoad: 'South',
      holdTime: 14.5,
      emergencyActive: true,
      emergencyRoad: 'South',
      emergencyClass: 'ambulance'
    }
  ];

  function MockEngine() {
    this.scenario = DEMO_SCENARIOS[0];
    this.counts = Object.assign({}, this.scenario.counts);
    this.smoothed = Object.assign({}, this.scenario.smoothedCounts);
    this.densities = Object.assign({}, this.scenario.densities);
    this.greenRoad = this.scenario.selectedRoad;
    this.holdRemaining = this.scenario.holdTime;
    this.emergencyActive = false;
    this.emergencyRoad = 'South';
    this.frame = 100;
  }

  MockEngine.prototype.setScenario = function (id) {
    for (var i = 0; i < DEMO_SCENARIOS.length; i++) {
      if (DEMO_SCENARIOS[i].id === id) {
        this.scenario = DEMO_SCENARIOS[i];
        this.counts = Object.assign({}, this.scenario.counts);
        this.smoothed = Object.assign({}, this.scenario.smoothedCounts);
        this.densities = Object.assign({}, this.scenario.densities);
        this.greenRoad = this.scenario.selectedRoad;
        this.holdRemaining = this.scenario.holdTime;
        this.emergencyActive = this.scenario.emergencyActive;
        this.emergencyRoad = this.scenario.emergencyRoad || 'South';
        break;
      }
    }
  };

  MockEngine.prototype.toggleEmergency = function (road) {
    this.emergencyActive = !this.emergencyActive;
    this.emergencyRoad = road || 'South';
    if (this.emergencyActive) {
      this.greenRoad = this.emergencyRoad;
      this.holdRemaining = 15.0;
    }
    return this.emergencyActive;
  };

  MockEngine.prototype.tick = function (dt) {
    this.frame += Math.round(dt * 25);
    var nowSec = Date.now() / 1000;

    for (var i = 0; i < ALL_ROADS.length; i++) {
      var r = ALL_ROADS[i];
      var base = this.scenario.counts[r];
      var delta = (Math.random() > 0.6 ? 1 : 0) - (Math.random() > 0.6 ? 1 : 0);
      var newCount = Math.max(0, Math.min(25, base + delta));
      this.counts[r] = newCount;
      var alpha = 0.15;
      this.smoothed[r] = Number((this.smoothed[r] * (1 - alpha) + newCount * alpha).toFixed(1));
      this.densities[r] = Number(Math.min(100, (this.smoothed[r] / 30) * 100).toFixed(1));
    }

    this.holdRemaining = Math.max(0, this.holdRemaining - dt);

    if (this.emergencyActive) {
      this.greenRoad = this.emergencyRoad;
      if (this.holdRemaining <= 0) this.holdRemaining = 10.0;
    } else if (this.holdRemaining <= 0) {
      var bestRoad = this.greenRoad;
      var highestDensity = -1;
      for (var j = 0; j < ALL_ROADS.length; j++) {
        var rd = ALL_ROADS[j];
        if (this.densities[rd] > highestDensity) {
          highestDensity = this.densities[rd];
          bestRoad = rd;
        }
      }

      var currentDensity = this.densities[this.greenRoad];
      if (bestRoad !== this.greenRoad && (highestDensity - currentDensity >= 2.0)) {
        this.greenRoad = bestRoad;
        this.holdRemaining = 8.0;
      } else if (highestDensity <= 0) {
        var nextIdx = (ALL_ROADS.indexOf(this.greenRoad) + 1) % ALL_ROADS.length;
        this.greenRoad = ALL_ROADS[nextIdx];
        this.holdRemaining = 8.0;
      }
    }

    var total = 0;
    for (var k = 0; k < ALL_ROADS.length; k++) total += this.counts[ALL_ROADS[k]];

    return {
      timestamp: nowSec,
      frame_index: this.frame,
      counts: Object.assign({}, this.counts),
      smoothed_counts: Object.assign({}, this.smoothed),
      density: Object.assign({}, this.densities),
      selected_green_road: this.greenRoad,
      emergency_active: this.emergencyActive,
      emergency_road: this.emergencyActive ? this.emergencyRoad : null,
      emergency_class: this.emergencyActive ? 'ambulance' : null,
      total_vehicles: total,
      green_hold_remaining: Number(this.holdRemaining.toFixed(1))
    };
  };

  // ================= COMPONENTS =================
  function Tooltip(props) {
    var content = props.content;
    var children = props.children;
    var position = props.position || 'top';
    var state = useState(false);
    var isVisible = state[0];
    var setIsVisible = state[1];

    return createElement(
      'span',
      {
        className: 'tooltip-container',
        onMouseEnter: function () { setIsVisible(true); },
        onMouseLeave: function () { setIsVisible(false); },
        onFocus: function () { setIsVisible(true); },
        onBlur: function () { setIsVisible(false); },
        tabIndex: 0,
        role: 'tooltip',
        'aria-label': content
      },
      children,
      isVisible ? createElement('span', { className: 'tooltip-bubble tooltip-' + position }, content) : null
    );
  }

  function Header(props) {
    var mode = props.mode;
    var lastUpdated = props.lastUpdated;
    var frameIndex = props.frameIndex;
    var latencyMs = props.latencyMs;
    var isDataSourceDemo = props.isDataSourceDemo;
    var onRefresh = props.onRefresh;

    var getStatusBadge = function () {
      switch (mode) {
        case 'live':
          return { label: 'LIVE BACKEND', className: 'badge-live', dotClass: 'dot-pulse-green', tip: 'Live output/traffic_state.json bridge' };
        case 'demo':
          return { label: 'DEMO SIMULATION', className: 'badge-demo', dotClass: 'dot-pulse-blue', tip: 'Interactive client mock simulator' };
        case 'stale':
          return { label: 'STALE DATA', className: 'badge-stale', dotClass: 'dot-warning', tip: 'Backend data unchanged (> 4s)' };
        case 'paused':
          return { label: 'PAUSED', className: 'badge-paused', dotClass: 'dot-gray', tip: 'Dashboard polling paused' };
        case 'disconnected':
        default:
          return { label: 'DISCONNECTED', className: 'badge-disconnected', dotClass: 'dot-red', tip: 'Cannot read traffic_state.json' };
      }
    };

    var status = getStatusBadge();

    return createElement(
      'header',
      { className: 'dashboard-header', role: 'banner' },
      createElement(
        'div',
        { className: 'header-brand-block' },
        createElement(
          'div',
          { className: 'logo-group' },
          createElement(
            'div',
            { className: 'brand-logo-icon', 'aria-hidden': 'true' },
            createElement(
              'svg',
              { width: 26, height: 26, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2.2 },
              createElement('rect', { x: 5, y: 2, width: 14, height: 20, rx: 3, fill: '#131e33', stroke: '#253553' }),
              createElement('circle', { cx: 12, cy: 7, r: 2.2, fill: '#ef4444' }),
              createElement('circle', { cx: 12, cy: 12, r: 2.2, fill: '#f59e0b' }),
              createElement('circle', { cx: 12, cy: 17, r: 2.2, fill: '#10b981' })
            )
          ),
          createElement(
            'div',
            null,
            createElement('h1', { className: 'brand-title' }, 'Veg', createElement('span', { className: 'accent-mint' }, 'Mitra')),
            createElement('p', { className: 'brand-subtitle' }, 'AI-Based Smart Traffic Light Management System')
          )
        )
      ),
      createElement(
        'div',
        { className: 'header-meta-block' },
        createElement('div', { className: 'header-tagline-row' }, createElement('span', { className: 'system-tagline' }, 'Smarter Signals | Greener Cities | Better Tomorrows')),
        createElement(
          'div',
          { className: 'header-status-row' },
          createElement(
            Tooltip,
            { content: status.tip },
            createElement(
              'div',
              { className: 'status-pill ' + status.className, role: 'status' },
              createElement('span', { className: 'status-dot ' + status.dotClass, 'aria-hidden': 'true' }),
              createElement('span', { className: 'status-label' }, status.label)
            )
          ),
          createElement(
            'div',
            { className: 'system-health-chip', title: 'Active Engine' },
            createElement('span', { className: 'health-label' }, 'ENGINE:'),
            createElement('span', { className: 'health-val' }, isDataSourceDemo ? 'Synthetic Demo' : 'YOLOv8 + BoTSORT')
          ),
          createElement(
            'div',
            { className: 'system-health-chip', title: 'Last State Update' },
            createElement('span', { className: 'health-label' }, 'UPDATED:'),
            createElement('span', { className: 'health-val' }, lastUpdated)
          ),
          frameIndex !== null ? createElement(
            'div',
            { className: 'system-health-chip', title: 'Frame Index' },
            createElement('span', { className: 'health-label' }, 'FRAME:'),
            createElement('span', { className: 'health-val' }, '#' + frameIndex)
          ) : null,
          latencyMs > 0 ? createElement(
            'div',
            { className: 'system-health-chip', title: 'Bridge Latency' },
            createElement('span', { className: 'health-label' }, 'LATENCY:'),
            createElement('span', { className: 'health-val' }, latencyMs + 'ms')
          ) : null,
          onRefresh ? createElement(
            'button',
            { className: 'refresh-btn', onClick: onRefresh, title: 'Refresh Data', 'aria-label': 'Refresh traffic state' },
            '↻'
          ) : null
        )
      )
    );
  }

  function EmergencyBanner(props) {
    var emergencyActive = props.emergencyActive;
    var emergencyRoad = props.emergencyRoad;
    var emergencyClass = props.emergencyClass;
    var isDemoMode = props.isDemoMode;

    if (emergencyActive) {
      return createElement(
        'div',
        { className: 'emergency-banner-alert', role: 'alert', 'aria-live': 'assertive' },
        createElement('div', { className: 'emergency-pulse-indicator', 'aria-hidden': 'true' }, createElement('span', { className: 'emergency-siren-dot' })),
        createElement(
          'div',
          { className: 'emergency-content' },
          createElement(
            'div',
            { className: 'emergency-header-row' },
            createElement('span', { className: 'emergency-badge' }, 'EMERGENCY PREEMPTION ACTIVE'),
            isDemoMode ? createElement('span', { className: 'demo-sim-tag' }, '[Simulated Action]') : null
          ),
          createElement(
            'p',
            { className: 'emergency-detail-msg' },
            'High-priority vehicle detected: ',
            createElement('strong', null, (emergencyClass || 'EMERGENCY VEHICLE').toUpperCase()),
            ' approaching on ',
            createElement('strong', null, (emergencyRoad || 'ACTIVE').toUpperCase() + ' CORRIDOR'),
            '. Standard signal timing suspended; continuous GREEN granted to clear intersection.'
          )
        )
      );
    }

    return createElement(
      'div',
      { className: 'emergency-banner-calm', role: 'status' },
      createElement(
        'div',
        { className: 'calm-status-wrap' },
        createElement('span', { className: 'calm-shield-icon', 'aria-hidden': 'true' }, '🛡'),
        createElement(
          'div',
          { className: 'calm-text-group' },
          createElement('span', { className: 'calm-title' }, 'No Emergency Detected'),
          createElement(
            'span',
            { className: 'calm-desc' },
            'Standard adaptive density cycle running. ',
            createElement(
              Tooltip,
              { content: 'Baseline YOLOv8 weights (car, motorcycle, bus, truck) lack emergency classes. Preemption code paths trigger via specialized models or external signal broadcasts.' },
              createElement('span', { className: 'info-icon', 'aria-label': 'Info' }, 'ℹ')
            )
          )
        )
      ),
      createElement('span', { className: 'calm-badge' }, 'NORMAL CYCLING')
    );
  }

  function IntersectionView(props) {
    var approaches = props.approaches;
    var selectedGreenRoad = props.selectedGreenRoad;
    var greenHoldRemaining = props.greenHoldRemaining;
    var emergencyActive = props.emergencyActive;
    var emergencyRoad = props.emergencyRoad;

    var getAspect = function (road) {
      if (selectedGreenRoad === road) {
        if (greenHoldRemaining > 0 && greenHoldRemaining <= 0.8) return 'AMBER';
        return 'GREEN';
      }
      return 'RED';
    };

    var renderVehicles = function (road, count) {
      var isEmergencyOnThisRoad = emergencyActive && emergencyRoad && emergencyRoad.toLowerCase() === road.toLowerCase();
      var clamped = Math.min(count, 8);
      var nodes = [];

      for (var i = 0; i < clamped; i++) {
        var isAmbulance = isEmergencyOnThisRoad && i === 0;
        var x = 0, y = 0, rot = 0;
        if (road === 'North') { x = 270; y = 70 + i * 26; rot = 180; }
        else if (road === 'South') { x = 330; y = 530 - i * 26; rot = 0; }
        else if (road === 'East') { x = 530 - i * 26; y = 270; rot = 270; }
        else if (road === 'West') { x = 70 + i * 26; y = 330; rot = 90; }

        var body = isAmbulance
          ? createElement(
              'g',
              null,
              createElement('rect', { x: -10, y: -18, width: 20, height: 36, rx: 4, fill: '#ffffff', stroke: '#ef4444', strokeWidth: 2 }),
              createElement('rect', { x: -7, y: -15, width: 14, height: 8, rx: 2, fill: '#38bdf8' }),
              createElement('rect', { x: -8, y: 2, width: 16, height: 5, fill: '#ef4444' }),
              createElement('rect', { x: -2.5, y: -3, width: 5, height: 15, fill: '#ef4444' }),
              createElement('circle', { cx: 0, cy: -6, r: 4, fill: '#ef4444', className: 'siren-beacon' })
            )
          : createElement(
              'g',
              null,
              createElement('rect', {
                x: -8, y: -14, width: 16, height: 28, rx: 3.5,
                fill: i % 3 === 0 ? '#38bdf8' : i % 2 === 0 ? '#fbbf24' : '#f87171',
                stroke: '#0f172a', strokeWidth: 1.5
              }),
              createElement('rect', { x: -6, y: -10, width: 12, height: 6, rx: 1.5, fill: '#0f172a' }),
              createElement('rect', { x: -6, y: 4, width: 12, height: 5, rx: 1.5, fill: '#0f172a' }),
              createElement('circle', { cx: -5, cy: -13, r: 1.5, fill: '#fef08a' }),
              createElement('circle', { cx: 5, cy: -13, r: 1.5, fill: '#fef08a' })
            );

        nodes.push(
          createElement(
            'g',
            { key: road + '-veh-' + i, transform: 'translate(' + x + ', ' + y + ') rotate(' + rot + ')', className: isAmbulance ? 'vehicle-emergency-pulse' : 'vehicle-icon' },
            body
          )
        );
      }
      return nodes;
    };

    var renderSignal = function (road, x, y, label) {
      var aspect = getAspect(road);
      var isGreen = aspect === 'GREEN';
      var isAmber = aspect === 'AMBER';
      var isRed = aspect === 'RED';

      return createElement(
        'g',
        { className: 'traffic-signal-head', transform: 'translate(' + x + ', ' + y + ')' },
        createElement('rect', {
          x: -14, y: -36, width: 28, height: 72, rx: 6,
          fill: '#0c1322', stroke: isGreen ? '#10b981' : '#23334d', strokeWidth: isGreen ? 2.5 : 1.5,
          className: isGreen ? 'signal-housing-active' : ''
        }),
        createElement('rect', { x: -11, y: -50, width: 22, height: 12, rx: 3, fill: '#1e293b' }),
        createElement('text', { x: 0, y: -41, textAnchor: 'middle', fill: '#94a3b8', fontSize: 9, fontWeight: 700 }, label),
        createElement('circle', {
          cx: 0, cy: -22, r: 8,
          fill: isRed ? '#ef4444' : '#331215', stroke: isRed ? '#fca5a5' : '#1e293b', strokeWidth: 1,
          className: isRed ? 'lamp-glow-red' : ''
        }),
        isRed ? createElement('text', { x: 0, y: -19.5, textAnchor: 'middle', fill: '#ffffff', fontSize: 7, fontWeight: 900 }, 'STOP') : null,
        createElement('circle', {
          cx: 0, cy: 0, r: 8,
          fill: isAmber ? '#f59e0b' : '#33240d', stroke: isAmber ? '#fde68a' : '#1e293b', strokeWidth: 1,
          className: isAmber ? 'lamp-glow-amber' : ''
        }),
        createElement('circle', {
          cx: 0, cy: 22, r: 8,
          fill: isGreen ? '#10b981' : '#072e21', stroke: isGreen ? '#6ee7b7' : '#1e293b', strokeWidth: 1,
          className: isGreen ? 'lamp-glow-green' : ''
        }),
        isGreen ? createElement('text', { x: 0, y: 24.5, textAnchor: 'middle', fill: '#ffffff', fontSize: 7, fontWeight: 900 }, 'GO') : null
      );
    };

    var crosswalkCoords = [240, 252, 264, 276, 288, 300, 312, 324, 336, 348];

    return createElement(
      'div',
      { className: 'intersection-container', role: 'region', 'aria-label': 'Intersection Map' },
      createElement(
        'div',
        { className: 'intersection-header-bar' },
        createElement(
          'div',
          { className: 'simulation-title-wrap' },
          createElement('span', { className: 'live-camera-tag' }, 'INTERSECTION OVERVIEW'),
          createElement('h2', { className: 'simulation-title' }, 'Smart City Autonomous Intersection')
        ),
        createElement(
          'div',
          { className: 'active-signal-banner' },
          createElement('span', { className: 'signal-lead-label' }, 'ACTIVE GREEN:'),
          selectedGreenRoad ? createElement(
            'span',
            { className: 'signal-active-pill' },
            createElement('span', { className: 'road-highlight-text' }, selectedGreenRoad.toUpperCase() + ' APPROACH'),
            createElement('span', { className: 'hold-pill-timer' }, '[' + greenHoldRemaining.toFixed(1) + 's hold]')
          ) : createElement('span', { className: 'signal-standby-pill' }, 'STANDBY')
        )
      ),
      createElement(
        'div',
        { className: 'svg-canvas-wrapper' },
        createElement(
          'svg',
          { viewBox: '0 0 600 600', className: 'intersection-svg', preserveAspectRatio: 'xMidYMid meet', role: 'img' },
          createElement(
            'defs',
            null,
            createElement(
              'pattern',
              { id: 'cityGrid', width: 20, height: 20, patternUnits: 'userSpaceOnUse' },
              createElement('path', { d: 'M 20 0 L 0 0 0 20', fill: 'none', stroke: '#141c2e', strokeWidth: 0.8 })
            ),
            createElement(
              'pattern',
              { id: 'boxJunctionGrid', width: 16, height: 16, patternUnits: 'userSpaceOnUse' },
              createElement('path', { d: 'M 0 0 L 16 16 M 16 0 L 0 16', fill: 'none', stroke: '#f59e0b', strokeWidth: 1.2, opacity: 0.85 })
            )
          ),
          createElement('rect', { width: 600, height: 600, fill: '#090d16' }),
          createElement('rect', { width: 600, height: 600, fill: 'url(#cityGrid)', opacity: 0.6 }),

          // COMMERCE CENTER (Top-Left)
          createElement(
            'g', { className: 'building-block' },
            createElement('rect', { x: 25, y: 25, width: 195, height: 195, rx: 6, fill: '#0e1726', stroke: '#1d2e4a', strokeWidth: 1.5 }),
            createElement('rect', { x: 45, y: 45, width: 155, height: 115, fill: '#09101c', stroke: '#0284c7', strokeWidth: 1, strokeDasharray: '3 3' }),
            createElement('line', { x1: 96, y1: 45, x2: 96, y2: 160, stroke: '#0284c7', strokeWidth: 0.8, strokeDasharray: '2 2' }),
            createElement('line', { x1: 147, y1: 45, x2: 147, y2: 160, stroke: '#0284c7', strokeWidth: 0.8, strokeDasharray: '2 2' }),
            createElement('line', { x1: 45, y1: 83, x2: 200, y2: 83, stroke: '#0284c7', strokeWidth: 0.8, strokeDasharray: '2 2' }),
            createElement('line', { x1: 45, y1: 121, x2: 200, y2: 121, stroke: '#0284c7', strokeWidth: 0.8, strokeDasharray: '2 2' }),
            createElement('rect', { x: 55, y: 175, width: 135, height: 28, rx: 4, fill: '#132138', stroke: '#1e3458', strokeWidth: 1 }),
            createElement('text', { x: 122, y: 193, textAnchor: 'middle', fill: '#93c5fd', fontSize: 10, fontWeight: 700, letterSpacing: '0.8' }, 'COMMERCE CENTER')
          ),

          // INNOVATION HUB with Helipad (Top-Right)
          createElement(
            'g', { className: 'building-block' },
            createElement('rect', { x: 380, y: 25, width: 195, height: 195, rx: 6, fill: '#0e1726', stroke: '#1d2e4a', strokeWidth: 1.5 }),
            createElement('rect', { x: 400, y: 45, width: 95, height: 115, fill: '#09101c', stroke: '#0284c7', strokeWidth: 1, strokeDasharray: '3 3' }),
            createElement('circle', { cx: 530, cy: 100, r: 32, fill: '#0b1320', stroke: '#f59e0b', strokeWidth: 2.5 }),
            createElement('circle', { cx: 530, cy: 100, r: 28, fill: 'none', stroke: '#f59e0b', strokeWidth: 1, strokeDasharray: '4 4' }),
            createElement('text', { x: 530, y: 108, textAnchor: 'middle', fill: '#f59e0b', fontSize: 22, fontWeight: 900 }, 'H'),
            createElement('rect', { x: 410, y: 175, width: 135, height: 28, rx: 4, fill: '#132138', stroke: '#1e3458', strokeWidth: 1 }),
            createElement('text', { x: 477, y: 193, textAnchor: 'middle', fill: '#93c5fd', fontSize: 10, fontWeight: 700, letterSpacing: '0.8' }, 'INNOVATION HUB')
          ),

          // METRO CIVIC COMPLEX (Bottom-Left)
          createElement(
            'g', { className: 'building-block' },
            createElement('rect', { x: 25, y: 380, width: 195, height: 195, rx: 6, fill: '#0e1726', stroke: '#1d2e4a', strokeWidth: 1.5 }),
            createElement('rect', { x: 45, y: 400, width: 115, height: 95, fill: '#09101c', stroke: '#10b981', strokeWidth: 1.2 }),
            createElement('rect', { x: 165, y: 420, width: 40, height: 75, fill: '#121b29', stroke: '#1e2d42' }),
            createElement('rect', { x: 45, y: 515, width: 155, height: 28, rx: 4, fill: '#132138', stroke: '#1e3458', strokeWidth: 1 }),
            createElement('text', { x: 122, y: 533, textAnchor: 'middle', fill: '#93c5fd', fontSize: 10, fontWeight: 700, letterSpacing: '0.8' }, 'METRO CIVIC COMPLEX')
          ),

          // ECO-TECH CAMPUS (Bottom-Right)
          createElement(
            'g', { className: 'building-block' },
            createElement('rect', { x: 380, y: 380, width: 195, height: 195, rx: 6, fill: '#0e1726', stroke: '#1d2e4a', strokeWidth: 1.5 }),
            createElement('rect', { x: 400, y: 400, width: 155, height: 105, fill: '#061c14', stroke: '#059669', strokeWidth: 1.2 }),
            createElement('circle', { cx: 430, cy: 430, r: 14, fill: '#047857', opacity: 0.9 }),
            createElement('circle', { cx: 465, cy: 445, r: 16, fill: '#059669', opacity: 0.9 }),
            createElement('circle', { cx: 510, cy: 435, r: 15, fill: '#10b981', opacity: 0.85 }),
            createElement('rect', { x: 400, y: 525, width: 155, height: 28, rx: 4, fill: '#132138', stroke: '#1e3458', strokeWidth: 1 }),
            createElement('text', { x: 477, y: 543, textAnchor: 'middle', fill: '#6ee7b7', fontSize: 10, fontWeight: 700, letterSpacing: '0.8' }, 'ECO-TECH CAMPUS')
          ),

          // Corridors & Asphalts
          createElement('rect', { x: 235, y: 0, width: 130, height: 600, fill: '#161c28' }),
          createElement('rect', { x: 0, y: 235, width: 600, height: 130, fill: '#161c28' }),

          // Selected corridor neon boundary
          selectedGreenRoad === 'North' ? createElement('rect', { x: 237, y: 0, width: 126, height: 235, fill: 'none', stroke: '#10b981', strokeWidth: 3, className: 'active-corridor-glow' }) : null,
          selectedGreenRoad === 'South' ? createElement('rect', { x: 237, y: 365, width: 126, height: 235, fill: 'none', stroke: '#10b981', strokeWidth: 3, className: 'active-corridor-glow' }) : null,
          selectedGreenRoad === 'East' ? createElement('rect', { x: 365, y: 237, width: 235, height: 126, fill: 'none', stroke: '#10b981', strokeWidth: 3, className: 'active-corridor-glow' }) : null,
          selectedGreenRoad === 'West' ? createElement('rect', { x: 0, y: 237, width: 235, height: 126, fill: 'none', stroke: '#10b981', strokeWidth: 3, className: 'active-corridor-glow' }) : null,

          // Curbs
          createElement('line', { x1: 235, y1: 0, x2: 235, y2: 235, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 365, y1: 0, x2: 365, y2: 235, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 235, y1: 365, x2: 235, y2: 600, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 365, y1: 365, x2: 365, y2: 600, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 0, y1: 235, x2: 235, y2: 235, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 0, y1: 365, x2: 235, y2: 365, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 365, y1: 235, x2: 600, y2: 235, stroke: '#334155', strokeWidth: 3 }),
          createElement('line', { x1: 365, y1: 365, x2: 600, y2: 365, stroke: '#334155', strokeWidth: 3 }),

          // Yellow dashed lane lines
          createElement('line', { x1: 300, y1: 0, x2: 300, y2: 225, stroke: '#f59e0b', strokeWidth: 2.5, strokeDasharray: '10 8' }),
          createElement('line', { x1: 300, y1: 375, x2: 300, y2: 600, stroke: '#f59e0b', strokeWidth: 2.5, strokeDasharray: '10 8' }),
          createElement('line', { x1: 0, y1: 300, x2: 225, y2: 300, stroke: '#f59e0b', strokeWidth: 2.5, strokeDasharray: '10 8' }),
          createElement('line', { x1: 375, y1: 300, x2: 600, y2: 300, stroke: '#f59e0b', strokeWidth: 2.5, strokeDasharray: '10 8' }),

          // Corridor Titles
          createElement('text', { x: 300, y: 24, textAnchor: 'middle', fill: '#64748b', fontSize: 11, fontWeight: 800, letterSpacing: '1' }, 'NORTH CORRIDOR'),
          createElement('text', { x: 300, y: 585, textAnchor: 'middle', fill: '#64748b', fontSize: 11, fontWeight: 800, letterSpacing: '1' }, 'SOUTH CORRIDOR'),
          createElement('text', { x: 540, y: 304, textAnchor: 'middle', fill: '#64748b', fontSize: 11, fontWeight: 800, letterSpacing: '1' }, 'EAST >>'),
          createElement('text', { x: 60, y: 304, textAnchor: 'middle', fill: '#64748b', fontSize: 11, fontWeight: 800, letterSpacing: '1' }, '<< WEST'),

          // Crosswalks (zebra stripes)
          createElement(
            'g', { className: 'crosswalk-stripes' },
            crosswalkCoords.map(function (xp, idx) { return createElement('rect', { key: 'cn-' + idx, x: xp, y: 226, width: 7, height: 12, fill: '#f8fafc', opacity: 0.9 }); })
          ),
          createElement(
            'g', { className: 'crosswalk-stripes' },
            crosswalkCoords.map(function (xp, idx) { return createElement('rect', { key: 'cs-' + idx, x: xp, y: 362, width: 7, height: 12, fill: '#f8fafc', opacity: 0.9 }); })
          ),
          createElement(
            'g', { className: 'crosswalk-stripes' },
            crosswalkCoords.map(function (yp, idx) { return createElement('rect', { key: 'cw-' + idx, x: 226, y: yp, width: 12, height: 7, fill: '#f8fafc', opacity: 0.9 }); })
          ),
          createElement(
            'g', { className: 'crosswalk-stripes' },
            crosswalkCoords.map(function (yp, idx) { return createElement('rect', { key: 'ce-' + idx, x: 362, y: yp, width: 12, height: 7, fill: '#f8fafc', opacity: 0.9 }); })
          ),

          // Central Yellow Box Junction
          createElement('rect', { x: 240, y: 240, width: 120, height: 120, fill: '#121824', stroke: '#f59e0b', strokeWidth: 2.5 }),
          createElement('rect', { x: 240, y: 240, width: 120, height: 120, fill: 'url(#boxJunctionGrid)' }),
          createElement('line', { x1: 240, y1: 240, x2: 360, y2: 360, stroke: '#f59e0b', strokeWidth: 1.5, opacity: 0.9 }),
          createElement('line', { x1: 360, y1: 240, x2: 240, y2: 360, stroke: '#f59e0b', strokeWidth: 1.5, opacity: 0.9 }),

          // Vehicles Layer
          createElement(
            'g', { className: 'vehicles-layer' },
            renderVehicles('North', approaches.North ? approaches.North.count : 0),
            renderVehicles('South', approaches.South ? approaches.South.count : 0),
            renderVehicles('East', approaches.East ? approaches.East.count : 0),
            renderVehicles('West', approaches.West ? approaches.West.count : 0)
          ),

          // 4 Traffic Lights
          renderSignal('North', 218, 195, 'N'),
          renderSignal('South', 382, 405, 'S'),
          renderSignal('East', 405, 218, 'E'),
          renderSignal('West', 195, 382, 'W'),
          createElement('circle', { cx: 300, cy: 300, r: 4, fill: '#f59e0b' })
        )
      ),
      createElement(
        'div',
        { className: 'intersection-caption-bar' },
        createElement('span', { className: 'caption-text' }, '4-Road Intersection | Real-Time Vehicle Movement & Smart City Environment'),
        createElement(
          'span',
          { className: 'legend-pills' },
          createElement('span', { className: 'legend-item' }, createElement('span', { className: 'legend-dot green' }), ' GREEN: Active Go'),
          createElement('span', { className: 'legend-item' }, createElement('span', { className: 'legend-dot red' }), ' RED: Stopped'),
          emergencyActive ? createElement('span', { className: 'legend-item alert' }, createElement('span', { className: 'legend-dot amber' }), ' EMERGENCY PRIORITY') : null
        )
      )
    );
  }

  function SignalStatusCard(props) {
    var selectedGreenRoad = props.selectedGreenRoad;
    var greenHoldRemaining = props.greenHoldRemaining;
    var decisionExplanation = props.decisionExplanation;
    var decisionIsEstimated = props.decisionIsEstimated;
    var activeApproachStats = props.activeApproachStats;
    var emergencyActive = props.emergencyActive;
    var emergencyRoad = props.emergencyRoad;

    var displayName = emergencyActive && emergencyRoad
      ? emergencyRoad.toUpperCase() + ' (EMERGENCY)'
      : selectedGreenRoad ? selectedGreenRoad.toUpperCase() + ' CORRIDOR' : 'STANDBY / ROTATING';

    var systemStatus = emergencyActive
      ? 'PREEMPTION ACTIVE'
      : greenHoldRemaining > 0 ? 'HOLDING MINIMUM GREEN' : 'EVALUATING DENSITY';

    return createElement(
      'div',
      { className: 'card signal-status-card', role: 'region', 'aria-label': 'Current Signal Status' },
      createElement(
        'div',
        { className: 'card-header' },
        createElement('h3', { className: 'card-title' }, 'Current Signal Status'),
        createElement('span', { className: 'card-badge-pill' }, 'ACTIVE PHASE')
      ),
      createElement(
        'div',
        { className: 'signal-status-grid' },
        createElement(
          'div',
          { className: 'status-display-box green-road-box ' + (emergencyActive ? 'box-emergency' : '') },
          createElement(
            'div',
            { className: 'box-meta-label' },
            createElement('span', null, 'CURRENT GREEN ROAD'),
            emergencyActive ? createElement('span', { className: 'priority-tag' }, 'OVERRIDE') : null
          ),
          createElement(
            'div',
            { className: 'box-main-value accent-mint' },
            activeApproachStats ? createElement('span', { className: 'road-arrow-icon' }, activeApproachStats.icon) : null,
            createElement('span', { className: 'road-name-text' }, displayName)
          )
        ),
        createElement(
          'div',
          { className: 'status-display-box timer-box' },
          createElement(
            'div',
            { className: 'box-meta-label' },
            createElement('span', null, 'HOLD REMAINING'),
            createElement(
              Tooltip,
              { content: 'Enforced minimum green duration preventing signal flickering (hysteresis guarantee).' },
              createElement('span', { className: 'info-icon', 'aria-label': 'Info' }, 'ℹ')
            )
          ),
          createElement(
            'div',
            { className: 'box-main-value accent-cyan mono' },
            greenHoldRemaining > 0 ? greenHoldRemaining.toFixed(1) + 's' : '0.0s'
          )
        )
      ),
      createElement(
        'div',
        { className: 'ai-decision-panel' },
        createElement(
          'div',
          { className: 'decision-header' },
          createElement('span', { className: 'decision-title' }, 'AI DECISION REASON'),
          decisionIsEstimated ? createElement(
            Tooltip,
            { content: 'Derived from relative density metrics, 10% hysteresis threshold, and minimum green hold rules.' },
            createElement('span', { className: 'estimate-badge' }, '[Estimated Basis]*')
          ) : null
        ),
        createElement('p', { className: 'decision-text' }, decisionExplanation)
      ),
      createElement(
        'div',
        { className: 'telemetry-rows' },
        createElement(
          'div',
          { className: 'telemetry-row' },
          createElement('span', { className: 'telemetry-key' }, 'Selected Approach Density:'),
          createElement(
            'span',
            { className: 'telemetry-val' },
            activeApproachStats ? createElement(
              'span',
              { className: 'density-pill density-' + activeApproachStats.densityLevel.toLowerCase() },
              activeApproachStats.road + ' ' + activeApproachStats.densityPct.toFixed(1) + '% (' + activeApproachStats.densityLevel + ')'
            ) : '—'
          )
        ),
        createElement(
          'div',
          { className: 'telemetry-row' },
          createElement('span', { className: 'telemetry-key' }, 'Controller Logic:'),
          createElement('span', { className: 'telemetry-val highlight-cyan' }, 'Adaptive YOLO + Hysteresis (2.0%)')
        ),
        createElement(
          'div',
          { className: 'telemetry-row' },
          createElement('span', { className: 'telemetry-key' }, 'System Operational State:'),
          createElement('span', { className: 'telemetry-val ' + (emergencyActive ? 'highlight-red' : 'highlight-green') }, systemStatus)
        )
      )
    );
  }

  function ApproachCard(props) {
    var stats = props.stats;
    var road = stats.road;
    var icon = stats.icon;
    var count = stats.count;
    var smoothedCount = stats.smoothedCount;
    var densityPct = stats.densityPct;
    var densityLevel = stats.densityLevel;
    var isGreen = stats.isGreen;
    var signalAspect = stats.signalAspect;

    var aspectBadge = signalAspect === 'GREEN'
      ? { label: 'GREEN (GO)', className: 'aspect-pill-green' }
      : signalAspect === 'AMBER' ? { label: 'AMBER', className: 'aspect-pill-amber' } : { label: 'RED (STOP)', className: 'aspect-pill-red' };

    return createElement(
      'div',
      { className: 'approach-card ' + (isGreen ? 'approach-card-active' : ''), role: 'article', 'aria-label': road + ' corridor statistics' },
      createElement(
        'div',
        { className: 'approach-card-header' },
        createElement(
          'div',
          { className: 'road-title-wrap' },
          createElement('span', { className: 'road-dir-icon', 'aria-hidden': 'true' }, icon),
          createElement('span', { className: 'road-name' }, road)
        ),
        createElement('span', { className: 'signal-aspect-pill ' + aspectBadge.className }, aspectBadge.label)
      ),
      createElement(
        'div',
        { className: 'approach-metric-body' },
        createElement(
          'div',
          { className: 'count-display-group' },
          createElement('div', { className: 'count-primary' }, createElement('span', { className: 'count-num mono' }, count), createElement('span', { className: 'count-unit' }, 'veh')),
          createElement(
            'div',
            { className: 'count-smoothed-row' },
            createElement('span', { className: 'smoothed-label' }, 'Smoothed:'),
            createElement('span', { className: 'smoothed-val mono' }, smoothedCount.toFixed(1)),
            createElement(
              Tooltip,
              { content: '10-frame rolling average of incoming tracks.' },
              createElement('span', { className: 'info-icon', 'aria-label': 'Info' }, 'ℹ')
            )
          )
        ),
        createElement(
          'div',
          { className: 'density-section' },
          createElement(
            'div',
            { className: 'density-header-row' },
            createElement(
              'span',
              { className: 'density-title' },
              'Density:',
              createElement(Tooltip, { content: '(smoothed_count / 30 capacity) * 100%' }, createElement('span', { className: 'info-icon', 'aria-label': 'Info' }, 'ℹ'))
            ),
            createElement('span', { className: 'density-val-text density-text-' + densityLevel.toLowerCase() + ' mono' }, densityPct.toFixed(1) + '% (' + densityLevel + ')')
          ),
          createElement(
            'div',
            { className: 'density-progress-track', role: 'progressbar', 'aria-valuenow': densityPct, 'aria-valuemin': 0, 'aria-valuemax': 100 },
            createElement('div', { className: 'density-progress-fill fill-' + densityLevel.toLowerCase(), style: { width: Math.min(100, Math.max(4, densityPct)) + '%' } })
          )
        )
      )
    );
  }

  function ApproachGrid(props) {
    var approaches = props.approaches;
    return createElement(
      'div',
      { className: 'card traffic-info-card', role: 'region', 'aria-label': 'Traffic by Approach' },
      createElement(
        'div',
        { className: 'card-header' },
        createElement('h3', { className: 'card-title' }, 'Traffic Information'),
        createElement('span', { className: 'card-subtitle-tag' }, '4 APPROACHES')
      ),
      createElement(
        'div',
        { className: 'approach-grid-layout' },
        ALL_ROADS.map(function (road) {
          var stats = approaches[road];
          if (!stats) return null;
          return createElement(ApproachCard, { key: road, stats: stats });
        })
      )
    );
  }

  function Controls(props) {
    var isPolling = props.isPolling;
    var isDemoMode = props.isDemoMode;
    var selectedScenarioId = props.selectedScenarioId;
    var pollingIntervalMs = props.pollingIntervalMs;
    var emergencyActive = props.emergencyActive;
    var onTogglePolling = props.onTogglePolling;
    var onReset = props.onReset;
    var onToggleDemoMode = props.onToggleDemoMode;
    var onSelectScenario = props.onSelectScenario;
    var onToggleEmergency = props.onToggleEmergencySimulation;
    var onChangeInterval = props.onChangePollingInterval;

    return createElement(
      'div',
      { className: 'card control-section-card', role: 'region', 'aria-label': 'Controls' },
      createElement(
        'div',
        { className: 'card-header' },
        createElement('h3', { className: 'card-title' }, 'Control Section'),
        createElement('span', { className: 'card-subtitle-tag' }, 'SIMULATION DASHBOARD')
      ),
      createElement(
        'div',
        { className: 'source-toggle-group' },
        createElement('span', { className: 'source-label' }, 'Data Source:'),
        createElement(
          'div',
          { className: 'segmented-control', role: 'tablist' },
          createElement(
            'button',
            {
              type: 'button',
              role: 'tab',
              'aria-selected': !isDemoMode,
              className: 'segment-btn ' + (!isDemoMode ? 'segment-active' : ''),
              onClick: function () { onToggleDemoMode(false); }
            },
            '📡 Live Backend JSON'
          ),
          createElement(
            'button',
            {
              type: 'button',
              role: 'tab',
              'aria-selected': isDemoMode,
              className: 'segment-btn ' + (isDemoMode ? 'segment-active' : ''),
              onClick: function () { onToggleDemoMode(true); }
            },
            '🧪 Interactive Demo Mode'
          )
        )
      ),
      createElement(
        'div',
        { className: 'control-button-grid' },
        createElement(
          'button',
          {
            type: 'button',
            className: 'btn-action ' + (isPolling ? 'btn-stop' : 'btn-start'),
            onClick: onTogglePolling
          },
          isPolling ? 'Stop Simulation' : 'Start Simulation'
        ),
        createElement('button', { type: 'button', className: 'btn-action btn-reset', onClick: onReset }, 'Reset'),
        createElement(
          'button',
          {
            type: 'button',
            className: 'btn-action ' + (emergencyActive ? 'btn-emergency-active' : 'btn-emergency'),
            onClick: onToggleEmergency,
            disabled: !isDemoMode,
            title: !isDemoMode ? 'Emergency simulation is available in Demo Mode' : 'Toggle simulated emergency ambulance'
          },
          emergencyActive ? 'Deactivate Emergency' : 'Emergency Mode (Demo)'
        )
      ),
      isDemoMode ? createElement(
        'div',
        { className: 'demo-scenarios-panel' },
        createElement('label', { htmlFor: 'scenario-select', className: 'scenario-label' }, 'Demo Traffic Scenario:'),
        createElement(
          'select',
          {
            id: 'scenario-select',
            className: 'scenario-dropdown',
            value: selectedScenarioId || DEMO_SCENARIOS[0].id,
            onChange: function (e) { onSelectScenario(e.target.value); }
          },
          DEMO_SCENARIOS.map(function (s) {
            return createElement('option', { key: s.id, value: s.id }, s.name);
          })
        )
      ) : null,
      createElement(
        'div',
        { className: 'polling-interval-row' },
        createElement(
          'div',
          { className: 'polling-label-group' },
          createElement('span', { className: 'control-helper-title' }, 'Refresh Interval:'),
          createElement('span', { className: 'polling-val-text mono' }, pollingIntervalMs + 'ms')
        ),
        createElement(
          'div',
          { className: 'interval-pills' },
          [500, 1000, 2000].map(function (val) {
            return createElement(
              'button',
              {
                key: val,
                type: 'button',
                className: 'interval-pill ' + (pollingIntervalMs === val ? 'interval-pill-active' : ''),
                onClick: function () { onChangeInterval(val); }
              },
              (val / 1000) + 's'
            );
          })
        )
      ),
      createElement(
        'div',
        { className: 'control-disclaimer-note' },
        createElement('span', { className: 'notice-icon' }, 'ℹ'),
        createElement(
          'span',
          { className: 'notice-text' },
          createElement('strong', null, 'Note: '),
          'Start/Stop controls UI telemetry polling. To run the live vision pipeline, execute ',
          createElement('code', { className: 'code-snippet' }, '.\\.venv\\Scripts\\python.exe main.py'),
          ' in the terminal.'
        )
      ),
      createElement('div', { className: 'control-tagline' }, '“Autonomous AI Signals for Greener, Flowing Cities”')
    );
  }

  function KpiSection(props) {
    var kpis = props.kpis;
    var frameIndex = props.frameIndex;

    return createElement(
      'section',
      { className: 'card kpi-section-card', role: 'region', 'aria-label': 'Key Performance Indicators' },
      createElement(
        'div',
        { className: 'card-header' },
        createElement('h3', { className: 'card-title' }, 'Key Performance Indicators (KPIs)'),
        createElement('span', { className: 'card-subtitle-tag' }, 'SYSTEM TELEMETRY')
      ),
      createElement(
        'div',
        { className: 'kpi-grid' },
        createElement(
          'div',
          { className: 'kpi-card', role: 'article' },
          createElement(
            'div',
            { className: 'kpi-header' },
            createElement('span', { className: 'kpi-bracket' }, '[ TIME ]'),
            createElement('span', { className: 'kpi-name' }, 'Avg Waiting Time'),
            createElement(Tooltip, { content: "Estimated delay based on Webster's queue model for adaptive signals." }, createElement('span', { className: 'info-icon' }, 'ℹ'))
          ),
          createElement('div', { className: 'kpi-value-row' }, createElement('span', { className: 'kpi-number accent-cyan mono' }, kpis.averageWaitTimeSec !== null ? kpis.averageWaitTimeSec.toFixed(1) + ' s' : 'Not available')),
          createElement('div', { className: 'kpi-subtext' }, '*Estimated from queue delay model')
        ),
        createElement(
          'div',
          { className: 'kpi-card', role: 'article' },
          createElement(
            'div',
            { className: 'kpi-header' },
            createElement('span', { className: 'kpi-bracket' }, '[ FLOW ]'),
            createElement('span', { className: 'kpi-name' }, 'Vehicles Detected'),
            createElement(Tooltip, { content: 'Instantaneous incoming vehicle tracks across all 4 corridors from YOLOv8.' }, createElement('span', { className: 'info-icon' }, 'ℹ'))
          ),
          createElement(
            'div',
            { className: 'kpi-value-row' },
            createElement('span', { className: 'kpi-number accent-mint mono' }, kpis.totalVehiclesAvailable ? kpis.totalVehicles : '—'),
            createElement('span', { className: 'kpi-unit' }, 'veh')
          ),
          createElement('div', { className: 'kpi-subtext' }, frameIndex !== null ? 'Live Frame #' + frameIndex : 'Source: Backend State')
        ),
        createElement(
          'div',
          { className: 'kpi-card', role: 'article' },
          createElement(
            'div',
            { className: 'kpi-header' },
            createElement('span', { className: 'kpi-bracket' }, '[ LOAD ]'),
            createElement('span', { className: 'kpi-name' }, 'Congestion Level'),
            createElement(Tooltip, { content: 'Mean traffic density across all 4 approaches relative to 30 vehicle/road capacity.' }, createElement('span', { className: 'info-icon' }, 'ℹ'))
          ),
          createElement('div', { className: 'kpi-value-row' }, createElement('span', { className: 'kpi-number density-text-' + kpis.congestionLevel.toLowerCase() + ' mono' }, kpis.congestionLevel + ' (' + kpis.averageCongestionPct.toFixed(0) + '%)')),
          createElement('div', { className: 'kpi-subtext' }, 'System Mean Density: ' + kpis.averageCongestionPct.toFixed(1) + '%')
        ),
        createElement(
          'div',
          { className: 'kpi-card', role: 'article' },
          createElement(
            'div',
            { className: 'kpi-header' },
            createElement('span', { className: 'kpi-bracket' }, '[ ECO ]'),
            createElement('span', { className: 'kpi-name' }, 'Estimated Fuel Saved'),
            createElement(Tooltip, { content: 'Theoretical fuel savings: ~18% idling reduction compared to fixed-time 60s cycle (assumes 0.8 L/hr idle).' }, createElement('span', { className: 'info-icon' }, 'ℹ'))
          ),
          createElement('div', { className: 'kpi-value-row' }, createElement('span', { className: 'kpi-number accent-mint mono' }, kpis.estimatedFuelSavedLiters !== null ? kpis.estimatedFuelSavedLiters.toFixed(2) + ' L' : '—')),
          createElement('div', { className: 'kpi-subtext' }, '*Estimated reduction vs fixed-time cycle')
        )
      )
    );
  }

  // ================= MAIN APP =================
  function App() {
    var demoState = useState(false);
    var isDemoMode = demoState[0];
    var setIsDemoMode = demoState[1];

    var pollState = useState(true);
    var isPolling = pollState[0];
    var setIsPolling = pollState[1];

    var intervalState = useState(1000);
    var pollingIntervalMs = intervalState[0];
    var setPollingIntervalMs = intervalState[1];

    var scenarioState = useState(DEMO_SCENARIOS[0].id);
    var selectedScenarioId = scenarioState[0];
    var setSelectedScenarioId = scenarioState[1];

    var connState = useState('live');
    var connectionMode = connState[0];
    var setConnectionMode = connState[1];

    var latencyState = useState(0);
    var latencyMs = latencyState[0];
    var setLatencyMs = latencyState[1];

    var errState = useState(0);
    var consecutiveErrors = errState[0];
    var setConsecutiveErrors = errState[1];

    var viewState = useState(function () { return adaptTrafficState({}, false); });
    var viewModel = viewState[0];
    var setViewModel = viewState[1];

    var engineRef = useRef(new MockEngine());
    var lastTimestampRef = useRef(null);
    var staleTimerRef = useRef(0);

    var STATE_ENDPOINTS = [
      '/api/traffic-state',
      '../output/traffic_state.json',
      '/output/traffic_state.json',
      'output/traffic_state.json'
    ];

    var fetchBackendState = useCallback(function () {
      var t0 = performance.now();
      var endpointSuccess = false;
      var foundPayload = null;

      function tryEndpoint(idx) {
        if (idx >= STATE_ENDPOINTS.length) {
          setLatencyMs(Math.round(performance.now() - t0));
          setConsecutiveErrors(function (prev) {
            var n = prev + 1;
            if (n >= 3) setConnectionMode('disconnected');
            return n;
          });
          return Promise.resolve(false);
        }

        var url = STATE_ENDPOINTS[idx];
        return fetch(url, { cache: 'no-store', headers: { 'Accept': 'application/json' } })
          .then(function (res) {
            if (res.ok) return res.json();
            throw new Error('Not ok');
          })
          .then(function (data) {
            foundPayload = data;
            endpointSuccess = true;
            setLatencyMs(Math.round(performance.now() - t0));
            setConsecutiveErrors(0);

            if (data.timestamp && data.timestamp === lastTimestampRef.current) {
              staleTimerRef.current += 1;
              if (staleTimerRef.current >= 4) {
                setConnectionMode('stale');
              } else {
                setConnectionMode('live');
              }
            } else {
              staleTimerRef.current = 0;
              lastTimestampRef.current = data.timestamp || null;
              setConnectionMode('live');
            }

            setViewModel(adaptTrafficState(data, false));
            return true;
          })
          .catch(function () {
            return tryEndpoint(idx + 1);
          });
      }

      return tryEndpoint(0);
    }, [STATE_ENDPOINTS]);

    var tickDemo = useCallback(function () {
      var dt = pollingIntervalMs / 1000;
      var rawDemo = engineRef.current.tick(dt);
      setViewModel(adaptTrafficState(rawDemo, true));
      setConnectionMode('demo');
      setLatencyMs(4);
    }, [pollingIntervalMs]);

    useEffect(function () {
      if (!isPolling) {
        setConnectionMode('paused');
        return;
      }

      var isMounted = true;
      var runCycle = function () {
        if (!isMounted) return;
        if (isDemoMode) {
          tickDemo();
        } else {
          fetchBackendState().then(function (ok) {
            if (!ok && consecutiveErrors > 3 && !viewModel.timestamp) {
              setIsDemoMode(true);
            }
          });
        }
      };

      runCycle();
      var id = window.setInterval(runCycle, pollingIntervalMs);
      return function () {
        isMounted = false;
        window.clearInterval(id);
      };
    }, [isPolling, isDemoMode, pollingIntervalMs, fetchBackendState, tickDemo, consecutiveErrors]);

    var handleTogglePolling = function () { setIsPolling(function (prev) { return !prev; }); };
    var handleReset = function () {
      if (isDemoMode) {
        engineRef.current = new MockEngine();
        tickDemo();
      } else {
        fetchBackendState();
      }
    };

    var handleToggleDemo = function (enable) {
      setIsDemoMode(enable);
      if (enable) {
        engineRef.current = new MockEngine();
        engineRef.current.setScenario(selectedScenarioId);
        tickDemo();
      } else {
        setConsecutiveErrors(0);
        fetchBackendState();
      }
    };

    var handleSelectScenario = function (id) {
      setSelectedScenarioId(id);
      engineRef.current.setScenario(id);
      tickDemo();
    };

    var handleToggleEmergency = function () {
      if (!isDemoMode) return;
      engineRef.current.toggleEmergency('South');
      tickDemo();
    };

    var activeApproachStats = viewModel.selectedGreenRoad ? viewModel.approaches[viewModel.selectedGreenRoad] : undefined;

    return createElement(
      'div',
      { className: 'dashboard-root' },
      createElement(
        'div',
        { className: 'dashboard-content-container' },
        createElement(Header, {
          mode: connectionMode,
          lastUpdated: viewModel.formattedTime,
          frameIndex: viewModel.frameIndex,
          latencyMs: latencyMs,
          isDataSourceDemo: viewModel.isDataSourceDemo,
          onRefresh: fetchBackendState
        }),
        connectionMode === 'stale' ? createElement(
          'div',
          { className: 'alert-strip alert-strip-warning', role: 'alert' },
          createElement('span', { className: 'alert-icon' }, '⚠️'),
          createElement(
            'span',
            null,
            createElement('strong', null, 'Backend Telemetry Stale: '),
            'Values reflect latest frame from ',
            createElement('code', null, 'output/traffic_state.json'),
            '. The detection pipeline (',
            createElement('code', null, 'main.py'),
            ') may have completed or is paused.'
          )
        ) : null,
        connectionMode === 'disconnected' && !isDemoMode ? createElement(
          'div',
          { className: 'alert-strip alert-strip-danger', role: 'alert' },
          createElement('span', { className: 'alert-icon' }, '🔌'),
          createElement(
            'span',
            null,
            createElement('strong', null, 'Backend Bridge Offline: '),
            'Could not read ',
            createElement('code', null, 'output/traffic_state.json'),
            '. Run ',
            createElement('code', null, 'python serve_dashboard.py'),
            ' in terminal or switch to Interactive Demo Mode.'
          ),
          createElement(
            'button',
            { type: 'button', className: 'alert-btn', onClick: function () { handleToggleDemo(true); } },
            'Switch to Demo Mode'
          )
        ) : null,
        createElement(EmergencyBanner, {
          emergencyActive: viewModel.emergencyActive,
          emergencyRoad: viewModel.emergencyRoad,
          emergencyClass: viewModel.emergencyClass,
          isDemoMode: viewModel.isDataSourceDemo
        }),
        createElement(
          'main',
          { className: 'dashboard-main-grid' },
          createElement(
            'section',
            { className: 'dashboard-left-col' },
            createElement(IntersectionView, {
              approaches: viewModel.approaches,
              selectedGreenRoad: viewModel.selectedGreenRoad,
              greenHoldRemaining: viewModel.greenHoldRemaining,
              emergencyActive: viewModel.emergencyActive,
              emergencyRoad: viewModel.emergencyRoad,
              emergencyClass: viewModel.emergencyClass
            })
          ),
          createElement(
            'aside',
            { className: 'dashboard-right-col' },
            createElement(SignalStatusCard, {
              selectedGreenRoad: viewModel.selectedGreenRoad,
              greenHoldRemaining: viewModel.greenHoldRemaining,
              decisionExplanation: viewModel.decisionExplanation,
              decisionIsEstimated: viewModel.decisionIsEstimated,
              activeApproachStats: activeApproachStats,
              emergencyActive: viewModel.emergencyActive,
              emergencyRoad: viewModel.emergencyRoad
            }),
            createElement(ApproachGrid, { approaches: viewModel.approaches }),
            createElement(Controls, {
              mode: connectionMode,
              isPolling: isPolling,
              isDemoMode: isDemoMode,
              selectedScenarioId: selectedScenarioId,
              pollingIntervalMs: pollingIntervalMs,
              emergencyActive: viewModel.emergencyActive,
              onTogglePolling: handleTogglePolling,
              onReset: handleReset,
              onToggleDemoMode: handleToggleDemo,
              onSelectScenario: handleSelectScenario,
              onToggleEmergencySimulation: handleToggleEmergency,
              onChangePollingInterval: function (val) { setPollingIntervalMs(val); }
            })
          )
        ),
        createElement(KpiSection, { kpis: viewModel.kpis, frameIndex: viewModel.frameIndex }),
        createElement(
          'footer',
          { className: 'dashboard-footer', role: 'contentinfo' },
          createElement(
            'div',
            { className: 'footer-disclaimer-card' },
            createElement(
              'div',
              { className: 'footer-title-row' },
              createElement('span', { className: 'disclaimer-shield' }, '🛡'),
              createElement('span', { className: 'disclaimer-heading' }, 'VegMitra Academic Research & Simulation System')
            ),
            createElement(
              'p',
              { className: 'disclaimer-text' },
              'This dashboard is a simulation and visual telemetry interface for the B.Tech Computer Science project ',
              createElement('strong', null, 'VegMitra (AI-Based Adaptive Traffic Signal Management System)'),
              '. Telemetry is sourced from YOLOv8 object detection on camera feeds, processed via BoTSORT tracking and algorithmic signal scheduling. It is designed exclusively for evaluation and academic demonstration purposes and is not connected to physical municipal traffic equipment.'
            )
          )
        )
      )
    );
  }

  // Mount Application
  var rootEl = document.getElementById('root');
  if (rootEl) {
    var root = ReactDOM.createRoot(rootEl);
    root.render(createElement(React.StrictMode, null, createElement(App, null)));
  }
})();
