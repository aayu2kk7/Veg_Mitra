import React from 'react';
import { RoadName, ApproachStats } from '../types/traffic';

interface IntersectionViewProps {
  approaches: Record<RoadName, ApproachStats>;
  selectedGreenRoad: RoadName | null;
  greenHoldRemaining: number;
  emergencyActive: boolean;
  emergencyRoad: string | null;
  emergencyClass: string | null;
}

export const IntersectionView: React.FC<IntersectionViewProps> = ({
  approaches,
  selectedGreenRoad,
  greenHoldRemaining,
  emergencyActive,
  emergencyRoad,
  emergencyClass
}) => {
  // Helper to determine signal light state
  const getSignalAspect = (road: RoadName) => {
    const isSelected = selectedGreenRoad === road;
    if (isSelected) {
      if (greenHoldRemaining > 0 && greenHoldRemaining <= 0.8) {
        return 'AMBER';
      }
      return 'GREEN';
    }
    return 'RED';
  };

  // Generate vehicle representation coordinates for each road approach
  const renderVehiclesForRoad = (road: RoadName, count: number) => {
    const isEmergencyOnThisRoad = emergencyActive && emergencyRoad?.toLowerCase() === road.toLowerCase();
    const clampedCount = Math.min(count, 8); // Display up to 8 visual markers per road
    const vehicles = [];

    // Lane positioning configuration for 600x600 SVG coordinate system
    // Center is (300, 300). Road width is 120 (from 240 to 360)
    for (let i = 0; i < clampedCount; i++) {
      const isAmbulance = isEmergencyOnThisRoad && i === 0;
      let x = 0;
      let y = 0;
      let rot = 0;

      if (road === 'North') {
        // Inbound lane is on the left side of North road (x: 270)
        x = 270;
        y = 70 + i * 26;
        rot = 180; // Facing down toward intersection
      } else if (road === 'South') {
        // Inbound lane is on the right side of South road (x: 330)
        x = 330;
        y = 530 - i * 26;
        rot = 0; // Facing up toward intersection
      } else if (road === 'East') {
        // Inbound lane is on the top side of East road (y: 270)
        x = 530 - i * 26;
        y = 270;
        rot = 270; // Facing left toward intersection
      } else if (road === 'West') {
        // Inbound lane is on the bottom side of West road (y: 330)
        x = 70 + i * 26;
        y = 330;
        rot = 90; // Facing right toward intersection
      }

      vehicles.push(
        <g 
          key={`${road}-veh-${i}`} 
          transform={`translate(${x}, ${y}) rotate(${rot})`}
          className={isAmbulance ? 'vehicle-emergency-pulse' : 'vehicle-icon'}
        >
          {isAmbulance ? (
            // Ambulance sprite
            <g>
              <rect x="-10" y="-18" width="20" height="36" rx="4" fill="#ffffff" stroke="#ef4444" strokeWidth="2" />
              <rect x="-7" y="-15" width="14" height="8" rx="2" fill="#38bdf8" />
              <rect x="-8" y="2" width="16" height="5" fill="#ef4444" />
              <rect x="-2.5" y="-3" width="5" height="15" fill="#ef4444" />
              {/* Flashing light */}
              <circle cx="0" cy="-6" r="4" fill="#ef4444" className="siren-beacon" />
            </g>
          ) : (
            // Passenger Car / Bus sprite
            <g>
              <rect 
                x="-8" 
                y="-14" 
                width="16" 
                height="28" 
                rx="3.5" 
                fill={i % 3 === 0 ? '#38bdf8' : i % 2 === 0 ? '#fbbf24' : '#f87171'} 
                stroke="#0f172a" 
                strokeWidth="1.5" 
              />
              {/* Windshields */}
              <rect x="-6" y="-10" width="12" height="6" rx="1.5" fill="#0f172a" />
              <rect x="-6" y="4" width="12" height="5" rx="1.5" fill="#0f172a" />
              {/* Headlights */}
              <circle cx="-5" cy="-13" r="1.5" fill="#fef08a" />
              <circle cx="5" cy="-13" r="1.5" fill="#fef08a" />
            </g>
          )}
        </g>
      );
    }

    return vehicles;
  };

  // Render 3-aspect traffic light head
  const renderSignalHead = (road: RoadName, x: number, y: number, label: string) => {
    const aspect = getSignalAspect(road);
    const isGreen = aspect === 'GREEN';
    const isAmber = aspect === 'AMBER';
    const isRed = aspect === 'RED';

    return (
      <g className="traffic-signal-head" transform={`translate(${x}, ${y})`}>
        {/* Signal Housing */}
        <rect 
          x="-14" 
          y="-36" 
          width="28" 
          height="72" 
          rx="6" 
          fill="#0c1322" 
          stroke={isGreen ? '#10b981' : '#23334d'} 
          strokeWidth={isGreen ? '2.5' : '1.5'} 
          className={isGreen ? 'signal-housing-active' : ''}
        />
        {/* Road approach identifier badge */}
        <rect x="-11" y="-50" width="22" height="12" rx="3" fill="#1e293b" />
        <text x="0" y="-41" textAnchor="middle" fill="#94a3b8" fontSize="9" fontWeight="700">
          {label}
        </text>

        {/* RED lamp */}
        <circle 
          cx="0" 
          cy="-22" 
          r="8" 
          fill={isRed ? '#ef4444' : '#331215'} 
          stroke={isRed ? '#fca5a5' : '#1e293b'} 
          strokeWidth="1"
          className={isRed ? 'lamp-glow-red' : ''}
        />
        {isRed && (
          <text x="0" y="-19.5" textAnchor="middle" fill="#ffffff" fontSize="7" fontWeight="900">
            STOP
          </text>
        )}

        {/* AMBER lamp */}
        <circle 
          cx="0" 
          cy="0" 
          r="8" 
          fill={isAmber ? '#f59e0b' : '#33240d'} 
          stroke={isAmber ? '#fde68a' : '#1e293b'} 
          strokeWidth="1"
          className={isAmber ? 'lamp-glow-amber' : ''}
        />

        {/* GREEN lamp */}
        <circle 
          cx="0" 
          cy="22" 
          r="8" 
          fill={isGreen ? '#10b981' : '#072e21'} 
          stroke={isGreen ? '#6ee7b7' : '#1e293b'} 
          strokeWidth="1"
          className={isGreen ? 'lamp-glow-green' : ''}
        />
        {isGreen && (
          <text x="0" y="24.5" textAnchor="middle" fill="#ffffff" fontSize="7" fontWeight="900">
            GO
          </text>
        )}
      </g>
    );
  };

  return (
    <div className="intersection-container" role="region" aria-label="Intersection Traffic Simulation Map">
      <div className="intersection-header-bar">
        <div className="simulation-title-wrap">
          <span className="live-camera-tag">INTERSECTION OVERVIEW</span>
          <h2 className="simulation-title">Smart City Autonomous Intersection</h2>
        </div>

        <div className="active-signal-banner">
          <span className="signal-lead-label">ACTIVE GREEN:</span>
          {selectedGreenRoad ? (
            <span className="signal-active-pill">
              <span className="road-highlight-text">{selectedGreenRoad.toUpperCase()} APPROACH</span>
              <span className="hold-pill-timer">[{greenHoldRemaining.toFixed(1)}s hold]</span>
            </span>
          ) : (
            <span className="signal-standby-pill">INITIALIZING...</span>
          )}
        </div>
      </div>

      <div className="svg-canvas-wrapper">
        <svg 
          viewBox="0 0 600 600" 
          className="intersection-svg"
          preserveAspectRatio="xMidYMid meet"
          role="img"
          aria-label="Top-down visual map of the four-way intersection showing North, South, East, and West corridors"
        >
          <defs>
            {/* Subtle city grid pattern */}
            <pattern id="cityGrid" width="20" height="20" patternUnits="userSpaceOnUse">
              <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#141c2e" strokeWidth="0.8" />
            </pattern>
            {/* Box junction diagonal hatching */}
            <pattern id="boxJunctionGrid" width="16" height="16" patternUnits="userSpaceOnUse">
              <path d="M 0 0 L 16 16 M 16 0 L 0 16" fill="none" stroke="#f59e0b" strokeWidth="1.2" opacity="0.85" />
            </pattern>
          </defs>

          {/* Background ground terrain */}
          <rect width="600" height="600" fill="#090d16" />
          <rect width="600" height="600" fill="url(#cityGrid)" opacity="0.6" />

          {/* ================= SMART CITY QUADRANTS ================= */}
          {/* Top-Left: COMMERCE CENTER */}
          <g className="building-block">
            <rect x="25" y="25" width="195" height="195" rx="6" fill="#0e1726" stroke="#1d2e4a" strokeWidth="1.5" />
            <rect x="45" y="45" width="155" height="115" fill="#09101c" stroke="#0284c7" strokeWidth="1" strokeDasharray="3 3" />
            {/* Grid windows */}
            <line x1="96" y1="45" x2="96" y2="160" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            <line x1="147" y1="45" x2="147" y2="160" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            <line x1="45" y1="83" x2="200" y2="83" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            <line x1="45" y1="121" x2="200" y2="121" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            <rect x="55" y="175" width="135" height="28" rx="4" fill="#132138" stroke="#1e3458" strokeWidth="1" />
            <text x="122" y="193" textAnchor="middle" fill="#93c5fd" fontSize="10" fontWeight="700" letterSpacing="0.8">
              COMMERCE CENTER
            </text>
          </g>

          {/* Top-Right: INNOVATION HUB with Helipad */}
          <g className="building-block">
            <rect x="380" y="25" width="195" height="195" rx="6" fill="#0e1726" stroke="#1d2e4a" strokeWidth="1.5" />
            <rect x="400" y="45" width="95" height="115" fill="#09101c" stroke="#0284c7" strokeWidth="1" strokeDasharray="3 3" />
            <line x1="447" y1="45" x2="447" y2="160" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            <line x1="400" y1="102" x2="495" y2="102" stroke="#0284c7" strokeWidth="0.8" strokeDasharray="2 2" />
            {/* Helipad */}
            <circle cx="530" cy="100" r="32" fill="#0b1320" stroke="#f59e0b" strokeWidth="2.5" />
            <circle cx="530" cy="100" r="28" fill="none" stroke="#f59e0b" strokeWidth="1" strokeDasharray="4 4" />
            <text x="530" y="108" textAnchor="middle" fill="#f59e0b" fontSize="22" fontWeight="900">H</text>
            <rect x="410" y="175" width="135" height="28" rx="4" fill="#132138" stroke="#1e3458" strokeWidth="1" />
            <text x="477" y="193" textAnchor="middle" fill="#93c5fd" fontSize="10" fontWeight="700" letterSpacing="0.8">
              INNOVATION HUB
            </text>
          </g>

          {/* Bottom-Left: METRO CIVIC COMPLEX */}
          <g className="building-block">
            <rect x="25" y="380" width="195" height="195" rx="6" fill="#0e1726" stroke="#1d2e4a" strokeWidth="1.5" />
            <rect x="45" y="400" width="115" height="95" fill="#09101c" stroke="#10b981" strokeWidth="1.2" />
            <rect x="165" y="420" width="40" height="75" fill="#121b29" stroke="#1e2d42" />
            <rect x="45" y="515" width="155" height="28" rx="4" fill="#132138" stroke="#1e3458" strokeWidth="1" />
            <text x="122" y="533" textAnchor="middle" fill="#93c5fd" fontSize="10" fontWeight="700" letterSpacing="0.8">
              METRO CIVIC COMPLEX
            </text>
          </g>

          {/* Bottom-Right: ECO-TECH CAMPUS with Green Spaces */}
          <g className="building-block">
            <rect x="380" y="380" width="195" height="195" rx="6" fill="#0e1726" stroke="#1d2e4a" strokeWidth="1.5" />
            <rect x="400" y="400" width="155" height="105" fill="#061c14" stroke="#059669" strokeWidth="1.2" />
            {/* Park trees landscape */}
            <circle cx="430" cy="430" r="14" fill="#047857" opacity="0.9" />
            <circle cx="465" cy="445" r="16" fill="#059669" opacity="0.9" />
            <circle cx="510" cy="435" r="15" fill="#10b981" opacity="0.85" />
            <circle cx="445" cy="475" r="14" fill="#047857" opacity="0.9" />
            <circle cx="490" cy="475" r="17" fill="#059669" opacity="0.9" />
            <rect x="400" y="525" width="155" height="28" rx="4" fill="#132138" stroke="#1e3458" strokeWidth="1" />
            <text x="477" y="543" textAnchor="middle" fill="#6ee7b7" fontSize="10" fontWeight="700" letterSpacing="0.8">
              ECO-TECH CAMPUS
            </text>
          </g>

          {/* ================= ROAD ASPHALT INFRASTRUCTURE ================= */}
          {/* North-South Road Corridor */}
          <rect x="235" y="0" width="130" height="600" fill="#161c28" />
          {/* East-West Road Corridor */}
          <rect x="0" y="235" width="600" height="130" fill="#161c28" />

          {/* Active Road Highlight Corridor Glow */}
          {selectedGreenRoad === 'North' && (
            <rect x="237" y="0" width="126" height="235" fill="none" stroke="#10b981" strokeWidth="3" className="active-corridor-glow" />
          )}
          {selectedGreenRoad === 'South' && (
            <rect x="237" y="365" width="126" height="235" fill="none" stroke="#10b981" strokeWidth="3" className="active-corridor-glow" />
          )}
          {selectedGreenRoad === 'East' && (
            <rect x="365" y="237" width="235" height="126" fill="none" stroke="#10b981" strokeWidth="3" className="active-corridor-glow" />
          )}
          {selectedGreenRoad === 'West' && (
            <rect x="0" y="237" width="235" height="126" fill="none" stroke="#10b981" strokeWidth="3" className="active-corridor-glow" />
          )}

          {/* Curbs / Sidewalk Edges */}
          <line x1="235" y1="0" x2="235" y2="235" stroke="#334155" strokeWidth="3" />
          <line x1="365" y1="0" x2="365" y2="235" stroke="#334155" strokeWidth="3" />
          <line x1="235" y1="365" x2="235" y2="600" stroke="#334155" strokeWidth="3" />
          <line x1="365" y1="365" x2="365" y2="600" stroke="#334155" strokeWidth="3" />
          <line x1="0" y1="235" x2="235" y2="235" stroke="#334155" strokeWidth="3" />
          <line x1="0" y1="365" x2="235" y2="365" stroke="#334155" strokeWidth="3" />
          <line x1="365" y1="235" x2="600" y2="235" stroke="#334155" strokeWidth="3" />
          <line x1="365" y1="365" x2="600" y2="365" stroke="#334155" strokeWidth="3" />

          {/* Yellow Dashed Center Lane Dividers */}
          <line x1="300" y1="0" x2="300" y2="225" stroke="#f59e0b" strokeWidth="2.5" strokeDasharray="10 8" />
          <line x1="300" y1="375" x2="300" y2="600" stroke="#f59e0b" strokeWidth="2.5" strokeDasharray="10 8" />
          <line x1="0" y1="300" x2="225" y2="300" stroke="#f59e0b" strokeWidth="2.5" strokeDasharray="10 8" />
          <line x1="375" y1="300" x2="600" y2="300" stroke="#f59e0b" strokeWidth="2.5" strokeDasharray="10 8" />

          {/* Directional Corridor Labels on Roads */}
          <text x="300" y="24" textAnchor="middle" fill="#64748b" fontSize="11" fontWeight="800" letterSpacing="1">
            NORTH CORRIDOR
          </text>
          <text x="300" y="585" textAnchor="middle" fill="#64748b" fontSize="11" fontWeight="800" letterSpacing="1">
            SOUTH CORRIDOR
          </text>
          <text x="540" y="304" textAnchor="middle" fill="#64748b" fontSize="11" fontWeight="800" letterSpacing="1">
            EAST &gt;&gt;
          </text>
          <text x="60" y="304" textAnchor="middle" fill="#64748b" fontSize="11" fontWeight="800" letterSpacing="1">
            &lt;&lt; WEST
          </text>

          {/* ================= PEDESTRIAN CROSSINGS (ZEBRA STRIPES) ================= */}
          {/* North Crosswalk */}
          <g className="crosswalk-stripes">
            {[240, 252, 264, 276, 288, 300, 312, 324, 336, 348].map((xp, idx) => (
              <rect key={`cw-n-${idx}`} x={xp} y="226" width="7" height="12" fill="#f8fafc" opacity="0.9" />
            ))}
          </g>
          {/* South Crosswalk */}
          <g className="crosswalk-stripes">
            {[240, 252, 264, 276, 288, 300, 312, 324, 336, 348].map((xp, idx) => (
              <rect key={`cw-s-${idx}`} x={xp} y="362" width="7" height="12" fill="#f8fafc" opacity="0.9" />
            ))}
          </g>
          {/* West Crosswalk */}
          <g className="crosswalk-stripes">
            {[240, 252, 264, 276, 288, 300, 312, 324, 336, 348].map((yp, idx) => (
              <rect key={`cw-w-${idx}`} x="226" y={yp} width="12" height="7" fill="#f8fafc" opacity="0.9" />
            ))}
          </g>
          {/* East Crosswalk */}
          <g className="crosswalk-stripes">
            {[240, 252, 264, 276, 288, 300, 312, 324, 336, 348].map((yp, idx) => (
              <rect key={`cw-e-${idx}`} x="362" y={yp} width="12" height="7" fill="#f8fafc" opacity="0.9" />
            ))}
          </g>

          {/* ================= CENTRAL YELLOW BOX JUNCTION ================= */}
          <rect 
            x="240" 
            y="240" 
            width="120" 
            height="120" 
            fill="#121824" 
            stroke="#f59e0b" 
            strokeWidth="2.5" 
          />
          <rect 
            x="240" 
            y="240" 
            width="120" 
            height="120" 
            fill="url(#boxJunctionGrid)" 
          />

          {/* Cross lines in central junction */}
          <line x1="240" y1="240" x2="360" y2="360" stroke="#f59e0b" strokeWidth="1.5" opacity="0.9" />
          <line x1="360" y1="240" x2="240" y2="360" stroke="#f59e0b" strokeWidth="1.5" opacity="0.9" />

          {/* ================= VEHICLE MARKERS ================= */}
          <g className="vehicles-layer">
            {renderVehiclesForRoad('North', approaches.North?.count ?? 0)}
            {renderVehiclesForRoad('South', approaches.South?.count ?? 0)}
            {renderVehiclesForRoad('East', approaches.East?.count ?? 0)}
            {renderVehiclesForRoad('West', approaches.West?.count ?? 0)}
          </g>

          {/* ================= 4-WAY TRAFFIC SIGNAL HEADS ================= */}
          {/* North Signal Head (Top right of North approach) */}
          {renderSignalHead('North', 218, 195, 'N')}

          {/* South Signal Head (Bottom left of South approach) */}
          {renderSignalHead('South', 382, 405, 'S')}

          {/* East Signal Head (Top right of East approach) */}
          {renderSignalHead('East', 405, 218, 'E')}

          {/* West Signal Head (Bottom left of West approach) */}
          {renderSignalHead('West', 195, 382, 'W')}

          {/* Central Intersection Center Point Marker */}
          <circle cx="300" cy="300" r="4" fill="#f59e0b" />
        </svg>
      </div>

      <div className="intersection-caption-bar">
        <span className="caption-text">
          4-Road Intersection | Real-Time Vehicle Movement &amp; Smart City Environment
        </span>
        <span className="legend-pills">
          <span className="legend-item"><span className="legend-dot green"></span> GREEN: Active Go</span>
          <span className="legend-item"><span className="legend-dot red"></span> RED: Stopped</span>
          {emergencyActive && <span className="legend-item alert"><span className="legend-dot amber"></span> EMERGENCY PRIORITY</span>}
        </span>
      </div>
    </div>
  );
};
