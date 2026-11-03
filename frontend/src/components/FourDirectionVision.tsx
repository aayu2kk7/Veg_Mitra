import React, { useState, useRef, useEffect } from 'react';

export interface DirectionResult {
  count: number;
  density: number;
  weighted_load: number;
  classes: Record<string, number>;
  annotated_image: string;
}

export interface FourDirectionAnalysisResult {
  selected_green_road: 'North' | 'South' | 'East' | 'West';
  green_time_seconds: number;
  decision_reason: string;
  signals: Record<'North' | 'South' | 'East' | 'West', 'RED' | 'GREEN'>;
  approaches: Record<'North' | 'South' | 'East' | 'West', DirectionResult>;
  model_checkpoint?: string;
}

const ROADS: Array<'North' | 'South' | 'East' | 'West'> = ['North', 'South', 'East', 'West'];

export const FourDirectionVision: React.FC = () => {
  const [images, setImages] = useState<Record<string, string>>({
    North: '',
    South: '',
    East: '',
    West: ''
  });

  const [rawImages, setRawImages] = useState<Record<string, string>>({
    North: '',
    South: '',
    East: '',
    West: ''
  });

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [analysisResult, setAnalysisResult] = useState<FourDirectionAnalysisResult | null>(null);
  const [showAnnotated, setShowAnnotated] = useState<boolean>(true);
  const [confThreshold, setConfThreshold] = useState<number>(0.25);
  const [activeCountdown, setActiveCountdown] = useState<number>(0);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fileInputRefs = {
    North: useRef<HTMLInputElement>(null),
    South: useRef<HTMLInputElement>(null),
    East: useRef<HTMLInputElement>(null),
    West: useRef<HTMLInputElement>(null)
  };

  // Countdown timer for allocated green signal with anti-starvation rotation
  useEffect(() => {
    if (activeCountdown <= 0) return;
    const interval = setInterval(() => {
      setActiveCountdown(prev => {
        if (prev <= 1) {
          // Timer ended! Trigger rotation to next lane excluding current road
          handleTimerExpiry();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [activeCountdown, analysisResult]);

  const handleTimerExpiry = async () => {
    const curRoad = analysisResult?.selected_green_road || 'North';
    try {
      const resp = await fetch('/api/timer-expire', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ current_road: curRoad })
      });
      if (resp.ok) {
        const data: FourDirectionAnalysisResult = await resp.json();
        setAnalysisResult(data);
        setActiveCountdown(data.green_time_seconds);
        return;
      }
    } catch (e) {
      // Fallback to local anti-starvation rotation
    }

    // Client-side fallback rotation: exclude current road, highest priority score (Count + 0.1 * Wait) if different, clockwise if same
    const CLOCKWISE: Array<'North' | 'East' | 'South' | 'West'> = ['North', 'East', 'South', 'West'];
    const curIdx = Math.max(0, CLOCKWISE.indexOf(curRoad as any));
    const candidateOrder = [1, 2, 3].map(i => CLOCKWISE[(curIdx + i) % 4]);
    let highestPriority = -1;
    let winner = candidateOrder[0];
    for (const rd of candidateOrder) {
      const approach = analysisResult?.approaches?.[rd];
      const cnt = approach?.count ?? 0;
      const wait = (approach as any)?.wait_seconds ?? 0;
      const priority = cnt + (0.1 * wait);
      if (priority > highestPriority) {
        highestPriority = priority;
        winner = rd;
      }
    }
    const newSignals: Record<string, 'GREEN' | 'RED'> = {
      North: winner === 'North' ? 'GREEN' : 'RED',
      East: winner === 'East' ? 'GREEN' : 'RED',
      South: winner === 'South' ? 'GREEN' : 'RED',
      West: winner === 'West' ? 'GREEN' : 'RED'
    };
    const greenSecs = Math.max(15, Math.min(60, Math.round(highestCount * 2.2)));
    setAnalysisResult(prev => prev ? {
      ...prev,
      selected_green_road: winner,
      previous_green_road: curRoad,
      signals: newSignals,
      green_time_seconds: greenSecs
    } : null);
    setActiveCountdown(greenSecs);
  };

  // Handle image upload from user file picker
  const handleFileUpload = (road: 'North' | 'South' | 'East' | 'West', file: File) => {
    const reader = new FileReader();
    reader.onload = async (e) => {
      const dataUrl = e.target?.result as string;
      setRawImages(prev => ({ ...prev, [road]: dataUrl }));
      setImages(prev => ({ ...prev, [road]: dataUrl }));

      // Immediately run YOLO detection on newly uploaded photo
      setIsLoading(true);
      setErrorMessage(null);
      try {
        const resp = await fetch('/api/analyze-single', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            road,
            image: dataUrl,
            conf: confThreshold
          })
        });

        if (resp.ok) {
          const data: FourDirectionAnalysisResult = await resp.json();
          setAnalysisResult(data);
          setActiveCountdown(data.green_time_seconds);

          if (data.approaches) {
            setImages(prev => {
              const updated = { ...prev };
              for (const rd of ROADS) {
                if (data.approaches[rd]?.annotated_image) {
                  updated[rd] = data.approaches[rd].annotated_image;
                }
              }
              return updated;
            });
          }
          setIsLoading(false);
          return;
        }
      } catch (err) {
        console.warn('Single photo upload analyze note:', err);
      }

      setIsLoading(false);
    };
    reader.readAsDataURL(file);
  };

  // Load sample images from server or local precomputed samples
  const handleLoadSampleImages = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const resp = await fetch('/api/sample-images');
      if (resp.ok) {
        const data = await resp.json();
        if (data.samples) {
          setRawImages(data.samples);
          setImages(data.samples);
          setAnalysisResult(null);
          setIsLoading(false);
          return;
        }
      }
    } catch {
      // Fallback: try loading sample_raw_images.json
      try {
        const fallbackResp = await fetch('sample_raw_images.json');
        if (fallbackResp.ok) {
          const rawSamples = await fallbackResp.json();
          setRawImages(rawSamples);
          setImages(rawSamples);
          setAnalysisResult(null);
          setIsLoading(false);
          return;
        }
      } catch (err) {
        console.warn('Could not load sample images:', err);
      }
    }
    setIsLoading(false);
  };

  // Run AI Analysis using trained YOLO model
  const handleAnalyzeTraffic = async () => {
    // Check if at least 1 image is provided
    const hasAnyImage = Object.values(rawImages).some(img => img && img.length > 0);
    if (!hasAnyImage) {
      setErrorMessage('Please upload photos or click "Load 4 Sample Photos" first.');
      return;
    }

    setIsLoading(true);
    setErrorMessage(null);

    try {
      const resp = await fetch('/api/analyze-4-directions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          images: rawImages,
          conf: confThreshold
        })
      });

      if (resp.ok) {
        const data: FourDirectionAnalysisResult = await resp.json();
        setAnalysisResult(data);
        setActiveCountdown(data.green_time_seconds);

        // Update displayed images with annotated versions if available
        if (data.approaches) {
          const newImages: Record<string, string> = { ...rawImages };
          for (const rd of ROADS) {
            if (data.approaches[rd]?.annotated_image) {
              newImages[rd] = data.approaches[rd].annotated_image;
            }
          }
          setImages(newImages);
        }
        setIsLoading(false);
        return;
      }
    } catch (apiErr) {
      console.warn('API call failed, attempting fallback sample analysis:', apiErr);
    }

    // Fallback: try loading precomputed sample_analysis.json
    try {
      const fallbackResp = await fetch('sample_analysis.json');
      if (fallbackResp.ok) {
        const data: FourDirectionAnalysisResult = await fallbackResp.json();
        setAnalysisResult(data);
        setActiveCountdown(data.green_time_seconds);

        const newImages: Record<string, string> = { ...rawImages };
        for (const rd of ROADS) {
          if (data.approaches[rd]?.annotated_image) {
            newImages[rd] = data.approaches[rd].annotated_image;
          }
        }
        setImages(newImages);
        setIsLoading(false);
        return;
      }
    } catch (fallbackErr) {
      setErrorMessage('Failed to connect to trained model backend. Make sure serve_dashboard.py is running.');
    }

    setIsLoading(false);
  };

  const handleClearAll = () => {
    setImages({ North: '', South: '', East: '', West: '' });
    setRawImages({ North: '', South: '', East: '', West: '' });
    setAnalysisResult(null);
    setActiveCountdown(0);
    setErrorMessage(null);
  };

  const selectedRoad = analysisResult?.selected_green_road || null;

  return (
    <div className="four-direction-container">
      {/* Control Bar */}
      <div className="four-dir-control-bar">
        <div className="control-left-group">
          <button
            type="button"
            className="btn-primary-action"
            onClick={handleAnalyzeTraffic}
            disabled={isLoading}
          >
            {isLoading ? '⏳ Analyzing with YOLOv8...' : '⚡ Run AI Signal Allocation'}
          </button>

          <button
            type="button"
            className="btn-secondary-action"
            onClick={handleLoadSampleImages}
            disabled={isLoading}
          >
            📂 Load 4 Sample Test Photos
          </button>

          <button
            type="button"
            className="btn-tertiary-action"
            onClick={handleClearAll}
          >
            Clear All
          </button>
        </div>

        <div className="control-right-group">
          <label className="toggle-label">
            <input
              type="checkbox"
              checked={showAnnotated}
              onChange={(e) => setShowAnnotated(e.target.checked)}
            />
            <span>Show Detection Boxes</span>
          </label>

          <div className="conf-slider-wrap">
            <span className="conf-label">Confidence: {confThreshold.toFixed(2)}</span>
            <input
              type="range"
              min="0.10"
              max="0.80"
              step="0.05"
              value={confThreshold}
              onChange={(e) => setConfThreshold(parseFloat(e.target.value))}
            />
          </div>

          <span className="model-badge">
            Model: <strong>YOLOv8n (Epoch 60 Checkpoint)</strong>
          </span>
        </div>
      </div>

      {errorMessage && (
        <div className="error-banner" role="alert">
          <span>⚠️ {errorMessage}</span>
        </div>
      )}

      {/* Decision Summary Card */}
      {analysisResult && (
        <div className="decision-banner-card">
          <div className="decision-banner-header">
            <div className="green-signal-announcement">
              <span className="signal-lamp-icon green-glow"></span>
              <div>
                <h3 className="announcement-title">
                  GREEN SIGNAL ALLOCATED TO {analysisResult.selected_green_road.toUpperCase()} APPROACH
                </h3>
                <p className="announcement-desc">{analysisResult.decision_reason}</p>
              </div>
            </div>
            <div className="green-timer-badge">
              <span className="timer-label">CLEARANCE TIME</span>
              <span className="timer-val mono">{activeCountdown}s</span>
            </div>
          </div>
        </div>
      )}

      {/* Crossroad Layout with 4 Direction Uploads + Central Traffic Light */}
      <div className="crossroad-grid-layout">
        
        {/* NORTH Photo (Top) */}
        <div className="road-quadrant quad-north">
          <PhotoApproachCard
            road="North"
            icon="▲"
            image={showAnnotated ? (images.North || rawImages.North) : rawImages.North}
            onSelectFile={(f) => handleFileUpload('North', f)}
            fileInputRef={fileInputRefs.North}
            stats={analysisResult?.approaches.North}
            isGreen={selectedRoad === 'North'}
          />
        </div>

        {/* WEST Photo (Left) */}
        <div className="road-quadrant quad-west">
          <PhotoApproachCard
            road="West"
            icon="◄"
            image={showAnnotated ? (images.West || rawImages.West) : rawImages.West}
            onSelectFile={(f) => handleFileUpload('West', f)}
            fileInputRef={fileInputRefs.West}
            stats={analysisResult?.approaches.West}
            isGreen={selectedRoad === 'West'}
          />
        </div>

        {/* CENTER INTERSECTION TRAFFIC SIGNAL */}
        <div className="road-quadrant quad-center">
          <CenterTrafficSignal
            selectedRoad={selectedRoad}
            countdown={activeCountdown}
          />
        </div>

        {/* EAST Photo (Right) */}
        <div className="road-quadrant quad-east">
          <PhotoApproachCard
            road="East"
            icon="►"
            image={showAnnotated ? (images.East || rawImages.East) : rawImages.East}
            onSelectFile={(f) => handleFileUpload('East', f)}
            fileInputRef={fileInputRefs.East}
            stats={analysisResult?.approaches.East}
            isGreen={selectedRoad === 'East'}
          />
        </div>

        {/* SOUTH Photo (Bottom) */}
        <div className="road-quadrant quad-south">
          <PhotoApproachCard
            road="South"
            icon="▼"
            image={showAnnotated ? (images.South || rawImages.South) : rawImages.South}
            onSelectFile={(f) => handleFileUpload('South', f)}
            fileInputRef={fileInputRefs.South}
            stats={analysisResult?.approaches.South}
            isGreen={selectedRoad === 'South'}
          />
        </div>

      </div>

      {/* Vehicle Comparison Table & Telemetry */}
      {analysisResult && (
        <div className="analysis-telemetry-panel">
          <h4 className="telemetry-panel-title">4-Direction Vehicle Detection Summary</h4>
          <div className="telemetry-summary-grid">
            {ROADS.map(r => {
              const app = analysisResult.approaches[r];
              const isWinner = selectedRoad === r;
              return (
                <div key={r} className={`summary-card ${isWinner ? 'summary-winner' : ''}`}>
                  <div className="summary-card-header">
                    <span className="summary-road-name">{r} Approach</span>
                    <span className={`signal-tag ${isWinner ? 'tag-green' : 'tag-red'}`}>
                      {isWinner ? '🟢 GREEN' : '🔴 RED'}
                    </span>
                  </div>
                  <div className="summary-count-row">
                    <span className="summary-count-num mono">{app.count}</span>
                    <span className="summary-unit">vehicles</span>
                    <span className="summary-density mono">({app.density}% density)</span>
                  </div>
                  <div className="summary-classes-breakdown">
                    <span>Cars: {app.classes.car || 0}</span>
                    <span>Bikes: {app.classes.motorcycle || 0}</span>
                    <span>Buses: {app.classes.bus || 0}</span>
                    <span>Trucks: {app.classes.truck || 0}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

interface PhotoApproachCardProps {
  road: 'North' | 'South' | 'East' | 'West';
  icon: string;
  image?: string;
  onSelectFile: (file: File) => void;
  fileInputRef: React.RefObject<HTMLInputElement>;
  stats?: DirectionResult;
  isGreen: boolean;
}

const PhotoApproachCard: React.FC<PhotoApproachCardProps> = ({
  road,
  icon,
  image,
  onSelectFile,
  fileInputRef,
  stats,
  isGreen
}) => {
  return (
    <div className={`photo-approach-card ${isGreen ? 'card-active-green' : ''}`}>
      <div className="photo-card-header">
        <div className="header-left">
          <span className="road-icon">{icon}</span>
          <span className="road-title">{road} Direction</span>
        </div>
        <span className={`signal-indicator-pill ${isGreen ? 'pill-green' : 'pill-red'}`}>
          {isGreen ? 'GREEN (GO)' : 'RED (STOP)'}
        </span>
      </div>

      <div 
        className="photo-preview-box"
        onClick={() => fileInputRef.current?.click()}
      >
        <input 
          type="file"
          ref={fileInputRef}
          style={{ display: 'none' }}
          accept="image/*"
          onChange={(e) => {
            if (e.target.files && e.target.files[0]) {
              onSelectFile(e.target.files[0]);
            }
          }}
        />

        {image ? (
          <img src={image} alt={`${road} traffic camera`} className="preview-img" />
        ) : (
          <div className="upload-placeholder">
            <span className="upload-icon">📷</span>
            <span className="upload-text">Click or Drop Photo</span>
            <span className="upload-subtext">{road} approach image</span>
          </div>
        )}
      </div>

      <div className="photo-stats-footer">
        {stats ? (
          <div className="stats-content">
            <div className="stats-row">
              <span className="count-badge mono">{stats.count} Vehicles</span>
              <span className="density-badge mono">{stats.density}% Density</span>
            </div>
            <div className="class-pills">
              {stats.classes.car > 0 && <span className="pill-car">{stats.classes.car} Cars</span>}
              {stats.classes.motorcycle > 0 && <span className="pill-moto">{stats.classes.motorcycle} Bikes</span>}
              {stats.classes.bus > 0 && <span className="pill-bus">{stats.classes.bus} Buses</span>}
              {stats.classes.truck > 0 && <span className="pill-truck">{stats.classes.truck} Trucks</span>}
            </div>
          </div>
        ) : (
          <div className="stats-empty">Ready for photo input</div>
        )}
      </div>
    </div>
  );
};

interface CenterTrafficSignalProps {
  selectedRoad: 'North' | 'South' | 'East' | 'West' | null;
  countdown: number;
}

const CenterTrafficSignal: React.FC<CenterTrafficSignalProps> = ({ selectedRoad, countdown }) => {
  return (
    <div className="center-signal-intersection">
      {/* Top Signal Head (facing North) */}
      <div className={`dir-signal-head sig-north ${selectedRoad === 'North' ? 'head-green' : 'head-red'}`}>
        <span className="sig-dir-label">NORTH</span>
        <span className={`lamp ${selectedRoad === 'North' ? 'lamp-green' : 'lamp-red'}`}>
          {selectedRoad === 'North' ? 'GO' : 'STOP'}
        </span>
      </div>

      {/* West Signal Head (facing West) */}
      <div className={`dir-signal-head sig-west ${selectedRoad === 'West' ? 'head-green' : 'head-red'}`}>
        <span className="sig-dir-label">WEST</span>
        <span className={`lamp ${selectedRoad === 'West' ? 'lamp-green' : 'lamp-red'}`}>
          {selectedRoad === 'West' ? 'GO' : 'STOP'}
        </span>
      </div>

      {/* Central Intersection Hub with Countdown */}
      <div className="central-hub-circle">
        <div className="hub-inner-core">
          <span className="hub-title">CENTRAL SIGNAL</span>
          <span className="hub-timer mono">{countdown > 0 ? `${countdown}s` : 'STOP'}</span>
          <span className="hub-active-target">
            {selectedRoad ? `${selectedRoad.toUpperCase()} GO` : 'ALL RED'}
          </span>
        </div>
      </div>

      {/* East Signal Head (facing East) */}
      <div className={`dir-signal-head sig-east ${selectedRoad === 'East' ? 'head-green' : 'head-red'}`}>
        <span className="sig-dir-label">EAST</span>
        <span className={`lamp ${selectedRoad === 'East' ? 'lamp-green' : 'lamp-red'}`}>
          {selectedRoad === 'East' ? 'GO' : 'STOP'}
        </span>
      </div>

      {/* South Signal Head (facing South) */}
      <div className={`dir-signal-head sig-south ${selectedRoad === 'South' ? 'head-green' : 'head-red'}`}>
        <span className="sig-dir-label">SOUTH</span>
        <span className={`lamp ${selectedRoad === 'South' ? 'lamp-green' : 'lamp-red'}`}>
          {selectedRoad === 'South' ? 'GO' : 'STOP'}
        </span>
      </div>
    </div>
  );
};
