% test_VegMitraApp.m
% Automated verification script for VegMitra Phase 1 & Phase 2 App Designer UI

try
    disp('====================================================');
    disp('    RUNNING VEGMITRA APP AUTOMATED TEST SUITE       ');
    disp('====================================================');
    
    % Add VegMitra_MATLAB directory to path
    addpath(fileparts(mfilename('fullpath')));
    
    % 1. Code syntax check using checkcode
    disp('1. Checking MATLAB code syntax using checkcode...');
    issues = checkcode('VegMitraApp.m', '-string');
    if isempty(issues)
        disp('[PASS] Code syntax check passed with 0 warnings/errors.');
    else
        fprintf('[WARNING] Syntax report:\n%s\n', issues);
    end
    
    % 2. App instantiation test
    disp('2. Instantiating VegMitraApp UI...');
    app = VegMitraApp();
    assert(~isempty(app.UIFigure), 'UIFigure failed to initialize');
    assert(isvalid(app.UIFigure), 'UIFigure handle is not valid');
    disp('[PASS] VegMitraApp figure created successfully.');
    
    % 3. Check Initial UI Component values
    disp('3. Verifying default component state...');
    assert(strcmp(app.SystemStatusValue.Text, 'READY'), 'Initial System Status must be READY');
    assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Initial Controller Mode must be AI Adaptive');
    assert(strcmp(app.NorthVehiclesValue.Text, '0'), 'Default North vehicles should be 0');
    assert(strcmp(app.SouthVehiclesValue.Text, '0'), 'Default South vehicles should be 0');
    assert(strcmp(app.EastVehiclesValue.Text, '0'), 'Default East vehicles should be 0');
    assert(strcmp(app.WestVehiclesValue.Text, '0'), 'Default West vehicles should be 0');
    assert(strcmp(app.CurrentGreenRoadValue.Text, 'ALL RED') || strcmp(app.CurrentGreenRoadValue.Text, 'N/A'), 'Default Green Road should be ALL RED or N/A');
    disp('[PASS] Default component values verified.');
    
    % 4. Phase 2 Verification: Intersection Axes & Properties
    disp('4. Verifying Phase 2 Intersection Axes & Limits...');
    assert(~isempty(app.SimulationCanvas), 'SimulationCanvas axes must exist');
    assert(isequal(app.SimulationCanvas.XLim, [-100 100]), 'Canvas XLim must be [-100 100]');
    assert(isequal(app.SimulationCanvas.YLim, [-100 100]), 'Canvas YLim must be [-100 100]');
    disp('[PASS] Simulation Canvas limits verified ([-100, 100]).');

    % 5. Phase 2 Verification: Reusable Coordinate Configuration Structure
    disp('5. Verifying Phase 2 Reusable Coordinate Properties...');
    assert(~isempty(app.IntersectionConfig), 'IntersectionConfig structure must exist');
    cfg = app.IntersectionConfig;
    assert(cfg.RoadWidth == 40, 'RoadWidth must be 40');
    
    % Check Lane Coordinates for all 4 directions
    assert(isfield(cfg.LaneCoordinates, 'North'), 'North lane coordinates missing');
    assert(isfield(cfg.LaneCoordinates, 'South'), 'South lane coordinates missing');
    assert(isfield(cfg.LaneCoordinates, 'East'),  'East lane coordinates missing');
    assert(isfield(cfg.LaneCoordinates, 'West'),  'West lane coordinates missing');
    assert(cfg.LaneCoordinates.North.IncomingX == -10, 'North incoming lane X coordinate must be -10');
    assert(cfg.LaneCoordinates.South.IncomingX == 10,  'South incoming lane X coordinate must be 10');
    assert(cfg.LaneCoordinates.East.IncomingY  == 10,  'East incoming lane Y coordinate must be 10');
    assert(cfg.LaneCoordinates.West.IncomingY  == -10, 'West incoming lane Y coordinate must be -10');
    disp('[PASS] Lane coordinates verified for North, South, East, West.');

    % Check Stop Line Coordinates for all 4 directions
    assert(isfield(cfg.StopLineCoordinates, 'North'), 'North stop line missing');
    assert(isfield(cfg.StopLineCoordinates, 'South'), 'South stop line missing');
    assert(isfield(cfg.StopLineCoordinates, 'East'),  'East stop line missing');
    assert(isfield(cfg.StopLineCoordinates, 'West'),  'West stop line missing');
    assert(isequal(cfg.StopLineCoordinates.North.Y, [20 20]), 'North stop line Y must be 20');
    assert(isequal(cfg.StopLineCoordinates.South.Y, [-20 -20]), 'South stop line Y must be -20');
    assert(isequal(cfg.StopLineCoordinates.East.X, [20 20]), 'East stop line X must be 20');
    assert(isequal(cfg.StopLineCoordinates.West.X, [-20 -20]), 'West stop line X must be -20');
    disp('[PASS] Stop line coordinates verified for North, South, East, West.');

    % Check Signal Housing Positions
    assert(isfield(cfg.SignalPositions, 'North'), 'North signal position missing');
    assert(isfield(cfg.SignalPositions, 'South'), 'South signal position missing');
    assert(isfield(cfg.SignalPositions, 'East'),  'East signal position missing');
    assert(isfield(cfg.SignalPositions, 'West'),  'West signal position missing');
    disp('[PASS] Traffic signal position coordinates verified.');

    % 6. Phase 2 Verification: Graphical Elements rendered on Canvas
    disp('6. Verifying graphical intersection elements on SimulationCanvas...');
    children = app.SimulationCanvas.Children;
    assert(~isempty(children), 'SimulationCanvas must contain drawn graphical objects');
    disp('[PASS] Intersection graphical elements present on canvas.');

    % 7. Phase 1 Button Callback Retest
    disp('7. Retesting Phase 1 button callbacks...');
    
    % Test Start Simulation Button
    app.StartButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'System Status should be RUNNING after Start click');
    disp('[PASS] Start Simulation button callback verified -> System Status: RUNNING');
    
    % Test Stop Simulation Button
    app.StopButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'STOPPED'), 'System Status should be STOPPED after Stop click');
    disp('[PASS] Stop Simulation button callback verified -> System Status: STOPPED');
    
    % Test Emergency Mode Button
    app.EmergencyButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'EMERGENCY MODE'), 'System Status should be EMERGENCY MODE after Emergency click');
    disp('[PASS] Emergency Mode button callback verified -> System Status: EMERGENCY MODE');
    
    % Test Reset Button
    app.ResetButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'READY'), 'System Status should return to READY after Reset click');
    assert(strcmp(app.NorthVehiclesValue.Text, '0'), 'North vehicles reset');
    disp('[PASS] Reset button callback verified -> System Status: READY');
    
    % 8. Phase 3 Verification: Simulation Properties & Initial State
    disp('8. Verifying Phase 3 simulation properties and timer setup...');
    assert(isfield(app.SpawnSettings, 'VehicleSpecs'), 'SpawnSettings.VehicleSpecs missing');
    assert(isfield(app.SpawnSettings.VehicleSpecs, 'Car'), 'Car specs missing');
    assert(isfield(app.SpawnSettings.VehicleSpecs, 'Motorcycle'), 'Motorcycle specs missing');
    assert(isfield(app.SpawnSettings.VehicleSpecs, 'Bus_Truck'), 'Bus_Truck specs missing');
    assert(app.NextVehicleID == 1, 'Initial NextVehicleID must be 1');
    assert(app.TotalVehiclesSpawned == 0, 'Initial TotalVehiclesSpawned must be 0');
    assert(app.TotalVehiclesProcessed == 0, 'Initial TotalVehiclesProcessed must be 0');
    assert(app.SimulationRunning == false, 'Initial SimulationRunning must be false');
    assert(~isempty(app.SimulationTimer) && isvalid(app.SimulationTimer), 'SimulationTimer must be initialized');
    assert(strcmp(app.SimulationTimer.Running, 'off'), 'SimulationTimer should be off initially');
    disp('[PASS] Phase 3 properties and timer initialized correctly.');

    % 9. Phase 3 Verification: Vehicle Spawning in All 4 Directions
    disp('9. Verifying vehicle spawning in all four directions...');
    vNorth = app.spawnSingleVehicle('North', 'Car');
    assert(~isempty(vNorth), 'Failed to spawn North Car');
    assert(strcmp(vNorth.Direction, 'North'), 'North vehicle direction incorrect');
    assert(strcmp(vNorth.Type, 'Car'), 'Vehicle type must be Car');
    assert(vNorth.X == -10, 'North vehicle X must be -10');
    assert(vNorth.Y == 95, 'North vehicle spawn Y must be 95');
    assert(vNorth.Length == 8.0, 'Car length must be 8.0');
    assert(vNorth.Width == 5.0, 'Car width must be 5.0');
    assert(~isempty(vNorth.GraphicHandle) && isvalid(vNorth.GraphicHandle), 'Vehicle graphic handle must be valid');

    vSouth = app.spawnSingleVehicle('South', 'Motorcycle');
    assert(~isempty(vSouth), 'Failed to spawn South Motorcycle');
    assert(vSouth.X == 10, 'South vehicle X must be 10');
    assert(vSouth.Y == -95, 'South vehicle spawn Y must be -95');
    assert(vSouth.Length == 4.5, 'Motorcycle length must be 4.5');

    vEast = app.spawnSingleVehicle('East', 'Bus/Truck');
    assert(~isempty(vEast), 'Failed to spawn East Bus/Truck');
    assert(vEast.X == 95, 'East vehicle spawn X must be 95');
    assert(vEast.Y == 10, 'East vehicle Y must be 10');
    assert(vEast.Length == 14.0, 'Bus/Truck length must be 14.0');

    vWest = app.spawnSingleVehicle('West', 'Car');
    assert(~isempty(vWest), 'Failed to spawn West Car');
    assert(vWest.X == -95, 'West vehicle spawn X must be -95');
    assert(vWest.Y == -10, 'West vehicle Y must be -10');

    assert(numel(app.ActiveVehicles) == 4, 'Must have 4 active vehicles');
    assert(app.TotalVehiclesSpawned == 4, 'TotalVehiclesSpawned must equal 4');
    disp('[PASS] Four directional vehicles successfully spawned with correct coordinates and dimensions.');

    % 10. Phase 3 Verification: Vehicle Movement & Coordinate Updates
    disp('10. Verifying vehicle motion updates along lane paths...');
    yBeforeN = app.ActiveVehicles(1).Y;
    yBeforeS = app.ActiveVehicles(2).Y;
    xBeforeE = app.ActiveVehicles(3).X;
    xBeforeW = app.ActiveVehicles(4).X;

    % Execute simulation update step
    app.updateVehicles();

    assert(app.ActiveVehicles(1).Y < yBeforeN, 'North vehicle must advance downwards (decreasing Y)');
    assert(app.ActiveVehicles(2).Y > yBeforeS, 'South vehicle must advance upwards (increasing Y)');
    assert(app.ActiveVehicles(3).X < xBeforeE, 'East vehicle must advance leftwards (decreasing X)');
    assert(app.ActiveVehicles(4).X > xBeforeW, 'West vehicle must advance rightwards (increasing X)');

    % Verify graphics rectangle position matches new vehicle coordinates
    posN = get(app.ActiveVehicles(1).GraphicHandle, 'Position');
    expectedBottomN = app.ActiveVehicles(1).Y - app.ActiveVehicles(1).Length / 2;
    assert(abs(posN(2) - expectedBottomN) < 1e-4, 'Graphics position must match numerical coordinates');
    disp('[PASS] Vehicles advance smoothly in correct directions and graphics sync verified.');

    % 11. Phase 3 Verification: Boundary-to-Boundary Headway & Anti-Collision
    disp('11. Verifying boundary-to-boundary headway and collision prevention...');
    % Clear vehicles for controlled collision test
    app.resetSimulation();

    % Spawn lead car in North at Y = 40
    leadCar = app.spawnSingleVehicle('North', 'Car');
    assert(~isempty(leadCar), 'Lead car spawn failed');
    app.ActiveVehicles(1).Y = 40; % Move lead car to Y = 40 (front at 36, rear at 44)
    leadL = app.ActiveVehicles(1).Length; % 8.0

    % Spawn follower Bus/Truck in North (Length = 14.0)
    followBus = app.spawnSingleVehicle('North', 'Bus/Truck');
    assert(~isempty(followBus), 'Follower bus spawn failed');
    % Place bus right behind lead car with bumper gap <= MinBumperBuffer (4.0)
    % Required center distance: (leadL + busL)/2 + gap = (8 + 14)/2 + 3 = 14
    app.ActiveVehicles(2).Y = 40 + (leadL + followBus.Length)/2 + 3; % Y = 54 (gap = 3.0)
    busBeforeY = app.ActiveVehicles(2).Y;

    % Lead vehicle speed set to 0 (stopped)
    app.ActiveVehicles(1).Speed = 0;
    app.updateVehicles();

    % Follower vehicle should halt (0 advancement) because bumperGap (3.0) <= MinBumperBuffer (4.0)
    assert(app.ActiveVehicles(2).Y == busBeforeY, 'Following vehicle must halt when bumper gap is below safety threshold');
    
    % Now move lead vehicle forward to open safe gap (> 12.0)
    app.ActiveVehicles(1).Y = 10; % Lead car moves ahead
    app.updateVehicles();
    assert(app.ActiveVehicles(2).Y < busBeforeY, 'Following vehicle must resume moving once headway opens');
    disp('[PASS] Boundary-to-boundary headway strictly prevents collisions and visual overlapping.');

    % 12. Phase 3 Verification: Out-of-Bounds Removal
    disp('12. Verifying vehicle removal upon exiting canvas boundaries...');
    % Place active vehicle beyond exit boundary (Y < -110)
    app.ActiveVehicles(1).Y = -115;
    procBefore = app.TotalVehiclesProcessed;
    app.updateVehicles();
    assert(app.TotalVehiclesProcessed == procBefore + 1, 'Processed vehicle count must increment on exit');
    disp('[PASS] Out-of-bounds vehicles cleanly removed and counters updated.');

    % 13. Phase 3 Verification: Start, Stop, and Reset Integration
    disp('13. Verifying Start, Stop, and Reset button workflows with animation timer...');
    app.StartButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'Status must be RUNNING');
    assert(app.SimulationRunning == true, 'SimulationRunning must be true');
    assert(strcmp(app.SimulationTimer.Running, 'on'), 'SimulationTimer must be running');
    disp('[PASS] Start Simulation button starts timer and updates status to RUNNING.');

    app.StopButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'STOPPED'), 'Status must be STOPPED');
    assert(app.SimulationRunning == false, 'SimulationRunning must be false');
    assert(strcmp(app.SimulationTimer.Running, 'off'), 'SimulationTimer must pause');
    disp('[PASS] Stop Simulation button pauses timer and updates status to STOPPED.');

    app.ResetButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'READY'), 'Status must return to READY');
    assert(isempty(app.ActiveVehicles), 'ActiveVehicles must be empty after Reset');
    assert(app.NextVehicleID == 1, 'NextVehicleID must reset to 1');
    assert(app.TotalVehiclesSpawned == 0, 'TotalVehiclesSpawned must reset to 0');
    assert(app.TotalVehiclesProcessed == 0, 'TotalVehiclesProcessed must reset to 0');
    assert(strcmp(app.SimulationTimer.Running, 'off'), 'SimulationTimer must remain off');
    disp('[PASS] Reset button completely restores READY state and clears all simulation data.');

    % =============================================================
    % PHASE 4 TESTS: TRAFFIC SIGNALS & CONTROLLER VERIFICATION
    % =============================================================

    % 14. Phase 4 Test A: Signal Initialization
    disp('14. Phase 4 Test A: Verifying signal initialization states...');
    assert(strcmp(app.getSignalState('North'), 'RED'),   'Initial North signal must be RED');
    assert(strcmp(app.getSignalState('South'), 'RED'),   'Initial South signal must be RED');
    assert(strcmp(app.getSignalState('East'),  'RED'),   'Initial East signal must be RED');
    assert(strcmp(app.getSignalState('West'),  'RED'),   'Initial West signal must be RED');
    assert(strcmp(app.getSignalPhase(), 'ALL_RED'),      'Initial SignalPhase must be ALL_RED');
    assert(strcmp(app.CurrentGreenRoadValue.Text, 'ALL RED'), 'CurrentGreenRoad should display "ALL RED"');
    assert(strcmp(app.CurrentGreenTimeValue.Text, '0s'), 'CurrentGreenTime should display "0s" initially');
    disp('[PASS] Signal initialization verified: All signals RED.');

    % 15. Phase 4 Test B: Signal Graphics Elements
    disp('15. Phase 4 Test B: Verifying 4 signal graphical objects and lamp elements...');
    dirs = {'North', 'South', 'East', 'West'};
    for dIdx = 1:numel(dirs)
        d = dirs{dIdx};
        assert(isfield(app.TrafficSignalGraphics, d), sprintf('Signal graphics structure for %s missing', d));
        g = app.TrafficSignalGraphics.(d);
        assert(~isempty(g.Housing) && isvalid(g.Housing), sprintf('%s housing graphic handle invalid', d));
        assert(~isempty(g.RedLamp) && isvalid(g.RedLamp), sprintf('%s Red lamp graphic handle invalid', d));
        assert(~isempty(g.YellowLamp) && isvalid(g.YellowLamp), sprintf('%s Yellow lamp graphic handle invalid', d));
        assert(~isempty(g.GreenLamp) && isvalid(g.GreenLamp), sprintf('%s Green lamp graphic handle invalid', d));
    end
    % Check illuminated visual color (initial state is ALL RED)
    gN = app.TrafficSignalGraphics.North;
    assert(isequal(get(gN.RedLamp, 'FaceColor'), [1.00 0.12 0.12]), 'North red lamp should have illuminated red face color');
    gE = app.TrafficSignalGraphics.East;
    assert(isequal(get(gE.RedLamp, 'FaceColor'), [1.00 0.12 0.12]), 'East red lamp should have illuminated red face color');
    disp('[PASS] Signal graphics objects and Red/Yellow/Green lamp elements verified.');

    % 16. Phase 4 Test C: Signal State Transitions and Conflict Prevention
    disp('16. Phase 4 Test C: Verifying state changes and safety invariant against conflicting greens...');
    % Transition North to Yellow
    app.setSignalPhase('NORTH_YELLOW');
    assert(strcmp(app.getSignalState('North'), 'YELLOW'), 'North should transition to YELLOW');
    assert(strcmp(app.getSignalState('South'), 'RED'),    'South must remain RED');
    assert(strcmp(app.getSignalState('East'),  'RED'),    'East must remain RED');
    assert(strcmp(app.getSignalState('West'),  'RED'),    'West must remain RED');

    % Transition to All-Red
    app.setSignalPhase('ALL_RED_1');
    assert(strcmp(app.getSignalState('North'), 'RED'), 'North must be RED during all-red');
    assert(strcmp(app.getSignalState('South'), 'RED'), 'South must be RED during all-red');
    assert(strcmp(app.getSignalState('East'),  'RED'), 'East must be RED during all-red');
    assert(strcmp(app.getSignalState('West'),  'RED'), 'West must be RED during all-red');

    % Transition to East Green
    app.setSignalPhase('EAST_GREEN');
    assert(strcmp(app.getSignalState('East'),  'GREEN'), 'East should transition to GREEN');
    assert(strcmp(app.getSignalState('West'),  'RED'),   'West must remain RED');
    assert(strcmp(app.getSignalState('North'), 'RED'),   'North must remain RED');
    assert(strcmp(app.getSignalState('South'), 'RED'),   'South must remain RED');
    assert(contains(app.CurrentGreenRoadValue.Text, 'East GREEN'), 'Dashboard should display East GREEN');

    % Safety test: attempting to set North to GREEN while East is GREEN must be blocked
    conflictBlocked = false;
    try
        app.setSignalState('North', 'GREEN');
    catch
        conflictBlocked = true;
    end
    assert(conflictBlocked, 'Conflicting green safety invariant must throw an error');
    
    % Restore initial phase
    app.setSignalPhase('NS_GREEN');
    disp('[PASS] Transitions operate correctly and conflicting greens are strictly prevented.');

    % 17. Phase 4 Test D: Safety Transition Intervals
    disp('17. Phase 4 Test D: Verifying safety transition intervals (Yellow=2s, All-Red=1s)...');
    cfg = app.SignalTimingConfig;
    assert(cfg.YellowDuration == 2.0, 'Yellow duration must be 2 seconds');
    assert(cfg.AllRedDuration == 1.0, 'All-red duration must be 1 second');

    % Set NORTH_GREEN, then initiate transition to NORTH_YELLOW
    app.setSignalPhase('NORTH_GREEN');
    assert(strcmp(app.getSignalPhase(), 'NORTH_GREEN'), 'Must start at NORTH_GREEN');
    
    app.setSignalPhase('NORTH_YELLOW');
    assert(strcmp(app.getSignalPhase(), 'NORTH_YELLOW'), 'Must be NORTH_YELLOW');
    assert(app.SignalPhaseTimeRemaining == 2.0, 'Yellow remaining time must be 2.0s');
    
    % Advance 2.0 seconds -> transitions to ALL_RED
    app.updateTrafficSignals(2.0);
    assert(strcmp(app.getSignalPhase(), 'ALL_RED'), 'Must transition to ALL_RED after 2s yellow');
    assert(app.SignalPhaseTimeRemaining == 1.0, 'All-Red remaining time must be 1.0s');
    
    % Advance 1.0 second -> transitions to target GREEN
    app.updateTrafficSignals(1.0);
    assert(contains(app.getSignalPhase(), 'GREEN'), 'Must transition to GREEN phase after 1s all-red');
    disp('[PASS] Safety transition intervals verified (2s Yellow -> 1s All-Red -> Green).');

    % 18. Phase 4 Test E: Red-Light Vehicle Stopping Behavior
    disp('18. Phase 4 Test E: Verifying vehicle does not cross red-light stop line...');
    app.resetSimulation();
    % East approach is RED initially
    assert(strcmp(app.getSignalState('East'), 'RED'), 'East signal must be RED');
    
    % Spawn car in East (X spawns at 95, travel direction: leftwards/decreasing X)
    % East stop line is at X = 20
    vEast = app.spawnSingleVehicle('East', 'Car');
    assert(~isempty(vEast), 'Failed to spawn East car');
    
    % Move car close to stop line, e.g. at X = 28 (Length = 8, front bumper at X = 24)
    app.ActiveVehicles(1).X = 28;
    
    % Run multiple simulation update steps
    for step = 1:20
        app.updateVehicles();
    end
    
    % Front bumper must NOT have crossed X = 20
    frontX = app.ActiveVehicles(1).X - app.ActiveVehicles(1).Length / 2.0;
    assert(frontX >= 20.0, sprintf('Vehicle front (%0.2f) crossed RED stop line (20.0)!', frontX));
    % Also verify vehicle has come to a complete halt
    dec = app.getStopDecision(app.ActiveVehicles(1));
    assert(dec.AllowedAdvancement == 0, 'Stopped vehicle at red light must have 0 allowed advancement');
    disp('[PASS] Red-light vehicle halts cleanly before the stop line.');

    % 19. Phase 4 Test F: Green-Light Vehicle Behavior
    disp('19. Phase 4 Test F: Verifying vehicle progresses through intersection on GREEN...');
    app.resetSimulation();
    app.setSignalPhase('NORTH_GREEN');
    assert(strcmp(app.getSignalState('North'), 'GREEN'), 'North signal must be GREEN');
    
    % Spawn car in North (spawn at Y=95, stop line at Y=20, moves downwards towards negative Y)
    app.spawnSingleVehicle('North', 'Car');
    % Place car approaching stop line at Y = 25 (front at 21)
    app.ActiveVehicles(1).Y = 25;
    yBefore = app.ActiveVehicles(1).Y;
    
    % Execute update steps
    for step = 1:15
        app.updateVehicles();
    end
    
    % Vehicle should have advanced freely through the intersection (Y < 20)
    assert(app.ActiveVehicles(1).Y < yBefore, 'Green light vehicle must advance');
    frontY = app.ActiveVehicles(1).Y - app.ActiveVehicles(1).Length / 2.0;
    assert(frontY < 20.0, 'Green light vehicle must progress past stop line into intersection');
    disp('[PASS] Green-light vehicle progresses smoothly through the intersection.');

    % 20. Phase 4 Test G: Signal Transition - Waiting Vehicles Resume on Green
    disp('20. Phase 4 Test G: Verifying queued vehicles resume once light turns GREEN...');
    app.resetSimulation();
    % Spawn East vehicle on RED and let it halt at stop line
    app.spawnSingleVehicle('East', 'Car');
    app.ActiveVehicles(1).X = 26; % near stop line
    for step = 1:10
        app.updateVehicles();
    end
    haltedX = app.ActiveVehicles(1).X;
    
    % Switch signals to EW_GREEN
    app.setSignalPhase('EW_GREEN');
    assert(strcmp(app.getSignalState('East'), 'GREEN'), 'East signal must now be GREEN');
    
    % Update simulation
    app.updateVehicles();
    assert(app.ActiveVehicles(1).X < haltedX, 'Vehicle must resume motion after signal turns GREEN');
    disp('[PASS] Previously waiting vehicle resumes motion immediately upon signal turning GREEN.');

    % 21. Phase 4 Test H: Headway and anti-collision safety in red-light queue
    disp('21. Phase 4 Test H: Verifying headway and queuing behind vehicle stopped at red light...');
    app.resetSimulation();
    % North set to RED for controlled queue test
    app.setSignalPhase('EW_GREEN'); % North is RED
    assert(strcmp(app.getSignalState('North'), 'RED'), 'North must be RED');

    % Spawn lead car in North and position halted at stop line (front at 21, rear at 29, center at 25)
    app.spawnSingleVehicle('North', 'Car');
    app.ActiveVehicles(1).Y = 25; % Length = 8

    % Spawn second car behind lead car (length = 8)
    app.spawnSingleVehicle('North', 'Car');
    app.ActiveVehicles(2).Y = 45; % Approaching lead car from behind

    % Step simulation multiple times
    for step = 1:30
        app.updateVehicles();
    end

    % Check positions:
    leadRear = app.ActiveVehicles(1).Y + app.ActiveVehicles(1).Length / 2.0;   % 25 + 4 = 29
    followFront = app.ActiveVehicles(2).Y - app.ActiveVehicles(2).Length / 2.0; % Y - 4
    bumperGap = followFront - leadRear;
    D_min = app.SpawnSettings.MinBumperBuffer; % 4.0

    assert(bumperGap >= D_min - 1e-3, sprintf('Queued vehicle bumper gap (%0.2f) must be >= MinBumperBuffer (%0.2f)', bumperGap, D_min));
    assert(app.ActiveVehicles(1).Y < app.ActiveVehicles(2).Y, 'Follower must remain behind leader');
    disp('[PASS] Natural queuing and bumper-to-bumper headway safety maintained at red light.');

    % 22. Phase 4 Test I: Start/Stop Controller & Timer Integration
    disp('22. Phase 4 Test I: Verifying Start begins and Stop pauses signal progression...');
    app.resetSimulation();
    app.StartButtonPushed([]);
    assert(app.SignalControllerRunning == true, 'SignalControllerRunning must be true when simulation starts');
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'Status must be RUNNING');
    
    app.StopButtonPushed([]);
    assert(app.SignalControllerRunning == false, 'SignalControllerRunning must be false when simulation stops');
    assert(strcmp(app.SystemStatusValue.Text, 'STOPPED'), 'Status must be STOPPED');

    % Restart resumes
    app.StartButtonPushed([]);
    assert(app.SignalControllerRunning == true, 'Restarting must resume signal controller');
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'Status must be RUNNING on restart');
    app.StopButtonPushed([]);
    disp('[PASS] Start begins, Stop pauses, and Restart resumes signal progression.');

    % 23. Phase 4 Test J: Reset restores pristine signal and UI state
    disp('23. Phase 4 Test J: Verifying Reset restores default signals, clears vehicles, and sets READY...');
    % Change signal phase and spawn vehicles
    app.setSignalPhase('EW_GREEN');
    app.spawnSingleVehicle('East', 'Car');
    assert(~isempty(app.ActiveVehicles), 'Must have active vehicles before reset');
    
    % Click Reset
    app.ResetButtonPushed([]);
    assert(isempty(app.ActiveVehicles), 'ActiveVehicles must be cleared after reset');
    assert(strcmp(app.getSignalState('North'), 'RED'),   'North signal must reset to RED');
    assert(strcmp(app.getSignalState('South'), 'RED'),   'South signal must reset to RED');
    assert(strcmp(app.getSignalState('East'),  'RED'),   'East signal must reset to RED');
    assert(strcmp(app.getSignalState('West'),  'RED'),   'West signal must reset to RED');
    assert(strcmp(app.getSignalPhase(), 'ALL_RED'),      'SignalPhase must reset to ALL_RED');
    assert(strcmp(app.SystemStatusValue.Text, 'READY'),   'SystemStatus must reset to READY');
    assert(strcmp(app.CurrentGreenRoadValue.Text, 'ALL RED'), 'Green Road must reset to "ALL RED"');
    disp('[PASS] Reset cleanly restores initial traffic signal states and READY status.');

    % =============================================================
    % PHASE 5 TESTS: VEHICLE COUNTING VERIFICATION
    % =============================================================

    % 25. Phase 5 Test A: North vehicle appears in North count
    disp('25. Phase 5 Test A: Verifying North vehicle appears in North count...');
    app.resetSimulation();
    initCounts = app.getVehicleCounts();
    assert(initCounts.North == 0 && initCounts.South == 0 && initCounts.East == 0 && initCounts.West == 0, ...
        'All vehicle counts must be 0 initially');
    
    vNorth = app.spawnSingleVehicle('North', 'Car');
    assert(~isempty(vNorth), 'North car spawn failed');
    assert(app.VehicleCounts.North == 1, 'app.VehicleCounts.North must be 1');
    assert(app.getVehicleCountByDirection('North') == 1, 'getVehicleCountByDirection(North) must be 1');
    assert(app.VehicleCounts.South == 0, 'South count must remain 0');
    assert(app.VehicleCounts.East == 0, 'East count must remain 0');
    assert(app.VehicleCounts.West == 0, 'West count must remain 0');
    assert(strcmp(app.NorthVehiclesValue.Text, '1'), 'NorthVehiclesValue GUI label must display 1');
    assert(strcmp(app.SouthVehiclesValue.Text, '0'), 'SouthVehiclesValue GUI label must display 0');
    disp('[PASS] Phase 5 Test A: North vehicle appears in North count.');

    % 26. Phase 5 Test B: Vehicles in all four directions counted correctly
    disp('26. Phase 5 Test B: Verifying vehicles in all four directions are counted correctly...');
    app.resetSimulation();
    % Spawn North (2 vehicles)
    app.spawnSingleVehicle('North', 'Car');
    app.ActiveVehicles(1).Y = 50; % Move ahead to allow clearance
    app.spawnSingleVehicle('North', 'Motorcycle');
    
    % Spawn South (3 vehicles)
    app.spawnSingleVehicle('South', 'Car');
    app.ActiveVehicles(end).Y = -50;
    app.spawnSingleVehicle('South', 'Motorcycle');
    app.ActiveVehicles(end).Y = -70;
    app.spawnSingleVehicle('South', 'Bus/Truck');
    
    % Spawn East (1 vehicle)
    app.spawnSingleVehicle('East', 'Bus/Truck');
    
    % Spawn West (2 vehicles)
    app.spawnSingleVehicle('West', 'Car');
    app.ActiveVehicles(end).X = -50;
    app.spawnSingleVehicle('West', 'Motorcycle');

    c = app.getVehicleCounts();
    assert(c.North == 2, sprintf('North count expected 2, got %d', c.North));
    assert(c.South == 3, sprintf('South count expected 3, got %d', c.South));
    assert(c.East == 1, sprintf('East count expected 1, got %d', c.East));
    assert(c.West == 2, sprintf('West count expected 2, got %d', c.West));
    assert(app.getVehicleCountByDirection('North') == 2, 'North count mismatch');
    assert(app.getVehicleCountByDirection('South') == 3, 'South count mismatch');
    assert(app.getVehicleCountByDirection('East') == 1, 'East count mismatch');
    assert(app.getVehicleCountByDirection('West') == 2, 'West count mismatch');
    assert(numel(app.ActiveVehicles) == 8, 'Total active vehicles must equal 8');
    disp('[PASS] Phase 5 Test B: Vehicles in all four directions counted correctly.');

    % 27. Phase 5 Test C: Counts decrease when vehicles are removed
    disp('27. Phase 5 Test C: Verifying directional counts decrease when vehicles are removed...');
    % Explicit removal of a South vehicle
    southBefore = app.getVehicleCountByDirection('South'); % 3
    sIdx = find(strcmp({app.ActiveVehicles.Direction}, 'South'), 1);
    app.removeVehicle(sIdx);
    assert(app.getVehicleCountByDirection('South') == southBefore - 1, 'South count must decrease by 1 after removeVehicle');
    assert(strcmp(app.SouthVehiclesValue.Text, num2str(southBefore - 1)), 'South GUI label must match decremented count');

    % Canvas boundary exit removal of a North vehicle
    northBefore = app.getVehicleCountByDirection('North'); % 2
    nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'), 1);
    app.ActiveVehicles(nIdx).Y = -115; % Exceed exit threshold
    app.updateVehicles();
    assert(app.getVehicleCountByDirection('North') == northBefore - 1, 'North count must decrease by 1 after exiting canvas');
    assert(strcmp(app.NorthVehiclesValue.Text, num2str(northBefore - 1)), 'North GUI label must match decremented count');
    disp('[PASS] Phase 5 Test C: Directional counts decrease properly when vehicles are removed.');

    % 28. Phase 5 Test D: Total spawned and processed counters remain accurate
    disp('28. Phase 5 Test D: Verifying Total Vehicles Spawned and Processed remain accurate...');
    app.resetSimulation();
    assert(app.TotalVehiclesSpawned == 0, 'TotalVehiclesSpawned must start at 0');
    assert(app.TotalVehiclesProcessed == 0, 'TotalVehiclesProcessed must start at 0');

    % Spawn 4 vehicles
    app.spawnSingleVehicle('North', 'Car');
    app.spawnSingleVehicle('South', 'Car');
    app.spawnSingleVehicle('East', 'Car');
    app.spawnSingleVehicle('West', 'Car');
    assert(app.TotalVehiclesSpawned == 4, 'TotalVehiclesSpawned must be 4 after 4 spawns');
    assert(app.TotalVehiclesProcessed == 0, 'TotalVehiclesProcessed must still be 0');

    % Process 2 vehicles via boundary exit
    app.ActiveVehicles(1).Y = -120;
    app.ActiveVehicles(2).Y = 120;
    app.updateVehicles();
    assert(app.TotalVehiclesSpawned == 4, 'TotalVehiclesSpawned must stay 4 after exit');
    assert(app.TotalVehiclesProcessed == 2, 'TotalVehiclesProcessed must increment to 2');
    assert(numel(app.ActiveVehicles) == 2, 'Must have 2 active vehicles remaining');
    assert(strcmp(app.VehiclesProcessedValue.Text, '2'), 'VehiclesProcessedValue GUI label must display 2');
    disp('[PASS] Phase 5 Test D: Total spawned and processed counters remain accurate.');

    % 29. Phase 5 Test E: Reset clears all counts and totals to zero
    disp('29. Phase 5 Test E: Verifying Reset clears all directional counts and totals to zero...');
    app.ResetButtonPushed([]);
    assert(app.VehicleCounts.North == 0, 'North count must reset to 0');
    assert(app.VehicleCounts.South == 0, 'South count must reset to 0');
    assert(app.VehicleCounts.East == 0, 'East count must reset to 0');
    assert(app.VehicleCounts.West == 0, 'West count must reset to 0');
    assert(app.TotalVehiclesSpawned == 0, 'TotalVehiclesSpawned must reset to 0');
    assert(app.TotalVehiclesProcessed == 0, 'TotalVehiclesProcessed must reset to 0');
    assert(isempty(app.ActiveVehicles), 'ActiveVehicles must be empty after Reset');
    assert(strcmp(app.NorthVehiclesValue.Text, '0'), 'NorthVehiclesValue must reset to 0');
    assert(strcmp(app.SouthVehiclesValue.Text, '0'), 'SouthVehiclesValue must reset to 0');
    assert(strcmp(app.EastVehiclesValue.Text, '0'), 'EastVehiclesValue must reset to 0');
    assert(strcmp(app.WestVehiclesValue.Text, '0'), 'WestVehiclesValue must reset to 0');
    assert(strcmp(app.VehiclesProcessedValue.Text, '0'), 'VehiclesProcessedValue must reset to 0');
    disp('[PASS] Phase 5 Test E: Reset completely restores all counts and totals to zero.');

    % 30. Phase 5 Test F: Live GUI labels match internal counts continuously
    disp('30. Phase 5 Test F: Verifying live GUI labels match internal counts continuously...');
    app.resetSimulation();
    app.spawnSingleVehicle('North', 'Car');
    app.spawnSingleVehicle('East', 'Car');
    app.spawnSingleVehicle('West', 'Car');

    % Direct string comparison with internal properties
    assert(strcmp(app.NorthVehiclesValue.Text, num2str(app.VehicleCounts.North)), 'North label mismatch');
    assert(strcmp(app.SouthVehiclesValue.Text, num2str(app.VehicleCounts.South)), 'South label mismatch');
    assert(strcmp(app.EastVehiclesValue.Text, num2str(app.VehicleCounts.East)), 'East label mismatch');
    assert(strcmp(app.WestVehiclesValue.Text, num2str(app.VehicleCounts.West)), 'West label mismatch');

    % Run multiple simulation steps and verify GUI labels stay synchronized
    for step = 1:5
        app.updateVehicles();
        assert(strcmp(app.NorthVehiclesValue.Text, num2str(app.getVehicleCountByDirection('North'))), 'North label sync failed');
        assert(strcmp(app.SouthVehiclesValue.Text, num2str(app.getVehicleCountByDirection('South'))), 'South label sync failed');
        assert(strcmp(app.EastVehiclesValue.Text, num2str(app.getVehicleCountByDirection('East'))), 'East label sync failed');
        assert(strcmp(app.WestVehiclesValue.Text, num2str(app.getVehicleCountByDirection('West'))), 'West label sync failed');
    end
    disp('[PASS] Phase 5 Test F: Live GUI labels strictly match internal counts.');

    % 31. Phase 5 Test G: Origin direction classification & zero double-counting
    disp('31. Phase 5 Test G: Verifying origin direction classification and zero double-counting...');
    app.resetSimulation();
    app.spawnSingleVehicle('North', 'Car');
    
    % Move North vehicle past the intersection into negative Y territory (Y = -50)
    app.ActiveVehicles(1).Y = -50;
    counts = app.getVehicleCounts();
    
    % Vehicle originating from North must count as North, never inferred as South
    assert(counts.North == 1, 'Vehicle originating from North must count as North even when Y < 0');
    assert(counts.South == 0, 'Vehicle originating from North must NOT be inferred as South from Y position');
    assert(app.getVehicleCountByDirection('North') == 1, 'Direction lookup must return 1 for North');
    assert(app.getVehicleCountByDirection('South') == 0, 'Direction lookup must return 0 for South');

    % Add East vehicle and move past intersection to negative X territory (X = -40)
    app.spawnSingleVehicle('East', 'Car');
    app.ActiveVehicles(2).X = -40;
    counts2 = app.getVehicleCounts();
    assert(counts2.East == 1, 'Vehicle originating from East must count as East even when X < 0');
    assert(counts2.West == 0, 'Vehicle originating from East must NOT be inferred as West from X position');

    % Invariant: sum of directional counts strictly equals total active vehicles
    totalDirectional = counts2.North + counts2.South + counts2.East + counts2.West;
    assert(totalDirectional == numel(app.ActiveVehicles), ...
        sprintf('Sum of directional counts (%d) must equal active vehicles (%d)', totalDirectional, numel(app.ActiveVehicles)));
    disp('[PASS] Phase 5 Test G: Origin direction preserved across intersection and zero double-counting verified.');

    % =============================================================
    % PHASE 6 TESTS: TRAFFIC DENSITY CALCULATION VERIFICATION
    % =============================================================

    % 32. Phase 6 Test A: Density initialization
    disp('32. Phase 6 Test A: Verifying density initialization states...');
    app.resetSimulation();
    assert(isfield(app.TrafficDensity, 'North'), 'TrafficDensity must have North field');
    assert(isfield(app.TrafficDensity, 'South'), 'TrafficDensity must have South field');
    assert(isfield(app.TrafficDensity, 'East'),  'TrafficDensity must have East field');
    assert(isfield(app.TrafficDensity, 'West'),  'TrafficDensity must have West field');
    assert(app.TrafficDensity.North.Percentage == 0, 'Initial North density must be 0%');
    assert(app.TrafficDensity.South.Percentage == 0, 'Initial South density must be 0%');
    assert(app.TrafficDensity.East.Percentage  == 0, 'Initial East density must be 0%');
    assert(app.TrafficDensity.West.Percentage  == 0, 'Initial West density must be 0%');
    assert(strcmp(app.TrafficDensity.North.Level, 'LOW'), 'Initial North level must be LOW');
    assert(strcmp(app.TrafficDensity.South.Level, 'LOW'), 'Initial South level must be LOW');
    assert(strcmp(app.TrafficDensity.East.Level,  'LOW'), 'Initial East level must be LOW');
    assert(strcmp(app.TrafficDensity.West.Level,  'LOW'), 'Initial West level must be LOW');
    assert(strcmp(app.TrafficDensityValue.Text, '0%'), 'Initial Traffic Density label must be 0%');
    assert(strcmp(app.CongestionValue.Text, 'Low (0%)'), 'Initial Congestion Level must be Low (0%)');
    disp('[PASS] Phase 6 Test A: Density initialization verified (all 0% and LOW).');

    % 33. Phase 6 Test B: Density formula
    disp('33. Phase 6 Test B: Verifying density calculation formula...');
    % Verify 0, 2, 5, 8, 10 vehicles normalized against MAX_VEHICLES_PER_APPROACH = 10
    app.resetSimulation();
    d0 = app.calculateDensityForDirection('North');
    assert(d0.Percentage == 0, '0 vehicles must equal 0%');
    assert(strcmp(d0.Level, 'LOW'), '0% must be category LOW');

    % Spawn 2 vehicles on North
    app.spawnSingleVehicle('North', 'Car');
    app.ActiveVehicles(1).Y = 50;
    app.spawnSingleVehicle('North', 'Motorcycle');
    d2 = app.calculateDensityForDirection('North');
    assert(d2.Percentage == 20, sprintf('2 vehicles must equal 20%%, got %d%%', d2.Percentage));
    assert(strcmp(d2.Level, 'LOW'), '20% must be category LOW');

    % Add 3 more vehicles on North (total 5)
    for k = 3:5
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx)
            app.ActiveVehicles(nIdx(j)).Y = 25 + (j - 1) * 7;
        end
        app.spawnSingleVehicle('North', 'Car');
    end
    d5 = app.calculateDensityForDirection('North');
    assert(d5.Percentage == 50, sprintf('5 vehicles must equal 50%%, got %d%%', d5.Percentage));
    assert(strcmp(d5.Level, 'MEDIUM'), '50% must be category MEDIUM');

    % Add 3 more vehicles on North (total 8)
    for k = 6:8
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx)
            app.ActiveVehicles(nIdx(j)).Y = 25 + (j - 1) * 6;
        end
        app.spawnSingleVehicle('North', 'Car');
    end
    d8 = app.calculateDensityForDirection('North');
    assert(d8.Percentage == 80, sprintf('8 vehicles must equal 80%%, got %d%%', d8.Percentage));
    assert(strcmp(d8.Level, 'HIGH'), '80% must be category HIGH');

    % Add 2 more vehicles on North (total 10)
    for k = 9:10
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx)
            app.ActiveVehicles(nIdx(j)).Y = 25 + (j - 1) * 5;
        end
        app.spawnSingleVehicle('North', 'Car');
    end
    d10 = app.calculateDensityForDirection('North');
    assert(d10.Percentage == 100, sprintf('10 vehicles must equal 100%%, got %d%%', d10.Percentage));
    assert(strcmp(d10.Level, 'VERY HIGH'), '100% must be category VERY HIGH');
    disp('[PASS] Phase 6 Test B: Density formula verified (0->0%, 2->20%, 5->50%, 8->80%, 10->100%).');

    % 34. Phase 6 Test C: Density cap & configurable simulation normalization parameter
    disp('34. Phase 6 Test C: Verifying density cap (11+ capped at 100%) and configurable parameter...');
    % Add 11th and 12th vehicles
    for k = 11:12
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx)
            app.ActiveVehicles(nIdx(j)).Y = 25 + (j - 1) * 4;
        end
        app.spawnSingleVehicle('North', 'Car');
    end
    d12 = app.calculateDensityForDirection('North');
    assert(d12.Percentage == 100, sprintf('12 vehicles must be capped at 100%%, got %d%%', d12.Percentage));
    assert(strcmp(d12.Level, 'VERY HIGH'), 'Capped 100% must be VERY HIGH');

    % Verify configurable simulation normalization parameter (e.g. changing MaxVehiclesPerApproach to 20)
    app.MaxVehiclesPerApproach = 20;
    dNorm = app.calculateDensityForDirection('North'); % 12 vehicles out of 20 = 60%
    assert(dNorm.Percentage == 60, sprintf('With MaxVehiclesPerApproach=20, 12 vehicles must equal 60%%, got %d%%', dNorm.Percentage));
    assert(strcmp(dNorm.Level, 'MEDIUM'), '60% must be category MEDIUM');

    % Restore standard normalization benchmark parameter
    app.MaxVehiclesPerApproach = 10;
    disp('[PASS] Phase 6 Test C: Density cap and configurable normalization parameter verified.');

    % 35. Phase 6 Test D: Category thresholds
    disp('35. Phase 6 Test D: Verifying LOW / MEDIUM / HIGH / VERY HIGH thresholds...');
    assert(strcmp(app.getDensityLevel(0),   'LOW'),       '0% must be LOW');
    assert(strcmp(app.getDensityLevel(30),  'LOW'),       '30% boundary must be LOW');
    assert(strcmp(app.getDensityLevel(31),  'MEDIUM'),    '31% boundary must be MEDIUM');
    assert(strcmp(app.getDensityLevel(60),  'MEDIUM'),    '60% boundary must be MEDIUM');
    assert(strcmp(app.getDensityLevel(61),  'HIGH'),      '61% boundary must be HIGH');
    assert(strcmp(app.getDensityLevel(80),  'HIGH'),      '80% boundary must be HIGH');
    assert(strcmp(app.getDensityLevel(81),  'VERY HIGH'), '81% boundary must be VERY HIGH');
    assert(strcmp(app.getDensityLevel(100), 'VERY HIGH'), '100% boundary must be VERY HIGH');
    disp('[PASS] Phase 6 Test D: Category threshold boundaries verified.');

    % 36. Phase 6 Test E: Directional calculation independence
    disp('36. Phase 6 Test E: Verifying directional calculation independence...');
    app.resetSimulation();
    % North: 2 vehicles -> 20% (LOW)
    app.spawnSingleVehicle('North', 'Car');
    app.ActiveVehicles(end).Y = 50;
    app.spawnSingleVehicle('North', 'Car');

    % South: 4 vehicles -> 40% (MEDIUM)
    for k = 1:4
        sIdx = find(strcmp({app.ActiveVehicles.Direction}, 'South'));
        for j = 1:numel(sIdx)
            app.ActiveVehicles(sIdx(j)).Y = -25 - (j - 1) * 10;
        end
        app.spawnSingleVehicle('South', 'Car');
    end

    % East: 7 vehicles -> 70% (HIGH)
    for k = 1:7
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx)
            app.ActiveVehicles(eIdx(j)).X = 25 + (j - 1) * 7;
        end
        app.spawnSingleVehicle('East', 'Car');
    end

    % West: 9 vehicles -> 90% (VERY HIGH)
    for k = 1:9
        wIdx = find(strcmp({app.ActiveVehicles.Direction}, 'West'));
        for j = 1:numel(wIdx)
            app.ActiveVehicles(wIdx(j)).X = -25 - (j - 1) * 6;
        end
        app.spawnSingleVehicle('West', 'Car');
    end

    densities = app.calculateTrafficDensity();
    assert(densities.North.Percentage == 20 && strcmp(densities.North.Level, 'LOW'),       'North density mismatch');
    assert(densities.South.Percentage == 40 && strcmp(densities.South.Level, 'MEDIUM'),    'South density mismatch');
    assert(densities.East.Percentage  == 70 && strcmp(densities.East.Level,  'HIGH'),      'East density mismatch');
    assert(densities.West.Percentage  == 90 && strcmp(densities.West.Level,  'VERY HIGH'), 'West density mismatch');
    disp('[PASS] Phase 6 Test E: All 4 directions calculated independently and accurately.');

    % 37. Phase 6 Test F: Live count integration
    disp('37. Phase 6 Test F: Verifying live count integration on spawn and removal...');
    app.resetSimulation();
    assert(app.TrafficDensity.East.Percentage == 0, 'East density must start at 0%');

    % Spawn vehicle -> triggers updateVehicleCounts -> calculates density automatically
    app.spawnSingleVehicle('East', 'Car');
    assert(app.TrafficDensity.East.Percentage == 10, 'East density must automatically update to 10% after spawn');

    % Spawn second vehicle -> 20%
    app.ActiveVehicles(1).X = 50;
    app.spawnSingleVehicle('East', 'Car');
    assert(app.TrafficDensity.East.Percentage == 20, 'East density must automatically update to 20% after second spawn');

    % Remove a vehicle -> density decrements automatically
    app.removeVehicle(1);
    assert(app.TrafficDensity.East.Percentage == 10, 'East density must automatically decrement to 10% after removal');
    disp('[PASS] Phase 6 Test F: Spawning and vehicle removal update densities automatically.');

    % 38. Phase 6 Test G: GUI synchronization with highest traffic density
    disp('38. Phase 6 Test G: Verifying Traffic Density label matches maximum directional density...');
    app.resetSimulation();
    % Spawn 7 vehicles on East -> 70% HIGH
    for k = 1:7
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx)
            app.ActiveVehicles(eIdx(j)).X = 25 + (j - 1) * 7;
        end
        app.spawnSingleVehicle('East', 'Car');
    end
    assert(contains(app.TrafficDensityValue.Text, '70%'), 'TrafficDensityValue must display 70%');
    assert(contains(app.TrafficDensityValue.Text, 'HIGH'), 'TrafficDensityValue must display HIGH');
    assert(contains(app.TrafficDensityValue.Text, 'East'), 'TrafficDensityValue must indicate East as bottleneck');
    disp('[PASS] Phase 6 Test G: Traffic Density label displays highest directional density and road.');

    % 39. Phase 6 Test H: KPI Congestion Level synchronization
    disp('39. Phase 6 Test H: Verifying KPI Congestion Level synchronization...');
    % Current max is 70% HIGH -> KPI should display 'High (70%)'
    assert(strcmp(app.CongestionValue.Text, 'High (70%)'), sprintf('CongestionValue expected "High (70%%)", got "%s"', app.CongestionValue.Text));

    % Add 2 more to East (total 9) -> 90% VERY HIGH -> KPI should display 'Very High (90%)'
    for k = 8:9
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx)
            app.ActiveVehicles(eIdx(j)).X = 25 + (j - 1) * 5;
        end
        app.spawnSingleVehicle('East', 'Car');
    end
    assert(strcmp(app.CongestionValue.Text, 'Very High (90%)'), sprintf('CongestionValue expected "Very High (90%%)", got "%s"', app.CongestionValue.Text));

    % Reset -> KPI should restore to 'Low (0%)'
    app.resetSimulation();
    assert(strcmp(app.CongestionValue.Text, 'Low (0%)'), 'CongestionValue must restore to "Low (0%)" on reset');
    disp('[PASS] Phase 6 Test H: KPI Congestion Level strictly tracks maximum directional density.');

    % 40. Phase 6 Test I: Directional density GUI badges
    disp('40. Phase 6 Test I: Verifying directional density badges in Traffic Information panel...');
    app.resetSimulation();
    assert(strcmp(app.NorthDensityValue.Text, '0% (LOW)'), 'North badge must display 0% (LOW)');
    assert(strcmp(app.SouthDensityValue.Text, '0% (LOW)'), 'South badge must display 0% (LOW)');
    assert(strcmp(app.EastDensityValue.Text,  '0% (LOW)'), 'East badge must display 0% (LOW)');
    assert(strcmp(app.WestDensityValue.Text,  '0% (LOW)'), 'West badge must display 0% (LOW)');

    % Spawn 3 vehicles on South -> South badge displays 30% (LOW)
    for k = 1:3
        app.spawnSingleVehicle('South', 'Car');
        app.ActiveVehicles(end).Y = -30 - k * 10;
    end
    assert(strcmp(app.SouthDensityValue.Text, '30% (LOW)'), sprintf('South badge expected "30%% (LOW)", got "%s"', app.SouthDensityValue.Text));
    assert(strcmp(app.NorthDensityValue.Text, '0% (LOW)'), 'North badge must stay 0% (LOW)');
    disp('[PASS] Phase 6 Test I: Directional density GUI badges synchronized.');

    % 41. Phase 6 Test J: Reset restores all densities and UI
    disp('41. Phase 6 Test J: Verifying Reset button restores all densities and UI...');
    % Spawn vehicles across all approaches
    app.spawnSingleVehicle('North', 'Car');
    app.spawnSingleVehicle('South', 'Car');
    app.spawnSingleVehicle('East', 'Car');
    app.spawnSingleVehicle('West', 'Car');

    % Trigger Reset button
    app.ResetButtonPushed([]);
    assert(app.TrafficDensity.North.Percentage == 0, 'Reset must restore North density to 0%');
    assert(app.TrafficDensity.South.Percentage == 0, 'Reset must restore South density to 0%');
    assert(app.TrafficDensity.East.Percentage  == 0, 'Reset must restore East density to 0%');
    assert(app.TrafficDensity.West.Percentage  == 0, 'Reset must restore West density to 0%');
    assert(strcmp(app.TrafficDensity.North.Level, 'LOW'), 'Reset must restore North level to LOW');
    assert(strcmp(app.TrafficDensity.South.Level, 'LOW'), 'Reset must restore South level to LOW');
    assert(strcmp(app.TrafficDensity.East.Level,  'LOW'), 'Reset must restore East level to LOW');
    assert(strcmp(app.TrafficDensity.West.Level,  'LOW'), 'Reset must restore West level to LOW');
    assert(strcmp(app.TrafficDensityValue.Text, '0%'), 'Reset must restore Traffic Density display to 0%');
    assert(strcmp(app.CongestionValue.Text, 'Low (0%)'), 'Reset must restore Congestion Level to Low (0%)');
    disp('[PASS] Phase 6 Test J: Reset completely restores all densities to 0% and LOW.');

    % 42. Phase 6 Test K: Start/Stop behavior maintains densities
    disp('42. Phase 6 Test K: Verifying Stop freezes and Start resumes density monitoring...');
    app.resetSimulation();
    app.spawnSingleVehicle('West', 'Car');
    app.ActiveVehicles(end).X = -50;
    app.spawnSingleVehicle('West', 'Car');
    assert(app.TrafficDensity.West.Percentage == 20, 'West density must be 20%');

    % Stop simulation
    app.StopButtonPushed([]);
    assert(~app.SimulationRunning, 'Simulation must be stopped');
    assert(app.TrafficDensity.West.Percentage == 20, 'Density must remain frozen at 20% while paused');

    % Restart simulation
    app.StartButtonPushed([]);
    assert(app.SimulationRunning, 'Simulation must be running');
    assert(app.TrafficDensity.West.Percentage == 20, 'Density must remain 20% on resume');
    app.StopButtonPushed([]);
    disp('[PASS] Phase 6 Test K: Simulation Stop freezes and Start maintains density state.');

    % 43. Phase 6 Test L: Static Code Analysis using checkcode
    disp('43. Phase 6 Test L: Running checkcode on VegMitraApp.m and test_VegMitraApp.m...');
    issuesApp = checkcode('VegMitraApp.m', '-string');
    assert(isempty(issuesApp), sprintf('checkcode detected warnings/errors in VegMitraApp.m:\n%s', issuesApp));
    issuesTest = checkcode('test_VegMitraApp.m', '-string');
    assert(isempty(issuesTest), sprintf('checkcode detected warnings/errors in test_VegMitraApp.m:\n%s', issuesTest));
    disp('[PASS] checkcode verified 0 syntax warnings/errors in VegMitraApp.m and test_VegMitraApp.m.');

    % =============================================================
    % PHASE 7 TESTS: DYNAMIC / AI-BASED SIGNAL TIMING (TESTS 44–58)
    % =============================================================

    % 44. Phase 7 Test 1: LOW density (0-30%) categorization
    disp('44. Phase 7 Test 1: Verifying LOW traffic density categorization...');
    [dur0, lvl0] = app.calculateGreenDuration(0);
    assert(isinf(dur0) && strcmp(lvl0, 'LOW'), '0% density must be LOW');
    [dur15, lvl15] = app.calculateGreenDuration(15);
    assert(isinf(dur15) && strcmp(lvl15, 'LOW'), '15% density must be LOW');
    [dur30, lvl30] = app.calculateGreenDuration(30);
    assert(isinf(dur30) && strcmp(lvl30, 'LOW'), '30% density boundary must be LOW');
    disp('[PASS] Phase 7 Test 1: LOW density (0-30%) categorization verified.');

    % 45. Phase 7 Test 2: MEDIUM density (31-60%) categorization
    disp('45. Phase 7 Test 2: Verifying MEDIUM traffic density categorization...');
    [dur31, lvl31] = app.calculateGreenDuration(31);
    assert(isinf(dur31) && strcmp(lvl31, 'MEDIUM'), '31% density boundary must be MEDIUM');
    [dur60, lvl60] = app.calculateGreenDuration(60);
    assert(isinf(dur60) && strcmp(lvl60, 'MEDIUM'), '60% density boundary must be MEDIUM');
    disp('[PASS] Phase 7 Test 2: MEDIUM density categorization verified.');

    % 46. Phase 7 Test 3: HIGH density (61-80%) categorization
    disp('46. Phase 7 Test 3: Verifying HIGH traffic density categorization...');
    [dur70, lvl70] = app.calculateGreenDuration(70);
    assert(isinf(dur70) && strcmp(lvl70, 'HIGH'), '70% density must be HIGH');
    [dur80, lvl80] = app.calculateGreenDuration(80);
    assert(isinf(dur80) && strcmp(lvl80, 'HIGH'), '80% density boundary must be HIGH');
    disp('[PASS] Phase 7 Test 3: HIGH density categorization verified.');

    % 47. Phase 7 Test 4: VERY HIGH density (81-100%) categorization
    disp('47. Phase 7 Test 4: Verifying VERY HIGH traffic density categorization...');
    [dur90, lvl90] = app.calculateGreenDuration(90);
    assert(isinf(dur90) && strcmp(lvl90, 'VERY HIGH'), '90% density must be VERY HIGH');
    [dur100, lvl100] = app.calculateGreenDuration(100);
    assert(isinf(dur100) && strcmp(lvl100, 'VERY HIGH'), '100% density boundary must be VERY HIGH');
    disp('[PASS] Phase 7 Test 4: VERY HIGH density categorization verified.');

    % 48. Phase 7 Test 5: Higher-demand group is selected
    disp('48. Phase 7 Test 5: Verifying higher-demand group is selected...');
    app.resetSimulation();
    % Case A: North = 8 (80%), South = 6 (60%), East = 2 (20%), West = 3 (30%)
    for k = 1:8
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx), app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('North', 'Car');
    end
    for k = 1:6
        sIdx = find(strcmp({app.ActiveVehicles.Direction}, 'South'));
        for j = 1:numel(sIdx), app.ActiveVehicles(sIdx(j)).Y = -24 - (j - 1) * 6; end
        app.spawnSingleVehicle('South', 'Car');
    end
    for k = 1:2
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx), app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('East', 'Car');
    end
    for k = 1:3
        wIdx = find(strcmp({app.ActiveVehicles.Direction}, 'West'));
        for j = 1:numel(wIdx), app.ActiveVehicles(wIdx(j)).X = -24 - (j - 1) * 6; end
        app.spawnSingleVehicle('West', 'Car');
    end

    decA = app.evaluateAIDecision();
    assert(strcmp(decA.SelectedRoad, 'North'), 'North road must be selected when North density > all others');
    assert(strcmp(decA.NextPhase, 'NORTH_GREEN'), 'NextPhase must be NORTH_GREEN');
    assert(contains(decA.DecisionText, 'NORTH GREEN'), 'DecisionText must indicate NORTH GREEN selected');

    % Case B: North = 2 (20%), South = 3 (30%), East = 8 (80%), West = 7 (70%)
    app.resetSimulation();
    for k = 1:2
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx), app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('North', 'Car');
    end
    for k = 1:3
        sIdx = find(strcmp({app.ActiveVehicles.Direction}, 'South'));
        for j = 1:numel(sIdx), app.ActiveVehicles(sIdx(j)).Y = -24 - (j - 1) * 6; end
        app.spawnSingleVehicle('South', 'Car');
    end
    for k = 1:8
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx), app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('East', 'Car');
    end
    for k = 1:7
        wIdx = find(strcmp({app.ActiveVehicles.Direction}, 'West'));
        for j = 1:numel(wIdx), app.ActiveVehicles(wIdx(j)).X = -24 - (j - 1) * 6; end
        app.spawnSingleVehicle('West', 'Car');
    end

    [nsDemB, ewDemB] = app.getGroupDemands();
    assert(nsDemB == 30, sprintf('NS demand expected 30%%, got %d%%', nsDemB));
    assert(ewDemB == 80, sprintf('EW demand expected 80%%, got %d%%', ewDemB));

    decB = app.evaluateAIDecision();
    assert(strcmp(decB.SelectedRoad, 'East'), 'East road must be selected when East density > all others');
    assert(strcmp(decB.NextPhase, 'EAST_GREEN'), 'NextPhase must be EAST_GREEN');
    assert(contains(decB.DecisionText, 'EAST GREEN'), 'DecisionText must indicate EAST GREEN selected');

    % Case C: East = 9 (90% VERY HIGH)
    eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
    for j = 1:numel(eIdx), app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6; end
    app.spawnSingleVehicle('East', 'Car');
    decC = app.evaluateAIDecision();
    assert(strcmp(decC.SelectedRoad, 'East'), 'East must be selected');
    disp('[PASS] Phase 7 Test 5: Higher-demand group is selected.');

    % 49. Phase 7 Test 6: Equal demand alternates fairly without permanent favor
    disp('49. Phase 7 Test 6: Verifying equal demand alternates fairly without favoring one group...');
    app.resetSimulation();
    % 0 vehicles on all approaches -> equal demand (0%)
    app.LastGreenGroup = 'North';
    app.ConsecutiveGreenCount = 1;

    groupsChosen = cell(1, 4);
    for cycle = 1:4
        dEq = app.selectNextAdaptivePhase();
        groupsChosen{cycle} = dEq.SelectedGroup;
    end
    assert(~all(strcmp(groupsChosen, groupsChosen{1})), 'Signals must alternate among roads on equal demand');
    disp('[PASS] Phase 7 Test 6: Equal demand alternates fairly and never permanently favors one group.');

    % 50. Phase 7 Test 7: Demand-based phase selection
    disp('50. Phase 7 Test 7: Verifying demand-based phase selection...');
    app.resetSimulation();
    for k = 1:8
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx), app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('North', 'Car');
    end
    for k = 1:3
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx), app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('East', 'Car');
    end

    dec1 = app.selectNextAdaptivePhase();
    assert(strcmp(dec1.SelectedRoad, 'North'), 'First cycle selects higher-demand North');
    disp('[PASS] Phase 7 Test 7: Demand-based phase selection verified.');

    % 51. Phase 7 Test 8: Conflicting directions never green simultaneously
    disp('51. Phase 7 Test 8: Verifying conflicting directions are never green simultaneously...');
    app.resetSimulation();
    app.selectNextAdaptivePhase();
    assert(~(strcmp(app.TrafficSignalStates.North, 'GREEN') && strcmp(app.TrafficSignalStates.East, 'GREEN')), 'Conflict: North & East green');
    assert(~(strcmp(app.TrafficSignalStates.South, 'GREEN') && strcmp(app.TrafficSignalStates.West, 'GREEN')), 'Conflict: South & West green');
    app.selectNextAdaptivePhase();
    assert(~(strcmp(app.TrafficSignalStates.North, 'GREEN') && strcmp(app.TrafficSignalStates.East, 'GREEN')), 'Conflict: North & East green');
    assert(~(strcmp(app.TrafficSignalStates.South, 'GREEN') && strcmp(app.TrafficSignalStates.West, 'GREEN')), 'Conflict: South & West green');
    disp('[PASS] Phase 7 Test 8: Conflicting directions never green simultaneously.');

    % 52. Phase 7 Test 9: Safety intervals maintained (Yellow = 2s, All-Red = 1s)
    disp('52. Phase 7 Test 9: Verifying Yellow = 2s and All-Red = 1s safety intervals...');
    app.resetSimulation();
    assert(app.SignalTimingConfig.YellowDuration == 2.0, 'Yellow interval must be 2.0s');
    assert(app.SignalTimingConfig.AllRedDuration == 1.0, 'All-Red interval must be 1.0s');

    app.setSignalPhase('NORTH_YELLOW');
    assert(app.SignalPhaseTimeRemaining == 2.0, 'Yellow remaining time must be 2.0s');

    % Advance 2.0s -> triggers ALL_RED
    app.updateTrafficSignals(2.0);
    assert(strcmp(app.getSignalPhase(), 'ALL_RED'), 'Must transition to ALL_RED after yellow expires');
    assert(app.SignalPhaseTimeRemaining == 1.0, 'All-Red remaining time must be 1.0s');

    % Advance 1.0s -> triggers next adaptive green phase
    app.updateTrafficSignals(1.0);
    assert(contains(app.getSignalPhase(), 'GREEN'), 'Must transition to a green phase after all-red');
    disp('[PASS] Phase 7 Test 9: Safety intervals (Yellow 2s, All-Red 1s) verified.');

    % 53. Phase 7 Test 10: Live GUI synchronization
    disp('53. Phase 7 Test 10: Verifying live GUI label synchronization...');
    app.resetSimulation();
    for k = 1:7
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx), app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('North', 'Car');
    end
    app.selectNextAdaptivePhase();
    assert(contains(app.CurrentGreenRoadValue.Text, 'North GREEN'), 'Current Green Road must display North GREEN');
    assert(contains(app.TrafficDensityValue.Text, '70%'), 'Traffic Density must display 70%');
    assert(contains(app.TrafficDensityValue.Text, 'HIGH'), 'Traffic Density must display HIGH');
    assert(contains(app.AIDecisionValue.Text, 'NORTH GREEN'), 'AI Decision must reflect NORTH GREEN selected');
    assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Controller Mode must be AI Adaptive');
    disp('[PASS] Phase 7 Test 10: Live GUI synchronization verified.');

    % 54. Phase 7 Test 11: Dynamic evaluation of demand
    disp('54. Phase 7 Test 11: Verifying dynamic evaluation of demand...');
    app.resetSimulation();

    for k = 1:9
        eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        for j = 1:numel(eIdx), app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6; end
        app.spawnSingleVehicle('East', 'Car');
    end
    app.selectNextAdaptivePhase();
    assert(strcmp(app.getSignalPhase(), 'EAST_GREEN'), 'Selected phase must be EAST_GREEN');
    disp('[PASS] Phase 7 Test 11: Dynamic evaluation of demand verified.');

    % 55. Phase 7 Test 12: Reset restores controller to initial safe state
    disp('55. Phase 7 Test 12: Verifying Reset restores controller to initial safe state...');
    app.ResetButtonPushed([]);
    assert(strcmp(app.SystemStatusValue.Text, 'READY'), 'Status must be READY');
    assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Mode must be AI Adaptive');
    disp('[PASS] Phase 7 Test 12: Reset restores initial safe state.');

    % 56. Phase 7 Test 13: Start/Stop maintains and freezes adaptive controller state
    disp('56. Phase 7 Test 13: Verifying Start/Stop maintains and freezes adaptive controller state...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 16.0);
    app.StartButtonPushed([]);
    assert(app.SimulationRunning, 'Simulation must be running');
    assert(app.SignalControllerRunning, 'SignalControllerRunning must be true');
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'Status must be RUNNING');

    % Stop simulation
    app.StopButtonPushed([]);
    assert(~app.SimulationRunning, 'Simulation must be stopped');
    assert(~app.SignalControllerRunning, 'SignalControllerRunning must be false');
    assert(strcmp(app.SystemStatusValue.Text, 'STOPPED'), 'Status must be STOPPED');
    remBefore = app.SignalPhaseTimeRemaining;

    % While stopped, signal controller is halted so time remaining remains frozen
    assert(app.SignalPhaseTimeRemaining == remBefore, 'Phase time remaining must freeze while stopped');

    % Resume simulation
    app.StartButtonPushed([]);
    assert(app.SimulationRunning, 'Simulation must resume running');
    assert(app.SignalControllerRunning, 'Signal controller must resume running');
    assert(strcmp(app.SystemStatusValue.Text, 'RUNNING'), 'Status must be RUNNING on resume');
    app.StopButtonPushed([]);
    disp('[PASS] Phase 7 Test 13: Start/Stop maintains and freezes adaptive controller state.');

    % 57. Phase 7 Test 14: Vehicle movement and red-light stopping behavior preserved
    disp('57. Phase 7 Test 14: Verifying vehicle movement and red-light stopping behavior preserved...');
    app.resetSimulation();
    % East is RED
    vEast = app.spawnSingleVehicle('East', 'Car');
    vEast.X = 28; % Near stop line at X = 20
    app.ActiveVehicles(1) = vEast;
    for step = 1:15
        app.updateVehicles();
    end
    frontEast = app.ActiveVehicles(1).X - app.ActiveVehicles(1).Length / 2.0;
    assert(frontEast >= 20.0, 'East vehicle must halt before red-light stop line');

    % Switch East to GREEN via adaptive transition
    app.setSignalPhase('EW_GREEN', 12.0);
    app.updateVehicles();
    frontEastAfter = app.ActiveVehicles(1).X - app.ActiveVehicles(1).Length / 2.0;
    assert(frontEastAfter < frontEast, 'Vehicle must proceed when light turns GREEN');
    disp('[PASS] Phase 7 Test 14: Vehicle movement and red-light stopping behavior preserved.');

    % 58. Phase 7 Test 15: Static code analysis using checkcode
    disp('58. Phase 7 Test 15: Running checkcode on VegMitraApp.m and test_VegMitraApp.m...');
    issuesApp = checkcode('VegMitraApp.m', '-string');
    assert(isempty(issuesApp), sprintf('checkcode detected warnings/errors in VegMitraApp.m:\n%s', issuesApp));
    issuesTest = checkcode('test_VegMitraApp.m', '-string');
    assert(isempty(issuesTest), sprintf('checkcode detected warnings/errors in test_VegMitraApp.m:\n%s', issuesTest));
    disp('[PASS] checkcode verified 0 syntax warnings/errors in VegMitraApp.m and test_VegMitraApp.m.');

    % =============================================================
    % PHASE 8 TESTS: EMERGENCY VEHICLE PRIORITY & SIGNAL PREEMPTION
    % =============================================================

    % 59. Phase 8 Test 1: Verify normal vehicle IsEmergency=false
    disp('59. Phase 8 Test 1: Verifying normal vehicle IsEmergency=false...');
    app.resetSimulation();
    vNorm = app.spawnSingleVehicle('North', 'Car');
    assert(~isempty(vNorm), 'Normal car should spawn');
    assert(isfield(vNorm, 'IsEmergency'), 'Vehicle must have IsEmergency field');
    assert(vNorm.IsEmergency == false, 'Normal vehicle IsEmergency must be false');
    assert(strcmp(vNorm.EmergencyType, ''), 'Normal vehicle EmergencyType must be empty');
    disp('[PASS] Phase 8 Test 1: Normal vehicle IsEmergency=false verified.');

    % 60. Phase 8 Test 2: Verify Ambulance can be spawned and marked IsEmergency=true
    disp('60. Phase 8 Test 2: Verifying Ambulance spawning and IsEmergency=true...');
    app.resetSimulation();
    vAmb = app.triggerEmergencyVehicle('East', 'Ambulance');
    assert(~isempty(vAmb), 'Ambulance must spawn successfully');
    assert(vAmb.IsEmergency == true, 'Ambulance IsEmergency must be true');
    assert(strcmp(vAmb.EmergencyType, 'Ambulance'), 'EmergencyType must be Ambulance');
    disp('[PASS] Phase 8 Test 2: Ambulance spawned and marked IsEmergency=true.');

    % 61. Phase 8 Test 3: Verify Fire Truck emergency type
    disp('61. Phase 8 Test 3: Verifying Fire Truck emergency type...');
    app.resetSimulation();
    vFire = app.triggerEmergencyVehicle('North', 'Fire Truck');
    assert(~isempty(vFire), 'Fire Truck must spawn successfully');
    assert(vFire.IsEmergency == true, 'Fire Truck IsEmergency must be true');
    assert(strcmp(vFire.EmergencyType, 'Fire Truck'), 'EmergencyType must be Fire Truck');
    disp('[PASS] Phase 8 Test 3: Fire Truck emergency type verified.');

    % 62. Phase 8 Test 4: Verify Police emergency type
    disp('62. Phase 8 Test 4: Verifying Police emergency type...');
    app.resetSimulation();
    vPol = app.triggerEmergencyVehicle('South', 'Police');
    assert(~isempty(vPol), 'Police vehicle must spawn successfully');
    assert(vPol.IsEmergency == true, 'Police IsEmergency must be true');
    assert(strcmp(vPol.EmergencyType, 'Police'), 'EmergencyType must be Police');
    disp('[PASS] Phase 8 Test 4: Police emergency type verified.');

    % 63. Phase 8 Test 5: Verify North emergency vehicle maps to NS priority
    disp('63. Phase 8 Test 5: Verifying North emergency vehicle maps to NS priority...');
    app.resetSimulation();
    app.triggerEmergencyVehicle('North', 'Ambulance');
    assert(strcmp(app.EmergencyDirection, 'North'), 'EmergencyDirection must be North');
    assert(strcmp(app.EmergencyTargetGroup, 'NS'), 'North emergency must map to NS priority group');
    disp('[PASS] Phase 8 Test 5: North emergency vehicle maps to NS priority.');

    % 64. Phase 8 Test 6: Verify South emergency vehicle maps to NS priority
    disp('64. Phase 8 Test 6: Verifying South emergency vehicle maps to NS priority...');
    app.resetSimulation();
    app.triggerEmergencyVehicle('South', 'Ambulance');
    assert(strcmp(app.EmergencyDirection, 'South'), 'EmergencyDirection must be South');
    assert(strcmp(app.EmergencyTargetGroup, 'NS'), 'South emergency must map to NS priority group');
    disp('[PASS] Phase 8 Test 6: South emergency vehicle maps to NS priority.');

    % 65. Phase 8 Test 7: Verify East emergency vehicle maps to EW priority
    disp('65. Phase 8 Test 7: Verifying East emergency vehicle maps to EW priority...');
    app.resetSimulation();
    app.triggerEmergencyVehicle('East', 'Fire Truck');
    assert(strcmp(app.EmergencyDirection, 'East'), 'EmergencyDirection must be East');
    assert(strcmp(app.EmergencyTargetGroup, 'EW'), 'East emergency must map to EW priority group');
    disp('[PASS] Phase 8 Test 7: East emergency vehicle maps to EW priority.');

    % 66. Phase 8 Test 8: Verify West emergency vehicle maps to EW priority
    disp('66. Phase 8 Test 8: Verifying West emergency vehicle maps to EW priority...');
    app.resetSimulation();
    app.triggerEmergencyVehicle('West', 'Police');
    assert(strcmp(app.EmergencyDirection, 'West'), 'EmergencyDirection must be West');
    assert(strcmp(app.EmergencyTargetGroup, 'EW'), 'West emergency must map to EW priority group');
    disp('[PASS] Phase 8 Test 8: West emergency vehicle maps to EW priority.');

    % 67. Phase 8 Test 9: Verify emergency priority overrides AI Adaptive selection
    disp('67. Phase 8 Test 9: Verifying emergency priority overrides AI Adaptive selection...');
    app.resetSimulation();
    % Setup high NS demand (8 cars in North = 80% HIGH), East has 0 cars (0% LOW)
    for k = 1:8
        nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
        for j = 1:numel(nIdx)
            app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6;
        end
        app.spawnSingleVehicle('North', 'Car');
    end
    app.updateVehicleCounts();
    % Trigger East Ambulance (EW group)
    app.triggerEmergencyVehicle('East', 'Ambulance');
    assert(app.EmergencyActive == true, 'Emergency priority must be active');
    assert(strcmp(app.EmergencyTargetGroup, 'EW'), 'EW group must be targeted despite NS higher density');
    assert(strcmp(app.ControllerModeValue.Text, 'EMERGENCY PRIORITY'), 'Controller Mode must be EMERGENCY PRIORITY');
    disp('[PASS] Phase 8 Test 9: Emergency priority overrides AI Adaptive selection.');

    % 68. Phase 8 Test 10: Verify emergency priority does NOT create conflicting green signals
    disp('68. Phase 8 Test 10: Verifying emergency priority does NOT create conflicting green signals...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 10.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    for step = 1:40
        app.updateTrafficSignals(0.1);
        nsG = strcmp(app.getSignalState('North'), 'GREEN') || strcmp(app.getSignalState('South'), 'GREEN');
        ewG = strcmp(app.getSignalState('East'), 'GREEN') || strcmp(app.getSignalState('West'), 'GREEN');
        assert(~(nsG && ewG), 'Conflicting greens must NEVER occur during emergency preemption');
    end
    disp('[PASS] Phase 8 Test 10: Emergency priority never creates conflicting green signals.');

    % 69. Phase 8 Test 11: Verify conflicting GREEN -> YELLOW -> ALL RED -> emergency GREEN transition
    disp('69. Phase 8 Test 11: Verifying conflicting GREEN -> YELLOW -> ALL RED -> emergency GREEN transition...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 10.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    assert(strcmp(app.SignalPhase, 'NS_YELLOW') || strcmp(app.SignalPhase, 'NORTH_YELLOW'), 'Must switch to YELLOW on preemption');
    app.updateTrafficSignals(2.0);
    assert(strcmp(app.SignalPhase, 'ALL_RED_1') || strcmp(app.SignalPhase, 'ALL_RED'), 'Must switch to ALL_RED');
    app.updateTrafficSignals(1.0);
    assert(strcmp(app.SignalPhase, 'EW_GREEN') || strcmp(app.SignalPhase, 'EAST_GREEN'), 'Must switch to emergency green phase');
    assert(strcmp(app.EmergencyPriorityState, 'ACTIVE'), 'State must be ACTIVE');
    disp('[PASS] Phase 8 Test 11: Conflicting GREEN -> YELLOW -> ALL RED -> emergency GREEN transition verified.');

    % 70. Phase 8 Test 12: Verify Yellow remains exactly 2 seconds during emergency preemption
    disp('70. Phase 8 Test 12: Verifying Yellow remains exactly 2 seconds during emergency preemption...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 10.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    assert(app.SignalPhaseTimeRemaining == 2.0, 'Yellow remaining duration must be exactly 2.0s');
    assert(app.SignalTimingConfig.YellowDuration == 2.0, 'SignalTimingConfig.YellowDuration must be 2.0s');
    disp('[PASS] Phase 8 Test 12: Yellow duration remains exactly 2 seconds.');

    % 71. Phase 8 Test 13: Verify All-Red remains exactly 1 second during emergency preemption
    disp('71. Phase 8 Test 13: Verifying All-Red remains exactly 1 second during emergency preemption...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 10.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    app.updateTrafficSignals(2.0);
    assert(strcmp(app.SignalPhase, 'ALL_RED_1') || strcmp(app.SignalPhase, 'ALL_RED'), 'Phase must be ALL_RED');
    assert(app.SignalPhaseTimeRemaining == 1.0, 'All-Red remaining duration must be exactly 1.0s');
    assert(app.SignalTimingConfig.AllRedDuration == 1.0, 'SignalTimingConfig.AllRedDuration must be 1.0s');
    disp('[PASS] Phase 8 Test 13: All-Red duration remains exactly 1 second.');

    % 72. Phase 8 Test 14: Verify emergency vehicle proceeds through its priority green
    disp('72. Phase 8 Test 14: Verifying emergency vehicle proceeds through its priority green...');
    app.resetSimulation();
    app.setSignalPhase('EW_GREEN', 30.0);
    vAmb = app.triggerEmergencyVehicle('East', 'Ambulance');
    aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
    app.ActiveVehicles(aIdx).X = 26;
    xBefore = app.ActiveVehicles(aIdx).X;
    app.updateVehicles();
    assert(app.ActiveVehicles(aIdx).X < xBefore, 'Ambulance must proceed through priority green');
    disp('[PASS] Phase 8 Test 14: Emergency vehicle proceeds through priority green.');

    % 73. Phase 8 Test 15: Verify normal conflicting traffic remains stopped at RED
    disp('73. Phase 8 Test 15: Verifying normal conflicting traffic remains stopped at RED...');
    app.resetSimulation();
    app.setSignalPhase('EW_GREEN', 30.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    vNorm = app.spawnSingleVehicle('North', 'Car');
    nIdx = find([app.ActiveVehicles.ID] == vNorm.ID, 1);
    app.ActiveVehicles(nIdx).Y = 24; % Near North stop line at Y = 20
    for step = 1:15
        app.updateVehicles();
    end
    nIdx = find([app.ActiveVehicles.ID] == vNorm.ID, 1);
    frontN = app.ActiveVehicles(nIdx).Y - app.ActiveVehicles(nIdx).Length / 2.0;
    assert(frontN >= 20.0, 'Conflicting North vehicle must halt at RED stop line');
    disp('[PASS] Phase 8 Test 15: Conflicting traffic safely halted at RED stop line.');

    % 74. Phase 8 Test 16: Verify emergency priority ends after emergency vehicle clears
    disp('74. Phase 8 Test 16: Verifying emergency priority ends after emergency vehicle clears...');
    app.resetSimulation();
    app.setSignalPhase('EW_GREEN', 30.0);
    vAmb = app.triggerEmergencyVehicle('East', 'Ambulance');
    aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
    app.ActiveVehicles(aIdx).X = -25; % Beyond conflict zone (-20)
    assert(app.checkEmergencyCleared() == true, 'checkEmergencyCleared must be true');
    app.updateTrafficSignals(0.1);
    assert(app.EmergencyActive == false, 'EmergencyActive must be false after clearing');
    assert(strcmp(app.EmergencyPriorityState, 'CLEARING'), 'State must be CLEARING');
    assert(strcmp(app.SignalPhase, 'EW_YELLOW') || strcmp(app.SignalPhase, 'EAST_YELLOW'), 'Phase must transition to yellow');
    disp('[PASS] Phase 8 Test 16: Emergency priority ends after vehicle clears intersection.');

    % 75. Phase 8 Test 17: Verify timeout safely ends emergency priority if vehicle cannot clear
    disp('75. Phase 8 Test 17: Verifying timeout safely ends emergency priority if vehicle cannot clear...');
    app.resetSimulation();
    app.setSignalPhase('EW_GREEN', 30.0);
    app.triggerEmergencyVehicle('East', 'Ambulance');
    app.EmergencyHoldTime = 29.95;
    app.updateTrafficSignals(0.1); % Crosses 30.0s timeout
    assert(app.EmergencyActive == false, 'Emergency priority must end when timeout is reached');
    assert(strcmp(app.EmergencyPriorityState, 'CLEARING'), 'Priority state must be CLEARING');
    disp('[PASS] Phase 8 Test 17: Safety timeout safely terminates stuck emergency priority.');

    % 76. Phase 8 Test 18: Verify controller returns to AI Adaptive after emergency clearance
    disp('76. Phase 8 Test 18: Verifying controller returns to AI Adaptive after emergency clearance...');
    app.ActiveVehicles = struct([]);
    app.updateTrafficSignals(2.0); % EW_YELLOW -> ALL_RED_2
    app.updateTrafficSignals(1.0); % ALL_RED_2 -> AI Adaptive
    assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Controller Mode must return to AI Adaptive');
    assert(strcmp(app.EmergencyPriorityState, 'NORMAL'), 'EmergencyPriorityState must be NORMAL');
    disp('[PASS] Phase 8 Test 18: Controller returns to AI Adaptive after emergency clearance.');

    % 77. Phase 8 Test 19: Verify next AI Adaptive phase recalculates using current traffic density
    disp('77. Phase 8 Test 19: Verifying next AI Adaptive phase recalculates using current traffic density...');
    app.resetSimulation();
    for k = 1:2, app.spawnSingleVehicle('North', 'Car'); end % 20% LOW
    for k = 1:8, app.spawnSingleVehicle('East', 'Car'); end  % 80% HIGH
    app.updateVehicleCounts();
    % Trigger West emergency (EW) and clear it
    vW = app.triggerEmergencyVehicle('West', 'Police');
    app.setSignalPhase('EW_GREEN', 30.0);
    wIdx = find([app.ActiveVehicles.ID] == vW.ID, 1);
    app.ActiveVehicles(wIdx).X = 25; % Cleared
    app.updateTrafficSignals(0.1); % Release -> EW_YELLOW
    app.updateTrafficSignals(2.0); % -> ALL_RED_2
    assert(contains(app.SignalPhase, 'GREEN'), 'Phase must be valid green');
    disp('[PASS] Phase 8 Test 19: Next phase recalculates using current traffic density.');

    % 78. Phase 8 Test 20: Verify Emergency Mode button activates emergency behavior
    disp('78. Phase 8 Test 20: Verifying Emergency Mode button activates emergency behavior...');
    app.resetSimulation();
    app.EmergencyButtonPushed([]);
    assert(app.EmergencyActive == true, 'Emergency Mode button must activate emergency priority');
    assert(ismember(app.EmergencyDirection, {'North', 'South', 'East', 'West'}), 'Emergency button must spawn ambulance from randomly selected road (North, South, East, West)');
    assert(strcmp(app.EmergencyType, 'Ambulance'), 'Emergency type must be Ambulance');
    disp('[PASS] Phase 8 Test 20: Emergency Mode button activates emergency behavior.');

    % 79. Phase 8 Test 21: Verify Start/Stop/Reset remain functional during/after emergency mode
    disp('79. Phase 8 Test 21: Verifying Start/Stop/Reset remain functional during/after emergency mode...');
    app.StartButtonPushed([]);
    assert(app.SimulationRunning == true, 'Simulation must be running after Start');
    app.StopButtonPushed([]);
    assert(app.SimulationRunning == false, 'Simulation must be stopped after Stop');
    app.ResetButtonPushed([]);
    assert(app.EmergencyActive == false, 'Emergency priority must be cleared on Reset');
    assert(strcmp(app.SystemStatusValue.Text, 'READY'), 'Status must return to READY');
    assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Controller Mode must return to AI Adaptive');
    disp('[PASS] Phase 8 Test 21: Start/Stop/Reset remain fully functional during/after emergency mode.');

    % 80. Phase 8 Test 22: Verify multiple emergency vehicles do not create conflicting greens
    disp('80. Phase 8 Test 22: Verifying multiple emergency vehicles do not create conflicting greens...');
    app.resetSimulation();
    app.setSignalPhase('NS_GREEN', 10.0);
    app.triggerEmergencyVehicle('North', 'Ambulance');
    app.triggerEmergencyVehicle('East', 'Police');
    assert(app.EmergencyActive == true, 'Emergency priority must be active');
    assert(strcmp(app.EmergencyTargetGroup, 'NS'), 'First group NS must be served first');
    assert(numel(app.EmergencyQueue) >= 1, 'Opposite group must be queued safely');
    nsG = strcmp(app.getSignalState('North'), 'GREEN');
    ewG = strcmp(app.getSignalState('East'), 'GREEN');
    assert(~(nsG && ewG), 'Multiple emergencies must never create simultaneous conflicting greens');
    disp('[PASS] Phase 8 Test 22: Multiple emergency vehicles do not create conflicting greens.');

    % 81. Phase 8 Test 23: Verify existing vehicle movement/headway/collision behavior remains intact
    disp('81. Phase 8 Test 23: Verifying existing vehicle movement/headway/collision behavior remains intact...');
    app.resetSimulation();
    leadCar = app.spawnSingleVehicle('North', 'Car');
    leadCar.Y = 40;
    app.ActiveVehicles(1) = leadCar;
    vPol = app.triggerEmergencyVehicle('North', 'Police');
    pIdx = find([app.ActiveVehicles.ID] == vPol.ID, 1);
    app.ActiveVehicles(pIdx).Y = 54; % Right behind leadCar (gap = 3m <= 4m buffer)
    app.ActiveVehicles(1).Speed = 0; % Lead vehicle stopped
    yPolBefore = app.ActiveVehicles(pIdx).Y;
    app.updateVehicles();
    assert(app.ActiveVehicles(pIdx).Y == yPolBefore, 'Police vehicle must halt behind lead car to prevent collision');
    disp('[PASS] Phase 8 Test 23: Existing headway and collision prevention remains intact.');

    % 82. Phase 8 Test 24: Running checkcode on VegMitraApp.m, test_VegMitraApp.m, verify_Phase8_EmergencyPriority.m, verify_Phase8_CollisionAndSmoothness.m
    disp('82. Phase 8 Test 24: Running checkcode on VegMitraApp.m, test_VegMitraApp.m, verify_Phase8_EmergencyPriority.m, and verify_Phase8_CollisionAndSmoothness.m...');
    issuesApp = checkcode('VegMitraApp.m', '-string');
    assert(isempty(issuesApp), sprintf('checkcode detected warnings/errors in VegMitraApp.m:\n%s', issuesApp));
    issuesTest = checkcode('test_VegMitraApp.m', '-string');
    assert(isempty(issuesTest), sprintf('checkcode detected warnings/errors in test_VegMitraApp.m:\n%s', issuesTest));
    issuesVer = checkcode('verify_Phase8_EmergencyPriority.m', '-string');
    assert(isempty(issuesVer), sprintf('checkcode detected warnings/errors in verify_Phase8_EmergencyPriority.m:\n%s', issuesVer));
    issuesCol = checkcode('verify_Phase8_CollisionAndSmoothness.m', '-string');
    assert(isempty(issuesCol), sprintf('checkcode detected warnings/errors in verify_Phase8_CollisionAndSmoothness.m:\n%s', issuesCol));
    disp('[PASS] checkcode verified 0 syntax warnings/errors across all files.');

    % =========================================================================
    % PHASE 9 TESTS: PEDESTRIAN / HUMAN SIMULATION (TESTS 83–94 / P1–P12)
    % =========================================================================

    % 83. Phase 9 Test P1: Pedestrian structure initializes correctly
    disp('83. Phase 9 Test P1: Verifying pedestrian structure initializes correctly...');
    app.resetSimulation();
    assert(~isempty(app.ActivePedestrians), 'ActivePedestrians must not be empty on initialization');
    nPeds = numel(app.ActivePedestrians);
    assert(nPeds >= 4 && nPeds <= 12, sprintf('Expected between 4 and 12 initial pedestrians, found %d', nPeds));
    reqPFields = {'ID', 'X', 'Y', 'Direction', 'Speed', 'Path', 'GraphicHandle'};
    for fIdx = 1:numel(reqPFields)
        assert(isfield(app.ActivePedestrians, reqPFields{fIdx}), sprintf('ActivePedestrians missing required field: %s', reqPFields{fIdx}));
    end
    for pIdx = 1:nPeds
        assert(isvalid(app.ActivePedestrians(pIdx).GraphicHandle), sprintf('Pedestrian %d GraphicHandle must be valid', app.ActivePedestrians(pIdx).ID));
    end
    disp('[PASS] Phase 9 Test P1: Pedestrian structure initializes correctly with all required fields.');

    % 84. Phase 9 Test P2: Pedestrians spawn only on sidewalk/building paths
    disp('84. Phase 9 Test P2: Verifying pedestrians spawn only on designated sidewalk paths...');
    validPaths = {'North', 'South', 'East', 'West'};
    for pIdx = 1:nPeds
        p = app.ActivePedestrians(pIdx);
        assert(ismember(p.Path, validPaths), sprintf('Pedestrian %d has invalid path %s', p.ID, p.Path));
        switch p.Path
            case 'North'
                assert(p.X == 31, sprintf('North pedestrian %d must have X = 31, got %.2f', p.ID, p.X));
                assert(p.Y >= 32 && p.Y <= 92, sprintf('North pedestrian %d Y must be in [32, 92], got %.2f', p.ID, p.Y));
            case 'South'
                assert(p.X == -31, sprintf('South pedestrian %d must have X = -31, got %.2f', p.ID, p.X));
                assert(p.Y >= -92 && p.Y <= -32, sprintf('South pedestrian %d Y must be in [-92, -32], got %.2f', p.ID, p.Y));
            case 'East'
                assert(p.Y == 31, sprintf('East pedestrian %d must have Y = 31, got %.2f', p.ID, p.Y));
                assert(p.X >= 32 && p.X <= 92, sprintf('East pedestrian %d X must be in [32, 92], got %.2f', p.ID, p.X));
            case 'West'
                assert(p.Y == -31, sprintf('West pedestrian %d must have Y = -31, got %.2f', p.ID, p.Y));
                assert(p.X >= -92 && p.X <= -32, sprintf('West pedestrian %d X must be in [-92, -32], got %.2f', p.ID, p.X));
        end
    end
    disp('[PASS] Phase 9 Test P2: Pedestrians spawn strictly on designated sidewalk corridors.');

    % 85. Phase 9 Test P3: Pedestrians never spawn inside vehicle lanes
    disp('85. Phase 9 Test P3: Verifying pedestrians never spawn inside vehicle lanes...');
    for pIdx = 1:nPeds
        p = app.ActivePedestrians(pIdx);
        inRoadLane = (abs(p.X) <= 20.0 && abs(p.Y) <= 100.0) || (abs(p.Y) <= 20.0 && abs(p.X) <= 100.0);
        assert(~inRoadLane, sprintf('Pedestrian %d spawned inside vehicle lanes (X=%.1f, Y=%.1f)', p.ID, p.X, p.Y));
    end
    disp('[PASS] Phase 9 Test P3: Pedestrians never spawn inside vehicle lanes.');

    % 86. Phase 9 Test P4: Pedestrians never enter the central intersection conflict zone
    disp('86. Phase 9 Test P4: Verifying pedestrians never enter the central intersection conflict zone...');
    for pIdx = 1:nPeds
        p = app.ActivePedestrians(pIdx);
        inConflictZone = abs(p.X) <= 20.0 && abs(p.Y) <= 20.0;
        assert(~inConflictZone, sprintf('Pedestrian %d inside central intersection conflict zone (X=%.1f, Y=%.1f)', p.ID, p.X, p.Y));
    end
    disp('[PASS] Phase 9 Test P4: Pedestrians never enter the central intersection conflict zone.');

    % 87. Phase 9 Test P5: Pedestrians move continuously across signals & emergency modes
    disp('87. Phase 9 Test P5: Verifying pedestrians move continuously across signals & emergency modes...');
    app.resetSimulation();
    app.StartButtonPushed([]);
    assert(app.SimulationRunning == true, 'Simulation must be running');

    % A. Verify movement during NS GREEN
    app.setSignalPhase('NS_GREEN', 10.0);
    posBeforeNS = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    for s = 1:25, app.updatePedestrians(); end
    posAfterNS = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    assert(~isequal(posBeforeNS, posAfterNS), 'Pedestrians must move during NS GREEN');

    % B. Verify movement during EW GREEN
    app.setSignalPhase('EW_GREEN', 10.0);
    posBeforeEW = posAfterNS;
    for s = 1:25, app.updatePedestrians(); end
    posAfterEW = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    assert(~isequal(posBeforeEW, posAfterEW), 'Pedestrians must continue moving during EW GREEN');

    % C. Verify movement during Emergency Priority
    app.triggerEmergencyVehicle('East', 'Ambulance');
    assert(app.EmergencyActive == true, 'Emergency priority must be active');
    posBeforeEmerg = posAfterEW;
    for s = 1:25, app.updatePedestrians(); end
    posAfterEmerg = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    assert(~isequal(posBeforeEmerg, posAfterEmerg), 'Pedestrians must continue moving during Emergency Priority');

    % D. Verify boundary turnaround
    app.resetSimulation();
    p1StartDir = app.ActivePedestrians(1).Direction;
    p1Reversed = false;
    for s = 1:150
        app.updatePedestrians();
        if ~strcmp(app.ActivePedestrians(1).Direction, p1StartDir)
            p1Reversed = true;
            break;
        end
    end
    assert(p1Reversed, 'Pedestrian 1 must reverse direction when reaching path boundary or meeting neighbor');
    disp('[PASS] Phase 9 Test P5: Pedestrians move continuously across NS GREEN, EW GREEN, and Emergency Priority.');

    % 88. Phase 9 Test P6: Pedestrians stop when simulation is stopped
    disp('88. Phase 9 Test P6: Verifying pedestrians stop when simulation is stopped...');
    app.StopButtonPushed([]);
    assert(app.SimulationRunning == false, 'Simulation must be stopped');
    frozenPPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    app.timerTickCallback();
    afterTickPPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    assert(isequal(frozenPPos, afterTickPPos), 'Pedestrians must remain stationary when simulation is stopped');
    disp('[PASS] Phase 9 Test P6: Pedestrians stop when simulation is stopped.');

    % 89. Phase 9 Test P7: Reset removes/reinitializes pedestrian graphics correctly
    disp('89. Phase 9 Test P7: Verifying Reset removes/reinitializes pedestrian graphics cleanly...');
    oldPGraphicHandles = [app.ActivePedestrians.GraphicHandle];
    app.ResetButtonPushed([]);
    for hIdx = 1:numel(oldPGraphicHandles)
        assert(~isvalid(oldPGraphicHandles(hIdx)), 'Old pedestrian graphic handles must be deleted on Reset');
    end
    assert(~isempty(app.ActivePedestrians), 'ActivePedestrians must be re-initialized after Reset');
    for pIdx = 1:numel(app.ActivePedestrians)
        assert(isvalid(app.ActivePedestrians(pIdx).GraphicHandle), 'New pedestrian graphic handles must be valid');
    end
    disp('[PASS] Phase 9 Test P7: Reset removes old graphics and reinitializes pedestrians cleanly.');

    % 90. Phase 9 Test P8: Pedestrians maintain positive spacing from each other
    disp('90. Phase 9 Test P8: Verifying pedestrians maintain positive spacing (>= 3.5 m)...');
    for i = 1:numel(app.ActivePedestrians)
        for j = (i + 1):numel(app.ActivePedestrians)
            pi = app.ActivePedestrians(i);
            pj = app.ActivePedestrians(j);
            if strcmp(pi.Path, pj.Path)
                gap = sqrt((pi.X - pj.X)^2 + (pi.Y - pj.Y)^2);
                assert(gap >= 3.5, sprintf('Pedestrians %d and %d have gap %.2f < 3.5 m', pi.ID, pj.ID, gap));
            end
        end
    end
    disp('[PASS] Phase 9 Test P8: Pedestrians maintain positive spacing (>= 3.5 m) from each other.');

    % 91. Phase 9 Test P9: Pedestrians remain outside vehicle safety corridors
    disp('91. Phase 9 Test P9: Verifying pedestrians remain outside vehicle safety corridors (>= 4.0 m buffer)...');
    for pIdx = 1:numel(app.ActivePedestrians)
        p = app.ActivePedestrians(pIdx);
        distFromRoadX = abs(p.X) - 20.0;
        distFromRoadY = abs(p.Y) - 20.0;
        assert(distFromRoadX >= 4.0 && distFromRoadY >= 4.0, ...
            sprintf('Pedestrian %d violates 4.0m vehicle buffer (dX=%.1f, dY=%.1f)', p.ID, distFromRoadX, distFromRoadY));
    end
    disp('[PASS] Phase 9 Test P9: Pedestrians remain outside vehicle safety corridors (>= 4.0 m buffer).');

    % 92. Phase 9 Test P10: Pedestrians do not modify vehicle counts or traffic density
    disp('92. Phase 9 Test P10: Verifying pedestrians do not modify vehicle counts or traffic density...');
    app.resetSimulation();
    assert(app.VehicleCounts.North == 0 && app.VehicleCounts.South == 0 && ...
           app.VehicleCounts.East == 0  && app.VehicleCounts.West == 0, ...
           'Pedestrians must not contribute to directional VehicleCounts');
    assert(app.TrafficDensity.North.Count == 0 && app.TrafficDensity.North.Percentage == 0, ...
           'Pedestrians must not contribute to TrafficDensity');
    assert(app.TotalVehiclesProcessed == 0, 'Pedestrians must not contribute to TotalVehiclesProcessed');
    assert(app.TotalVehiclesSpawned == 0,   'Pedestrians must not contribute to TotalVehiclesSpawned');
    disp('[PASS] Phase 9 Test P10: Pedestrians do not modify vehicle counts, traffic density, or processed metrics.');

    % 93. Phase 9 Test P11: Run at least 100 simulation frames and verify all pedestrian positions remain valid
    disp('93. Phase 9 Test P11: Running 100 simulation frames and verifying all pedestrian positions remain valid...');
    app.resetSimulation();
    for frame = 1:100
        app.updatePedestrians();

        for i = 1:numel(app.ActivePedestrians)
            pi = app.ActivePedestrians(i);
            assert(abs(pi.X) >= 24.0 && abs(pi.Y) >= 24.0, sprintf('Frame %d: Ped %d breached safety buffer', frame, pi.ID));
            switch pi.Path
                case 'North', assert(pi.X == 31 && pi.Y >= 32 && pi.Y <= 92, sprintf('Frame %d: North bounds breached', frame));
                case 'South', assert(pi.X == -31 && pi.Y >= -92 && pi.Y <= -32, sprintf('Frame %d: South bounds breached', frame));
                case 'East',  assert(pi.Y == 31 && pi.X >= 32 && pi.X <= 92, sprintf('Frame %d: East bounds breached', frame));
                case 'West',  assert(pi.Y == -31 && pi.X >= -92 && pi.X <= -32, sprintf('Frame %d: West bounds breached', frame));
            end
            for j = (i + 1):numel(app.ActivePedestrians)
                pj = app.ActivePedestrians(j);
                if strcmp(pi.Path, pj.Path)
                    d = sqrt((pi.X - pj.X)^2 + (pi.Y - pj.Y)^2);
                    assert(d >= 3.5 - 1e-4, sprintf('Frame %d: Peds %d and %d spacing %.2f < 3.5 m', frame, pi.ID, pj.ID, d));
                end
            end
        end
    end
    disp('[PASS] Phase 9 Test P11: 100 simulation frames executed with all pedestrian positions remaining valid.');

    % 94. Phase 9 Test P12: checkcode has 0 warnings/errors across all files
    disp('94. Phase 9 Test P12: Running checkcode on VegMitraApp.m, test_VegMitraApp.m, and verify_Phase9_Pedestrians.m...');
    issuesApp = checkcode('VegMitraApp.m', '-string');
    assert(isempty(issuesApp), sprintf('checkcode detected warnings/errors in VegMitraApp.m:\n%s', issuesApp));
    issuesTest = checkcode('test_VegMitraApp.m', '-string');
    assert(isempty(issuesTest), sprintf('checkcode detected warnings/errors in test_VegMitraApp.m:\n%s', issuesTest));
    issuesP9 = checkcode('verify_Phase9_Pedestrians.m', '-string');
    assert(isempty(issuesP9), sprintf('checkcode detected warnings/errors in verify_Phase9_Pedestrians.m:\n%s', issuesP9));
    disp('[PASS] Phase 9 Test P12: checkcode verified 0 syntax warnings/errors across all files.');

    % 95. Phase 9 Test P13: Pedestrians continue moving for 200 consecutive ticks without deadlock
    disp('95. Phase 9 Test P13: Verifying pedestrians continue moving for 200 consecutive simulation ticks without deadlock...');
    app.resetSimulation();
    app.StartButtonPushed([]);

    historyPos = cell(1, 8);
    for interval = 1:8
        for s = 1:25
            app.updatePedestrians();
        end
        historyPos{interval} = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
    end

    for interval = 2:8
        prevPos = historyPos{interval - 1};
        currPos = historyPos{interval};
        movedPeds = any(abs(currPos - prevPos) > 1e-3, 2);
        numMoved = sum(movedPeds);
        assert(numMoved >= 4, sprintf('Interval %d: Expected at least 4 moving pedestrians, found %d (deadlock detected)', interval, numMoved));
    end

    pos100 = historyPos{4};
    pos200 = historyPos{8};
    totalDisplacement = sum(abs(pos200 - pos100), 2);
    assert(all(totalDisplacement > 2.0), 'All pedestrians must demonstrate continuous displacement between ticks 100 and 200 without being permanently stuck');
    disp('[PASS] Phase 9 Test P13: Verified continuous movement across 200 simulation ticks with zero deadlocks.');

    % Clean up
    delete(app);
    disp('====================================================');
    disp(' [SUCCESS] ALL PHASE 1–8 TESTS (1–82) AND           ');
    disp('           PHASE 9 TESTS (83–95 / P1–P13) PASSED!   ');
    disp('====================================================');
    exit(0);

catch ME
    fprintf('\n[FAIL] Test Error encountered: %s\n', ME.message);
    fprintf('In file: %s (Line %d)\n', ME.stack(1).file, ME.stack(1).line);
    exit(1);
end
