classdef VegMitraApp < matlab.apps.AppBase
    % VegMitraApp - AI Based Smart Traffic Light Management System Dashboard
    % Phase 1: MATLAB App Designer UI Implementation
    % Phase 2: Four-Road Intersection Implementation
    % Phase 3: Moving Vehicles & Simulation Engine
    % Phase 4: Traffic Signals & Controller
    % Phase 5: Directional Vehicle Counting & Approach Tracking
    % Phase 6: Traffic Density Calculation & Congestion Monitoring

    % Properties representing UI components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        MainGridLayout              matlab.ui.container.GridLayout
        
        % Header Components
        HeaderPanel                 matlab.ui.container.Panel
        HeaderGrid                  matlab.ui.container.GridLayout
        TitleLabel                  matlab.ui.control.Label
        SubtitleLabel               matlab.ui.control.Label
        
        % Middle Section Containers
        MiddleGrid                  matlab.ui.container.GridLayout
        
        % Left Column: Traffic Simulation Canvas
        SimulationPanel             matlab.ui.container.Panel
        SimulationGrid              matlab.ui.container.GridLayout
        SimSubLabel                 matlab.ui.control.Label
        SimulationCanvas            matlab.ui.control.UIAxes
        
        % Right Column Container
        RightPanel                  matlab.ui.container.Panel
        RightGrid                   matlab.ui.container.GridLayout
        
        % Traffic Information Panel
        InfoPanel                   matlab.ui.container.Panel
        InfoGrid                    matlab.ui.container.GridLayout
        NorthVehiclesLabel          matlab.ui.control.Label
        NorthVehiclesValue          matlab.ui.control.Label
        NorthDensityValue           matlab.ui.control.Label
        SouthVehiclesLabel          matlab.ui.control.Label
        SouthVehiclesValue          matlab.ui.control.Label
        SouthDensityValue           matlab.ui.control.Label
        EastVehiclesLabel           matlab.ui.control.Label
        EastVehiclesValue           matlab.ui.control.Label
        EastDensityValue            matlab.ui.control.Label
        WestVehiclesLabel           matlab.ui.control.Label
        WestVehiclesValue           matlab.ui.control.Label
        WestDensityValue            matlab.ui.control.Label
        CurrentGreenRoadLabel       matlab.ui.control.Label
        CurrentGreenRoadValue       matlab.ui.control.Label
        CurrentGreenTimeLabel       matlab.ui.control.Label
        CurrentGreenTimeValue       matlab.ui.control.Label
        TrafficDensityLabel         matlab.ui.control.Label
        TrafficDensityValue         matlab.ui.control.Label
        AIDecisionLabel             matlab.ui.control.Label
        AIDecisionValue             matlab.ui.control.Label
        
        % Control Panel
        ControlPanel                matlab.ui.container.Panel
        ControlGrid                 matlab.ui.container.GridLayout
        StartButton                 matlab.ui.control.Button
        StopButton                  matlab.ui.control.Button
        ResetButton                 matlab.ui.control.Button
        EmergencyButton             matlab.ui.control.Button
        
        % Status Panel
        StatusPanel                 matlab.ui.container.Panel
        StatusGrid                  matlab.ui.container.GridLayout
        SystemStatusLabel           matlab.ui.control.Label
        SystemStatusValue           matlab.ui.control.Label
        ControllerModeLabel         matlab.ui.control.Label
        ControllerModeValue         matlab.ui.control.Label
        
        % Bottom Row: KPI Panel
        KPIPanel                    matlab.ui.container.Panel
        KPIGrid                     matlab.ui.container.GridLayout
        AvgWaitCard                 matlab.ui.container.Panel
        AvgWaitTitle                matlab.ui.control.Label
        AvgWaitValue                matlab.ui.control.Label
        VehiclesProcessedCard       matlab.ui.container.Panel
        VehiclesProcessedTitle      matlab.ui.control.Label
        VehiclesProcessedValue      matlab.ui.control.Label
        CongestionCard              matlab.ui.container.Panel
        CongestionTitle             matlab.ui.control.Label
        CongestionValue             matlab.ui.control.Label
        FuelSavedCard               matlab.ui.container.Panel
        FuelSavedTitle              matlab.ui.control.Label
        FuelSavedValue              matlab.ui.control.Label

        % Phase 2 Properties: Intersection Configurations & Storage
        IntersectionConfig          struct

        % Phase 3 Properties: Moving Vehicles & Simulation Engine
        ActiveVehicles              struct = struct([])
        NextVehicleID               double = 1
        SimulationTimer
        SpawnSettings               struct
        TotalVehiclesSpawned        double = 0
        TotalVehiclesProcessed      double = 0
        TotalWaitTimeAccumulated    double = 0
        SimulationRunning           logical = false
        StepCount                   double = 0

        % Phase 4 Properties: Traffic Signals & Controller
        TrafficSignalStates         struct
        TrafficSignalGraphics       struct
        SignalPhase                 char = 'ALL_RED'
        SignalPhaseTimeRemaining   double = 0.0
        SignalTimingConfig          struct
        SignalControllerRunning     logical = false

        % Phase 5 Properties: Vehicle Counting & Directional Counts
        VehicleCounts               struct = struct('North', 0, 'South', 0, 'East', 0, 'West', 0)

        % Phase 6 Properties: Traffic Density Calculation & Monitoring
        MaxVehiclesPerApproach      double = 10 % Simulation normalization benchmark parameter
        TrafficDensityConfig        struct = struct('MaxVehiclesPerApproach', 10)
        TrafficDensity              struct = struct(...
            'North', struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
            'South', struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
            'East',  struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
            'West',  struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'))

        % Phase 7 Properties: Dynamic / AI-Based Signal Timing
        AdaptiveTimingEnabled       logical = true
        LastGreenGroup              char = 'NS'
        ConsecutiveGreenCount       double = 1
        MaxConsecutiveGreens        double = 2
        AIDecisionRecord            struct = struct()
        DensityMeters               struct = struct()

        % Phase 8 Properties: Emergency Vehicle Priority / Signal Preemption
        EmergencyPriorityEnabled    logical = true
        EmergencyActive             logical = false
        EmergencyDirection          char = ''
        EmergencyType               char = ''
        EmergencyVehicleID          double = []
        EmergencyHoldTime           double = 0.0
        EmergencyClearanceTimeout   double = 30.0
        EmergencyPriorityState      char = 'NORMAL' % 'NORMAL', 'PREEMPTING', 'ACTIVE', 'CLEARING'
        EmergencyTargetGroup        char = ''       % 'NS' or 'EW'
        EmergencyQueue              struct = struct([])

        % Queue/Demand Signal Controller Properties
        SmoothedDensity             struct = struct('North', 0, 'South', 0, 'East', 0, 'West', 0)
        QueueClearThreshold         double = 1.0
        HysteresisThreshold         double = 10.0
        TargetGreenRoad             char = ''
        ActiveGreenDuration         double = 0.0

        % Performance & Telemetry Caching Properties
        LastDisplayedGreenTime      double = -1
        LastReportedCounts          struct = struct('North', -1, 'South', -1, 'East', -1, 'West', -1, 'Processed', -1)

        % Phase 9 Properties: Pedestrian / Human Simulation
        ActivePedestrians           struct = struct([])
        NextPedestrianID            double = 1
        PedestrianConfig            struct = struct()
    end

    % Callbacks executing in response to component actions
    methods (Access = public)

        % Button push function: StartButton
        function StartButtonPushed(app, ~)
            app.startSimulation();
        end

        % Button push function: StopButton
        function StopButtonPushed(app, ~)
            app.stopSimulation();
        end

        % Button push function: ResetButton
        function ResetButtonPushed(app, ~)
            app.resetSimulation();
        end

        % Button push function: EmergencyButton
        function EmergencyButtonPushed(app, ~)
            % Randomly select starting road from North, South, East, West
            roads = {'North', 'South', 'East', 'West'};
            selectedRoad = roads{randi(numel(roads))};

            % Randomly select emergency vehicle type from Ambulance, Police, Fire Truck
            emTypes = {'Ambulance', 'Police', 'Fire Truck'};
            selectedType = emTypes{randi(numel(emTypes))};

            app.triggerEmergencyVehicle(selectedRoad, selectedType);
        end

        % -------------------------------------------------------------
        % Phase 3 Methods: Moving Vehicles & Simulation Engine
        % -------------------------------------------------------------
        function initializeSimulation(app)
            % Initialize Phase 3 vehicle lists and settings
            app.ActiveVehicles = struct(...
                'ID', {}, ...
                'Type', {}, ...
                'Direction', {}, ...
                'X', {}, ...
                'Y', {}, ...
                'Speed', {}, ...
                'Length', {}, ...
                'Width', {}, ...
                'Color', {}, ...
                'GraphicHandle', {}, ...
                'IsEmergency', {}, ...
                'EmergencyType', {});
            app.NextVehicleID = 1;
            app.TotalVehiclesSpawned = 0;
            app.TotalVehiclesProcessed = 0;
            app.SimulationRunning = false;
            app.StepCount = 0;
            app.VehicleCounts = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);
            app.SmoothedDensity = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);
            app.TargetGreenRoad = '';
            app.ActiveGreenDuration = 0.0;
            app.initializeTrafficDensity();
            app.updateVehicleCounts();

            % Reset Phase 8 emergency properties
            app.EmergencyPriorityEnabled = true;
            app.EmergencyActive = false;
            app.EmergencyDirection = '';
            app.EmergencyType = '';
            app.EmergencyVehicleID = [];
            app.EmergencyHoldTime = 0.0;
            app.EmergencyClearanceTimeout = 30.0;
            app.EmergencyPriorityState = 'NORMAL';
            app.EmergencyTargetGroup = '';
            app.EmergencyQueue = struct([]);

            % Reset telemetry caching properties
            app.LastDisplayedGreenTime = -1;
            app.LastReportedCounts = struct('North', -1, 'South', -1, 'East', -1, 'West', -1, 'Processed', -1);

            % Configure spawn and headway parameters
            s = struct();
            s.Directions = {'North', 'South', 'East', 'West'};
            s.Types = {'Car', 'Motorcycle', 'Bus/Truck'};
            s.TypeWeights = [0.60, 0.25, 0.15]; % 60% Car, 25% Bike, 15% Bus
            s.SpawnIntervalTicks = 30; % Base spawn check interval (~1.5s)
            s.SpawnProbabilities = struct('North', 0.85, 'South', 0.85, 'East', 0.85, 'West', 0.85);
            s.MinBumperBuffer = 4.0;   % Minimum distance between vehicle boundaries (m)
            s.SlowdownBuffer = 12.0;   % Deceleration threshold (m)
            s.SpawnClearance = 12.0;   % Minimum boundary clearance required at road entry (m)
            s.TickPeriod = 0.05;       % 20 FPS update rate
            
            % Vehicle type specifications (scaled 1.08x for dynamic traffic motion)
            s.VehicleSpecs = struct();
            s.VehicleSpecs.Car = struct('Length', 8.0, 'Width', 5.0, 'Speed', 1.47, 'Color', [0.15 0.75 1.00]); % Cyan (1.36 * 1.08)
            s.VehicleSpecs.Motorcycle = struct('Length', 4.5, 'Width', 3.0, 'Speed', 2.02, 'Color', [1.00 0.82 0.20]); % Amber (1.87 * 1.08)
            s.VehicleSpecs.Bus_Truck = struct('Length', 14.0, 'Width', 6.0, 'Speed', 1.01, 'Color', [0.92 0.35 0.40]); % Coral (0.935 * 1.08)
            s.VehicleSpecs.Ambulance = struct('Length', 9.5, 'Width', 5.2, 'Speed', 1.84, 'Color', [0.96 0.96 0.98]); % Reflective White (1.70 * 1.08)
            s.VehicleSpecs.Fire_Truck = struct('Length', 13.0, 'Width', 5.8, 'Speed', 1.65, 'Color', [0.90 0.15 0.15]); % Emergency Crimson (1.53 * 1.08)
            s.VehicleSpecs.Police = struct('Length', 8.2, 'Width', 5.0, 'Speed', 2.02, 'Color', [0.12 0.28 0.85]); % Police Blue (1.87 * 1.08)
            app.SpawnSettings = s;

            % Stop and delete any pre-existing timer
            if ~isempty(app.SimulationTimer) && isvalid(app.SimulationTimer)
                stop(app.SimulationTimer);
                delete(app.SimulationTimer);
            end

            % Create App Designer animation timer
            app.SimulationTimer = timer(...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', app.SpawnSettings.TickPeriod, ...
                'BusyMode', 'drop', ...
                'TimerFcn', @(~,~) app.timerTickCallback());

            % Phase 9: Initialize Pedestrian Simulation
            app.initializePedestrians();
        end

        function startSimulation(app)
            % Starts simulation, animates vehicles, changes status to RUNNING
            app.SystemStatusValue.Text = 'RUNNING';
            app.SystemStatusValue.FontColor = [0.13 0.65 0.38]; % Green
            app.SimulationRunning = true;
            app.startSignalController();

            if isempty(app.SimulationTimer) || ~isvalid(app.SimulationTimer)
                app.initializeSimulation();
                app.SimulationRunning = true;
            end

            if strcmp(app.SimulationTimer.Running, 'off')
                start(app.SimulationTimer);
            end
        end

        function stopSimulation(app)
            % Pauses animation timer, changes status to STOPPED, preserves vehicles and signal state
            app.SystemStatusValue.Text = 'STOPPED';
            app.SystemStatusValue.FontColor = [0.85 0.25 0.25]; % Red
            app.SimulationRunning = false;
            app.SignalControllerRunning = false;

            if ~isempty(app.SimulationTimer) && isvalid(app.SimulationTimer)
                if strcmp(app.SimulationTimer.Running, 'on')
                    stop(app.SimulationTimer);
                end
            end
        end

        function resetSimulation(app)
            % Stops timer, clears all vehicles and graphics, resets counters, restores READY state
            app.stopSimulation();

            % Remove all active vehicle graphics from canvas
            for i = 1:numel(app.ActiveVehicles)
                if isvalid(app.ActiveVehicles(i).GraphicHandle)
                    delete(app.ActiveVehicles(i).GraphicHandle);
                end
            end

            % Remove all active pedestrian graphics from canvas (Phase 9)
            for pIdx = 1:numel(app.ActivePedestrians)
                if isfield(app.ActivePedestrians(pIdx), 'GraphicHandle') && ...
                        ~isempty(app.ActivePedestrians(pIdx).GraphicHandle) && ...
                        isvalid(app.ActivePedestrians(pIdx).GraphicHandle)
                    delete(app.ActivePedestrians(pIdx).GraphicHandle);
                end
                if isfield(app.ActivePedestrians(pIdx), 'HeadHandle') && ...
                        ~isempty(app.ActivePedestrians(pIdx).HeadHandle) && ...
                        isvalid(app.ActivePedestrians(pIdx).HeadHandle)
                    delete(app.ActivePedestrians(pIdx).HeadHandle);
                end
            end
            app.ActivePedestrians = struct([]);
            app.NextPedestrianID = 1;

            % Re-initialize vehicle list and counters
            app.ActiveVehicles = struct(...
                'ID', {}, ...
                'Type', {}, ...
                'Direction', {}, ...
                'X', {}, ...
                'Y', {}, ...
                'Speed', {}, ...
                'Length', {}, ...
                'Width', {}, ...
                'Color', {}, ...
                'GraphicHandle', {}, ...
                'IsEmergency', {}, ...
                'EmergencyType', {});
            app.NextVehicleID = 1;
            app.TotalVehiclesSpawned = 0;
            app.TotalVehiclesProcessed = 0;
            app.StepCount = 0;
            app.VehicleCounts = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);

            % Redraw pristine road intersection and signal canvas
            app.drawIntersection();

            % Restore Phase 9 Pedestrian initial state
            app.initializePedestrians();

            % Restore Phase 4 initial signal configuration (NS GREEN, EW RED, 10s)
            app.initializeTrafficSignals();

            % Restore Phase 6 Traffic Density state
            app.initializeTrafficDensity();

            % Restore Phase 7 Adaptive Controller state
            app.AdaptiveTimingEnabled = true;
            app.LastGreenGroup = 'NS';
            app.ConsecutiveGreenCount = 1;
            app.AIDecisionRecord = struct();

            % Restore Phase 8 Emergency Priority state
            app.EmergencyPriorityEnabled = true;
            app.EmergencyActive = false;
            app.EmergencyDirection = '';
            app.EmergencyType = '';
            app.EmergencyVehicleID = [];
            app.EmergencyHoldTime = 0.0;
            app.EmergencyClearanceTimeout = 30.0;
            app.EmergencyPriorityState = 'NORMAL';
            app.EmergencyTargetGroup = '';
            app.EmergencyQueue = struct([]);

            % Reset telemetry caching properties
            app.LastDisplayedGreenTime = -1;
            app.LastReportedCounts = struct('North', -1, 'South', -1, 'East', -1, 'West', -1, 'Processed', -1);

            % Restore Phase 1 & 7 UI state
            app.SystemStatusValue.Text = 'READY';
            app.SystemStatusValue.FontColor = [0.15 0.45 0.85]; % Blue
            app.ControllerModeValue.Text = 'AI Adaptive';
            app.ControllerModeValue.FontColor = [0.15 0.80 1.00];
            app.NorthVehiclesValue.Text = '0';
            app.SouthVehiclesValue.Text = '0';
            app.EastVehiclesValue.Text = '0';
            app.WestVehiclesValue.Text = '0';
            app.CurrentGreenRoadValue.Text = 'ALL RED';
            app.CurrentGreenTimeValue.Text = '0s';
            app.TrafficDensityValue.Text = '0%';
            app.TrafficDensityValue.FontColor = [1 1 1];
            app.AIDecisionValue.Text = 'Standby';
            app.AIDecisionValue.FontColor = [0.4 0.85 0.5];
            app.AvgWaitValue.Text = '0.0 s';
            app.VehiclesProcessedValue.Text = '0';
            app.CongestionValue.Text = 'Low (0%)';
            app.CongestionValue.FontColor = [0.4 0.85 0.5];
            app.FuelSavedValue.Text = '0.0 L';
        end

        function timerTickCallback(app)
            % Safe timer callback executing simulation steps
            if ~isvalid(app) || isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                if ~isempty(app.SimulationTimer) && isvalid(app.SimulationTimer)
                    stop(app.SimulationTimer);
                    delete(app.SimulationTimer);
                end
                return;
            end

            if ~app.SimulationRunning
                return;
            end

            try
                app.StepCount = app.StepCount + 1;

                % Phase 4: Signal progression
                if app.SignalControllerRunning
                    app.updateTrafficSignals(app.SpawnSettings.TickPeriod);
                end

                % Spawning cycle
                if mod(app.StepCount, app.SpawnSettings.SpawnIntervalTicks) == 0 || app.StepCount == 1
                    app.spawnVehicles();
                end

                % Movement, headway control, signal stop obedience, and boundary removal
                app.updateVehicles();

                % Phase 9: Pedestrian simulation update (movement, spacing, turnaround)
                app.updatePedestrians();
            catch ME
                fprintf(2, 'Warning in VegMitra simulation timer: %s\n', ME.message);
            end
        end

        function spawnVehicles(app)
            % Spawns vehicles from North, South, East, West with randomized control
            dirs = app.SpawnSettings.Directions;
            for i = 1:numel(dirs)
                d = dirs{i};
                p = app.SpawnSettings.SpawnProbabilities.(d);
                if rand() <= p
                    app.spawnSingleVehicle(d);
                end
            end
        end

        function veh = spawnSingleVehicle(app, direction, optType)
            % Spawns a single vehicle in the specified direction if entry clearance permits
            veh = [];
            if ~isfield(app.IntersectionConfig, 'SpawnPositions') || ~isfield(app.IntersectionConfig.SpawnPositions, direction)
                return;
            end

            % Select vehicle type
            if nargin >= 3 && ~isempty(optType)
                vType = optType;
            else
                r = rand();
                if r <= app.SpawnSettings.TypeWeights(1)
                    vType = 'Car';
                elseif r <= (app.SpawnSettings.TypeWeights(1) + app.SpawnSettings.TypeWeights(2))
                    vType = 'Motorcycle';
                else
                    vType = 'Bus/Truck';
                end
            end

            % Map type to spec key
            if strcmp(vType, 'Bus/Truck') || strcmp(vType, 'BUS/TRUCK')
                vType = 'Bus/Truck';
                specKey = 'Bus_Truck';
            elseif strcmp(vType, 'Fire Truck') || strcmp(vType, 'Fire Brigade') || strcmp(vType, 'FIRE BRIGADE') || strcmp(vType, 'Fire_Truck')
                vType = 'Fire Truck';
                specKey = 'Fire_Truck';
            elseif strcmp(vType, 'Police') || strcmp(vType, 'Police Car') || strcmp(vType, 'POLICE CAR')
                vType = 'Police';
                specKey = 'Police';
            else
                specKey = vType;
            end
            spec = app.SpawnSettings.VehicleSpecs.(specKey);
            spawnCenter = app.IntersectionConfig.SpawnPositions.(direction);
            L_new = spec.Length;

            % Boundary-to-boundary entry clearance check:
            % Find closest existing vehicle in this direction near the entry approach
            clearanceOK = true;
            for i = 1:numel(app.ActiveVehicles)
                existing = app.ActiveVehicles(i);
                if strcmp(existing.Direction, direction)
                    L_exist = existing.Length;
                    L_half_sum = (L_new + L_exist) / 2.0;

                    switch direction
                        case 'North'
                            % Spawns at Y=95 moving downwards (Y decreasing).
                            if existing.Y > 20
                                bumperGap = (spawnCenter.Y - existing.Y) - L_half_sum;
                                if bumperGap < app.SpawnSettings.SpawnClearance
                                    clearanceOK = false;
                                    break;
                                end
                            end
                        case 'South'
                            % Spawns at Y=-95 moving upwards (Y increasing).
                            if existing.Y < -20
                                bumperGap = (existing.Y - spawnCenter.Y) - L_half_sum;
                                if bumperGap < app.SpawnSettings.SpawnClearance
                                    clearanceOK = false;
                                    break;
                                end
                            end
                        case 'East'
                            % Spawns at X=95 moving leftwards (X decreasing).
                            if existing.X > 20
                                bumperGap = (spawnCenter.X - existing.X) - L_half_sum;
                                if bumperGap < app.SpawnSettings.SpawnClearance
                                    clearanceOK = false;
                                    break;
                                end
                            end
                        case 'West'
                            % Spawns at X=-95 moving rightwards (X increasing).
                            if existing.X < -20
                                bumperGap = (existing.X - spawnCenter.X) - L_half_sum;
                                if bumperGap < app.SpawnSettings.SpawnClearance
                                    clearanceOK = false;
                                    break;
                                end
                            end
                    end
                end
            end

            if ~clearanceOK
                return;
            end

            % Create vehicle record
            newVeh = struct();
            newVeh.ID = app.NextVehicleID;
            app.NextVehicleID = app.NextVehicleID + 1;
            newVeh.Type = vType;
            newVeh.Direction = direction;
            newVeh.X = spawnCenter.X;
            newVeh.Y = spawnCenter.Y;
            newVeh.Speed = spec.Speed;
            newVeh.Length = spec.Length;
            newVeh.Width = spec.Width;
            newVeh.Color = spec.Color;
            isEmerg = ismember(vType, {'Ambulance', 'Fire Truck', 'Police'});
            newVeh.IsEmergency = isEmerg;
            if isEmerg
                newVeh.EmergencyType = vType;
            else
                newVeh.EmergencyType = '';
            end

            % Assign vehicle route: STRAIGHT (50%), LEFT (25%), RIGHT (25%)
            rRoute = rand();
            if rRoute <= 0.50
                newVeh.Route = 'STRAIGHT';
            elseif rRoute <= 0.75
                newVeh.Route = 'LEFT';
            else
                newVeh.Route = 'RIGHT';
            end
            newVeh.WaitTime = 0.0;

            % Apply diverse car colors during runtime random simulation
            if (nargin < 3 || isempty(optType)) && strcmp(vType, 'Car')
                carPalette = [
                    0.12, 0.65, 0.98;  % Electric Cyan
                    0.92, 0.25, 0.25;  % Crimson Red
                    0.98, 0.80, 0.15;  % Taxi Yellow
                    0.18, 0.82, 0.48;  % Emerald Green
                    0.92, 0.94, 0.98;  % Pure White
                    0.25, 0.52, 0.92   % Royal Blue
                ];
                cIdx = randi(size(carPalette, 1));
                newVeh.Color = carPalette(cIdx, :);
            end

            % Render graphics on SimulationCanvas
            newVeh.GraphicHandle = app.createVehicleGraphics(newVeh);

            % Add to active vehicles list
            if isempty(app.ActiveVehicles)
                app.ActiveVehicles = newVeh;
            else
                app.ActiveVehicles(end + 1) = newVeh;
            end
            app.TotalVehiclesSpawned = app.TotalVehiclesSpawned + 1;
            app.updateVehicleCounts();
            veh = newVeh;
        end

        function h = createVehicleGraphics(app, veh)
            % Creates a rounded rectangle representing the vehicle with crisp contrast
            if strcmp(veh.Direction, 'North') || strcmp(veh.Direction, 'South')
                % Vertical road: width along X, length along Y
                pos = [veh.X - veh.Width/2, veh.Y - veh.Length/2, veh.Width, veh.Length];
            else
                % Horizontal road: length along X, width along Y
                pos = [veh.X - veh.Length/2, veh.Y - veh.Width/2, veh.Length, veh.Width];
            end

            switch veh.Type
                case 'Car'
                    curv = [0.42 0.42];
                case 'Motorcycle'
                    curv = [0.65 0.65];
                case 'Ambulance'
                    curv = [0.28 0.28];
                case 'Fire Truck'
                    curv = [0.18 0.18];
                case 'Police'
                    curv = [0.38 0.38];
                otherwise % Bus/Truck
                    curv = [0.18 0.18];
            end

            h = rectangle(app.SimulationCanvas, ...
                'Position', pos, ...
                'Curvature', curv, ...
                'FaceColor', veh.Color, ...
                'EdgeColor', [0.95 0.98 1.00], ...
                'LineWidth', 1.3);

            % Layer decorative vehicle details (windshield & headlights & emergency lightbars) in UserData
            sub = app.createVehicleSubGraphics(veh);
            h.UserData = sub;
            h.DeleteFcn = @(src, ~) app.cleanupVehicleSubGraphics(src);
        end

        function sub = createVehicleSubGraphics(app, veh)
            % Creates decorative top-down vehicle details (windshield & headlights & emergency lightbars)
            ax = app.SimulationCanvas;
            sub = struct('Windshield', [], 'Headlight1', [], 'Headlight2', [], 'Lightbar', []);
            [posW, posH1, posH2, isBike] = app.calculateVehicleDetailPositions(veh);

            if isBike
                % Motorcycle helmet / dark visor
                hW = rectangle(ax, ...
                    'Position', posW, ...
                    'Curvature', [1 1], ...
                    'FaceColor', [0.10 0.14 0.20], ...
                    'EdgeColor', [0.85 0.90 1.00], ...
                    'LineWidth', 0.8);
                hH1 = rectangle(ax, ...
                    'Position', posH1, ...
                    'Curvature', [1 1], ...
                    'FaceColor', [1.00 0.98 0.70], ...
                    'EdgeColor', 'none');
                sub.Windshield = hW;
                sub.Headlight1 = hH1;
            else
                % Car / Bus / Truck / Emergency windshield & dual headlights
                hW = rectangle(ax, ...
                    'Position', posW, ...
                    'Curvature', [0.30 0.30], ...
                    'FaceColor', [0.08 0.12 0.18], ...
                    'EdgeColor', [0.28 0.38 0.50], ...
                    'LineWidth', 0.8);
                hH1 = rectangle(ax, ...
                    'Position', posH1, ...
                    'Curvature', [1 1], ...
                    'FaceColor', [1.00 0.98 0.70], ...
                    'EdgeColor', 'none');
                hH2 = rectangle(ax, ...
                    'Position', posH2, ...
                    'Curvature', [1 1], ...
                    'FaceColor', [1.00 0.98 0.70], ...
                    'EdgeColor', 'none');
                sub.Windshield = hW;
                sub.Headlight1 = hH1;
                sub.Headlight2 = hH2;
            end

            % Decorative emergency roof lightbar for emergency vehicles
            if isfield(veh, 'IsEmergency') && veh.IsEmergency
                posBar = app.calculateLightbarPosition(veh);
                switch veh.Type
                    case 'Ambulance'
                        barColor = [0.95 0.20 0.20]; % Emergency Red
                    case 'Fire Truck'
                        barColor = [1.00 0.60 0.10]; % Emergency Amber/Red
                    otherwise % Police
                        barColor = [0.10 0.50 1.00]; % Police Blue
                end
                hBar = rectangle(ax, ...
                    'Position', posBar, ...
                    'Curvature', [0.4 0.4], ...
                    'FaceColor', barColor, ...
                    'EdgeColor', [1 1 1], ...
                    'LineWidth', 0.9);
                sub.Lightbar = hBar;
            end
        end

        function updateVehicleSubGraphics(app, veh)
            % Synchronizes decorative top-down vehicle sub-graphics with current position
            if isempty(veh.GraphicHandle) || ~isvalid(veh.GraphicHandle)
                return;
            end
            sub = veh.GraphicHandle.UserData;
            if isempty(sub) || ~isstruct(sub)
                return;
            end

            [posW, posH1, posH2, isBike] = app.calculateVehicleDetailPositions(veh);

            if isfield(sub, 'Windshield') && ~isempty(sub.Windshield) && isvalid(sub.Windshield)
                set(sub.Windshield, 'Position', posW);
            end
            if isfield(sub, 'Headlight1') && ~isempty(sub.Headlight1) && isvalid(sub.Headlight1)
                set(sub.Headlight1, 'Position', posH1);
            end
            if ~isBike && isfield(sub, 'Headlight2') && ~isempty(sub.Headlight2) && isvalid(sub.Headlight2)
                set(sub.Headlight2, 'Position', posH2);
            end
            if isfield(sub, 'Lightbar') && ~isempty(sub.Lightbar) && isvalid(sub.Lightbar)
                posBar = app.calculateLightbarPosition(veh);
                set(sub.Lightbar, 'Position', posBar);
            end
        end

        function posBar = calculateLightbarPosition(~, veh)
            % Computes bounding box for top-down emergency vehicle lightbar
            curDir = veh.Direction;
            if strcmp(curDir, 'North') || strcmp(curDir, 'South')
                bW = veh.Width * 0.55;
                bL = 1.4;
                posBar = [veh.X - bW/2, veh.Y - bL/2, bW, bL];
            else
                bL = 1.4;
                bW = veh.Width * 0.55;
                posBar = [veh.X - bL/2, veh.Y - bW/2, bL, bW];
            end
        end

        function [posW, posH1, posH2, isBike] = calculateVehicleDetailPositions(~, veh)
            % Computes bounding boxes for windshield and headlights based on vehicle coordinates
            isBike = strcmp(veh.Type, 'Motorcycle');
            curDir = veh.Direction;

            if isBike
                posW = [veh.X - 1.0, veh.Y - 1.0, 2.0, 2.0];
                switch curDir
                    case 'North'
                        posH1 = [veh.X - 0.6, veh.Y - veh.Length/2 + 0.2, 1.2, 0.8];
                    case 'South'
                        posH1 = [veh.X - 0.6, veh.Y + veh.Length/2 - 1.0, 1.2, 0.8];
                    case 'East'
                        posH1 = [veh.X - veh.Length/2 + 0.2, veh.Y - 0.6, 0.8, 1.2];
                    case 'West'
                        posH1 = [veh.X + veh.Length/2 - 1.0, veh.Y - 0.6, 0.8, 1.2];
                end
                posH2 = [];
            else
                switch curDir
                    case 'North'
                        wW = veh.Width * 0.65;
                        wL = veh.Length * 0.26;
                        posW = [veh.X - wW/2, veh.Y - veh.Length * 0.12 - wL/2, wW, wL];
                        posH1 = [veh.X - veh.Width * 0.32 - 0.6, veh.Y - veh.Length/2 + 0.2, 1.2, 0.8];
                        posH2 = [veh.X + veh.Width * 0.32 - 0.6, veh.Y - veh.Length/2 + 0.2, 1.2, 0.8];
                    case 'South'
                        wW = veh.Width * 0.65;
                        wL = veh.Length * 0.26;
                        posW = [veh.X - wW/2, veh.Y + veh.Length * 0.12 - wL/2, wW, wL];
                        posH1 = [veh.X - veh.Width * 0.32 - 0.6, veh.Y + veh.Length/2 - 1.0, 1.2, 0.8];
                        posH2 = [veh.X + veh.Width * 0.32 - 0.6, veh.Y + veh.Length/2 - 1.0, 1.2, 0.8];
                    case 'East'
                        wW = veh.Length * 0.26;
                        wL = veh.Width * 0.65;
                        posW = [veh.X - veh.Length * 0.12 - wW/2, veh.Y - wL/2, wW, wL];
                        posH1 = [veh.X - veh.Length/2 + 0.2, veh.Y - veh.Width * 0.32 - 0.6, 0.8, 1.2];
                        posH2 = [veh.X - veh.Length/2 + 0.2, veh.Y + veh.Width * 0.32 - 0.6, 0.8, 1.2];
                    case 'West'
                        wW = veh.Length * 0.26;
                        wL = veh.Width * 0.65;
                        posW = [veh.X + veh.Length * 0.12 - wW/2, veh.Y - wL/2, wW, wL];
                        posH1 = [veh.X + veh.Length/2 - 1.0, veh.Y - veh.Width * 0.32 - 0.6, 0.8, 1.2];
                        posH2 = [veh.X + veh.Length/2 - 1.0, veh.Y + veh.Width * 0.32 - 0.6, 0.8, 1.2];
                end
            end
        end

        function cleanupVehicleSubGraphics(~, src)
            % Safely deletes vehicle sub-graphics when the main vehicle rectangle is deleted
            if isvalid(src) && isprop(src, 'UserData') && ~isempty(src.UserData) && isstruct(src.UserData)
                sub = src.UserData;
                if isfield(sub, 'Windshield') && ~isempty(sub.Windshield) && isvalid(sub.Windshield)
                    delete(sub.Windshield);
                end
                if isfield(sub, 'Headlight1') && ~isempty(sub.Headlight1) && isvalid(sub.Headlight1)
                    delete(sub.Headlight1);
                end
                if isfield(sub, 'Headlight2') && ~isempty(sub.Headlight2) && isvalid(sub.Headlight2)
                    delete(sub.Headlight2);
                end
                if isfield(sub, 'Lightbar') && ~isempty(sub.Lightbar) && isvalid(sub.Lightbar)
                    delete(sub.Lightbar);
                end
            end
        end

        function bounds = getVehicleBoundingBox(~, veh, posX, posY)
            % Computes axis-aligned physical bounding box [xMin, xMax, yMin, yMax]
            % strictly accounting for vehicle orientation:
            % - North/South: longitudinal dimension = Length along Y, width along X
            % - East/West:   longitudinal dimension = Length along X, width along Y
            if nargin < 3 || isempty(posX)
                posX = veh.X;
            end
            if nargin < 4 || isempty(posY)
                posY = veh.Y;
            end

            if strcmp(veh.Direction, 'North') || strcmp(veh.Direction, 'South')
                halfW = veh.Width / 2.0;
                halfL = veh.Length / 2.0;
                bounds = [posX - halfW, posX + halfW, posY - halfL, posY + halfL];
            else
                halfL = veh.Length / 2.0;
                halfW = veh.Width / 2.0;
                bounds = [posX - halfL, posX + halfL, posY - halfW, posY + halfW];
            end
        end

        function tf = checkAABBOverlap(~, b1, b2, buffer)
            % Returns true if bounding box b1 overlaps b2 (with optional safety buffer)
            if nargin < 4 || isempty(buffer)
                buffer = 0.0;
            end
            overlapX = ((b1(2) + buffer) > b2(1)) && ((b1(1) - buffer) < b2(2));
            overlapY = ((b1(4) + buffer) > b2(3)) && ((b1(3) - buffer) < b2(4));
            tf = overlapX && overlapY;
        end

        function updateVehicles(app)
            % Moves active vehicles according to direction, maintains bumper-to-bumper
            % spacing, prevents physical bounding box collisions, and removes out-of-bounds vehicles.
            if isempty(app.ActiveVehicles)
                return;
            end

            dirs = {'North', 'South', 'East', 'West'};
            D_min = app.SpawnSettings.MinBumperBuffer;
            D_slow = app.SpawnSettings.SlowdownBuffer;
            D_conf_gap = 1.0;

            % 1. Determine lane ordering along travel direction for each approach
            approachOrder = cell(1, numel(dirs));
            for dIdx = 1:numel(dirs)
                curDir = dirs{dIdx};
                matchIndices = find(strcmp({app.ActiveVehicles.Direction}, curDir));
                if isempty(matchIndices)
                    continue;
                end
                switch curDir
                    case 'North'
                        % Downwards: leader has smallest Y -> sort ascending
                        [~, sortOrder] = sort([app.ActiveVehicles(matchIndices).Y], 'ascend');
                    case 'South'
                        % Upwards: leader has largest Y -> sort descending
                        [~, sortOrder] = sort([app.ActiveVehicles(matchIndices).Y], 'descend');
                    case 'East'
                        % Leftwards: leader has smallest X -> sort ascending
                        [~, sortOrder] = sort([app.ActiveVehicles(matchIndices).X], 'ascend');
                    case 'West'
                        % Rightwards: leader has largest X -> sort descending
                        [~, sortOrder] = sort([app.ActiveVehicles(matchIndices).X], 'descend');
                end
                approachOrder{dIdx} = matchIndices(sortOrder);
            end

            % Combine processing sequence: prioritize vehicles inside or clearing
            % intersection conflict zone ([-22, 22] x [-22, 22]) to allow clear paths
            allOrdered = [approachOrder{:}];
            if isempty(allOrdered)
                return;
            end

            isInside = false(1, numel(allOrdered));
            for oIdx = 1:numel(allOrdered)
                v = app.ActiveVehicles(allOrdered(oIdx));
                isInside(oIdx) = (abs(v.X) <= 22 && abs(v.Y) <= 22);
            end
            [~, priorityOrder] = sort(isInside, 'descend');
            processingSequence = allOrdered(priorityOrder);

            numVeh = numel(app.ActiveVehicles);
            newX = [app.ActiveVehicles.X];
            newY = [app.ActiveVehicles.Y];
            hasMoved = false(1, numVeh);

            % 2. Evaluate each vehicle's advancement
            for seqIdx = 1:numel(processingSequence)
                idx = processingSequence(seqIdx);
                veh = app.ActiveVehicles(idx);
                curDir = veh.Direction;

                % 2a. Signal and Stop Line constraint
                sigDecision = app.getStopDecision(veh);
                sigAdv = max(0, sigDecision.AllowedAdvancement);
                adv = min(veh.Speed, sigAdv);

                % 2b. Same-lane longitudinal bumper-to-bumper headway constraint
                laneVehs = approachOrder{strcmp(dirs, curDir)};
                posInLane = find(laneVehs == idx, 1);

                if ~isempty(posInLane) && posInLane > 1
                    leadIdx = laneVehs(posInLane - 1);
                    leadVeh = app.ActiveVehicles(leadIdx);
                    leadX = newX(leadIdx);
                    leadY = newY(leadIdx);
                    L_half_sum = (veh.Length + leadVeh.Length) / 2.0;

                    % Exact longitudinal bumper-to-bumper separation with lead vehicle's updated position
                    switch curDir
                        case 'North'
                            bumperGap = (veh.Y - leadY) - L_half_sum;
                        case 'South'
                            bumperGap = (leadY - veh.Y) - L_half_sum;
                        case 'East'
                            bumperGap = (veh.X - leadX) - L_half_sum;
                        case 'West'
                            bumperGap = (leadX - veh.X) - L_half_sum;
                    end

                    % Strict non-overlap: clamp advancement so bumperGap >= D_min
                    if bumperGap <= D_min
                        headwayAdv = 0;
                    elseif bumperGap <= D_slow
                        headroom = bumperGap - D_min;
                        headwayAdv = min([adv, leadVeh.Speed, headroom]);
                        headwayAdv = max(0, headwayAdv);
                    else
                        headroom = bumperGap - D_min;
                        headwayAdv = min(adv, max(0, headroom));
                    end
                    adv = min(adv, headwayAdv);
                end

                % 2c. Multi-approach / Intersection AABB physical collision safeguard
                if adv > 0
                    switch curDir
                        case 'North', candX = veh.X; candY = veh.Y - adv;
                        case 'South', candX = veh.X; candY = veh.Y + adv;
                        case 'East',  candX = veh.X - adv; candY = veh.Y;
                        case 'West',  candX = veh.X + adv; candY = veh.Y;
                    end

                    candBox = app.getVehicleBoundingBox(veh, candX, candY);

                    % Check against all other vehicles
                    for otherIdx = 1:numVeh
                        if otherIdx == idx
                            continue;
                        end
                        otherVeh = app.ActiveVehicles(otherIdx);
                        otherBox = app.getVehicleBoundingBox(otherVeh, newX(otherIdx), newY(otherIdx));

                        if app.checkAABBOverlap(candBox, otherBox, D_conf_gap)
                            switch curDir
                                case 'North'
                                    distToObstacle = (veh.Y - veh.Length / 2.0) - otherBox(4);
                                case 'South'
                                    distToObstacle = otherBox(3) - (veh.Y + veh.Length / 2.0);
                                case 'East'
                                    distToObstacle = (veh.X - veh.Length / 2.0) - otherBox(2);
                                case 'West'
                                    distToObstacle = otherBox(1) - (veh.X + veh.Length / 2.0);
                            end
                            safeDist = max(0, distToObstacle - D_conf_gap);
                            adv = min(adv, safeDist);

                            % Re-evaluate candidate position with clamped adv
                            switch curDir
                                case 'North', candX = veh.X; candY = veh.Y - adv;
                                case 'South', candX = veh.X; candY = veh.Y + adv;
                                case 'East',  candX = veh.X - adv; candY = veh.Y;
                                case 'West',  candX = veh.X + adv; candY = veh.Y;
                            end
                            candBox = app.getVehicleBoundingBox(veh, candX, candY);
                        end
                    end
                end

                % 3. Apply safe position if moved
                if adv > 0
                    switch curDir
                        case 'North', newY(idx) = veh.Y - adv;
                        case 'South', newY(idx) = veh.Y + adv;
                        case 'East',  newX(idx) = veh.X - adv;
                        case 'West',  newX(idx) = veh.X + adv;
                    end
                    app.ActiveVehicles(idx).X = newX(idx);
                    app.ActiveVehicles(idx).Y = newY(idx);
                    hasMoved(idx) = true;
                end
            end

            % 4. In-place graphics update (only for vehicles that actually moved)
            for idx = 1:numVeh
                if hasMoved(idx)
                    veh = app.ActiveVehicles(idx);
                    if isvalid(veh.GraphicHandle)
                        curDir = veh.Direction;
                        if strcmp(curDir, 'North') || strcmp(curDir, 'South')
                            newPos = [veh.X - veh.Width/2, veh.Y - veh.Length/2, veh.Width, veh.Length];
                        else
                            newPos = [veh.X - veh.Length/2, veh.Y - veh.Width/2, veh.Length, veh.Width];
                        end
                        set(veh.GraphicHandle, 'Position', newPos);
                        app.updateVehicleSubGraphics(veh);
                    end
                end
            end

            % 5. Check and remove out-of-bounds vehicles
            toRemove = false(1, numel(app.ActiveVehicles));
            for i = 1:numel(app.ActiveVehicles)
                v = app.ActiveVehicles(i);
                isOut = false;
                switch v.Direction
                    case 'North', if v.Y < -110, isOut = true; end
                    case 'South', if v.Y > 110, isOut = true; end
                    case 'East',  if v.X < -110, isOut = true; end
                    case 'West',  if v.X > 110, isOut = true; end
                end

                if isOut
                    if isvalid(v.GraphicHandle)
                        delete(v.GraphicHandle);
                    end
                    toRemove(i) = true;
                    app.TotalVehiclesProcessed = app.TotalVehiclesProcessed + 1;
                end
            end

            if any(toRemove)
                app.ActiveVehicles(toRemove) = [];
            end

            % Synchronize dynamic vehicle counters and dashboard labels
            app.updateVehicleCounts();
        end

        function removeVehicle(app, index)
            % Explicitly removes a vehicle by index and deletes its graphics
            if index >= 1 && index <= numel(app.ActiveVehicles)
                if isvalid(app.ActiveVehicles(index).GraphicHandle)
                    delete(app.ActiveVehicles(index).GraphicHandle);
                end
                app.ActiveVehicles(index) = [];
                app.TotalVehiclesProcessed = app.TotalVehiclesProcessed + 1;
                app.updateVehicleCounts();
            end
        end

        % Phase 2 Methods: Intersection Setup and Drawing
        function initializeIntersectionConfig(app)
            % Defines centralized, reusable road, lane, stop-line, signal, and spawn coordinates
            cfg = struct();
            cfg.XLimits = [-100, 100];
            cfg.YLimits = [-100, 100];
            cfg.RoadWidth = 40; % Road spans from -20 to +20
            cfg.LaneWidth = 20; % Each direction gets 20 width
            
            % Stop Line positions
            % North incoming vehicles stop at Y = 20, X in [-20, 0]
            cfg.StopLineCoordinates.North = struct('X', [-20, 0], 'Y', [20, 20]);
            % South incoming vehicles stop at Y = -20, X in [0, 20]
            cfg.StopLineCoordinates.South = struct('X', [0, 20], 'Y', [-20, -20]);
            % East incoming vehicles stop at X = 20, Y in [0, 20]
            cfg.StopLineCoordinates.East  = struct('X', [20, 20], 'Y', [0, 20]);
            % West incoming vehicles stop at X = -20, Y in [-20, 0]
            cfg.StopLineCoordinates.West  = struct('X', [-20, -20], 'Y', [-20, 0]);
            
            % Lane Centerline Coordinates (Incoming & Outgoing)
            % North: Incoming (downwards) at X = -10, Outgoing (upwards) at X = +10
            cfg.LaneCoordinates.North = struct('IncomingX', -10, 'OutgoingX', 10, 'YRange', [20, 100]);
            % South: Incoming (upwards) at X = +10, Outgoing (downwards) at X = -10
            cfg.LaneCoordinates.South = struct('IncomingX', 10, 'OutgoingX', -10, 'YRange', [-100, -20]);
            % East: Incoming (leftwards) at Y = +10, Outgoing (rightwards) at Y = -10
            cfg.LaneCoordinates.East  = struct('IncomingY', 10, 'OutgoingY', -10, 'XRange', [20, 100]);
            % West: Incoming (rightwards) at Y = -10, Outgoing (leftwards) at Y = +10
            cfg.LaneCoordinates.West  = struct('IncomingY', -10, 'OutgoingY', 10, 'XRange', [-100, -20]);
            
            % Signal Housing Positions (4 corners of junction)
            cfg.SignalPositions.North = struct('X', -26, 'Y', 26);
            cfg.SignalPositions.South = struct('X', 26, 'Y', -26);
            cfg.SignalPositions.East  = struct('X', 26, 'Y', 26);
            cfg.SignalPositions.West  = struct('X', -26, 'Y', -26);

            % Vehicle Spawn Positions (Incoming ends of roads for Phase 3 readiness)
            cfg.SpawnPositions.North = struct('X', -10, 'Y', 95);
            cfg.SpawnPositions.South = struct('X', 10, 'Y', -95);
            cfg.SpawnPositions.East  = struct('X', 95, 'Y', 10);
            cfg.SpawnPositions.West  = struct('X', -95, 'Y', -10);

            % Phase 9 Configuration: Dedicated Pedestrian Sidewalk Corridors
            pedCfg = struct();
            pedCfg.MinSpacing = 3.5;    % Strict minimum pedestrian spacing (m)
            pedCfg.SafetyBuffer = 4.0;  % Strict minimum vehicle safety buffer (m)
            pedCfg.Speed = 0.45;        % Nominal pedestrian walking speed (m/tick)
            pedCfg.Paths = struct();
            pedCfg.Paths.North = struct('Axis', 'Y', 'FixedCoord', 31,  'Range', [32, 92]);
            pedCfg.Paths.South = struct('Axis', 'Y', 'FixedCoord', -31, 'Range', [-92, -32]);
            pedCfg.Paths.East  = struct('Axis', 'X', 'FixedCoord', 31,  'Range', [32, 92]);
            pedCfg.Paths.West  = struct('Axis', 'X', 'FixedCoord', -31, 'Range', [-92, -32]);
            cfg.PedestrianConfig = pedCfg;

            app.IntersectionConfig = cfg;
        end

        function drawIntersection(app)
            % Clears and draws the top-down 4-way smart-city road intersection inside SimulationCanvas
            ax = app.SimulationCanvas;
            cla(ax);
            hold(ax, 'on');
            
            % Configure axis limits, aspect ratio, and remove MATLAB axes toolbar
            ax.XLim = app.IntersectionConfig.XLimits;
            ax.YLim = app.IntersectionConfig.YLimits;
            daspect(ax, [1 1 1]); % Equal 1:1 aspect ratio to avoid distortion
            ax.Color = [0.06 0.07 0.10]; % Dark obsidian canvas background
            ax.XColor = [0.18 0.22 0.30];
            ax.YColor = [0.18 0.22 0.30];
            ax.XTick = [];
            ax.YTick = [];
            ax.Box = 'on';
            if isprop(ax, 'Toolbar') && ~isempty(ax.Toolbar)
                ax.Toolbar.Visible = 'off';
            end
            title(ax, 'Smart City Autonomous Intersection', 'Color', [0.85 0.92 1.00], 'FontSize', 12, 'FontWeight', 'bold');

            % 1. Sidewalk Pavements in 4 Corner Quadrants (Base under buildings)
            pavementColor = [0.19 0.21 0.26];
            fill(ax, [-100 -20 -20 -100], [20 20 100 100], pavementColor, 'EdgeColor', 'none');
            fill(ax, [20 100 100 20], [20 20 100 100], pavementColor, 'EdgeColor', 'none');
            fill(ax, [-100 -20 -20 -100], [-100 -100 -20 -20], pavementColor, 'EdgeColor', 'none');
            fill(ax, [20 100 100 20], [-100 -100 -20 -20], pavementColor, 'EdgeColor', 'none');

            % Subtle paving slab grid texture on sidewalks
            gridCol = [0.23 0.26 0.32];
            for gVal = 28:10:98
                plot(ax, [-100 -20], [gVal gVal], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [20 100], [gVal gVal], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [-100 -20], [-gVal -gVal], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [20 100], [-gVal -gVal], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [gVal gVal], [20 100], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [-gVal -gVal], [20 100], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [gVal gVal], [-100 -20], 'Color', gridCol, 'LineWidth', 0.6);
                plot(ax, [-gVal -gVal], [-100 -20], 'Color', gridCol, 'LineWidth', 0.6);
            end

            % Pedestrian tactile waiting zones / curb ramps at junction corners
            tactileCol = [0.28 0.26 0.18];
            fill(ax, [-28 -20.5 -20.5 -28], [20.5 20.5 28 28], tactileCol, 'EdgeColor', [0.38 0.35 0.22], 'LineWidth', 0.8);
            fill(ax, [20.5 28 28 20.5], [20.5 20.5 28 28], tactileCol, 'EdgeColor', [0.38 0.35 0.22], 'LineWidth', 0.8);
            fill(ax, [-28 -20.5 -20.5 -28], [-28 -28 -20.5 -20.5], tactileCol, 'EdgeColor', [0.38 0.35 0.22], 'LineWidth', 0.8);
            fill(ax, [20.5 28 28 20.5], [-28 -28 -20.5 -20.5], tactileCol, 'EdgeColor', [0.38 0.35 0.22], 'LineWidth', 0.8);

            % Dedicated Pedestrian Sidewalk Corridors (Phase 9 Visual Paving Strips)
            promenadeCol = [0.22 0.24 0.30];
            promEdgeCol  = [0.32 0.38 0.48];
            % North Corridor (X = 31, Y in [32, 92])
            fill(ax, [29 33 33 29], [32 32 92 92], promenadeCol, 'EdgeColor', promEdgeCol, 'LineWidth', 0.8);
            plot(ax, [31 31], [32 92], ':', 'Color', [0.45 0.55 0.70], 'LineWidth', 1.0);
            % South Corridor (X = -31, Y in [-92, -32])
            fill(ax, [-33 -29 -29 -33], [-92 -92 -32 -32], promenadeCol, 'EdgeColor', promEdgeCol, 'LineWidth', 0.8);
            plot(ax, [-31 -31], [-92 -32], ':', 'Color', [0.45 0.55 0.70], 'LineWidth', 1.0);
            % East Corridor (Y = 31, X in [32, 92])
            fill(ax, [32 92 92 32], [29 29 33 33], promenadeCol, 'EdgeColor', promEdgeCol, 'LineWidth', 0.8);
            plot(ax, [32 92], [31 31], ':', 'Color', [0.45 0.55 0.70], 'LineWidth', 1.0);
            % West Corridor (Y = -31, X in [-92, -32])
            fill(ax, [-92 -32 -32 -92], [-33 -33 -29 -29], promenadeCol, 'EdgeColor', promEdgeCol, 'LineWidth', 0.8);
            plot(ax, [-92 -32], [-31 -31], ':', 'Color', [0.45 0.55 0.70], 'LineWidth', 1.0);

            % 2. Stylized Top-Down Smart-City Buildings with 3D Drop-Shadows & Details
            % Top-Left (NW) Commercial Complex & Atrium Galleria
            % Soft drop shadow
            fill(ax, [-93 -33 -33 -93], [33 33 93 93], [0.05 0.06 0.08], 'EdgeColor', 'none');
            % Main commercial podium
            fill(ax, [-95 -35 -35 -95], [35 35 95 95], [0.22 0.25 0.32], 'EdgeColor', [0.36 0.42 0.52], 'LineWidth', 1.4);
            plot(ax, [-91 -39 -39 -91 -91], [39 39 91 91 39], 'Color', [0.42 0.48 0.60], 'LineWidth', 1.0);
            % Glass Skylight Atrium
            fill(ax, [-82 -48 -48 -82], [54 54 84 84], [0.12 0.28 0.42], 'EdgeColor', [0.20 0.62 0.85], 'LineWidth', 1.3);
            plot(ax, [-82 -48], [64 64], 'Color', [0.25 0.68 0.88], 'LineWidth', 0.8);
            plot(ax, [-82 -48], [74 74], 'Color', [0.25 0.68 0.88], 'LineWidth', 0.8);
            plot(ax, [-71 -71], [54 84], 'Color', [0.25 0.68 0.88], 'LineWidth', 0.8);
            plot(ax, [-59 -59], [54 84], 'Color', [0.25 0.68 0.88], 'LineWidth', 0.8);
            % Rooftop HVAC chiller units
            fill(ax, [-88 -76 -76 -88], [42 42 49 49], [0.16 0.18 0.24], 'EdgeColor', [0.30 0.35 0.45]);
            fill(ax, [-54 -42 -42 -54], [42 42 49 49], [0.16 0.18 0.24], 'EdgeColor', [0.30 0.35 0.45]);
            % Discreet architectural badge
            text(ax, -65, 45, 'COMMERCE CENTER', 'Color', [0.75 0.85 0.98], 'FontSize', 7.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

            % Top-Right (NE) Innovation & Smart-City Tech Tower
            fill(ax, [35 97 97 35], [33 33 93 93], [0.05 0.06 0.08], 'EdgeColor', 'none');
            fill(ax, [35 88 95 95 35], [35 35 35 95 95], [0.20 0.23 0.30], 'EdgeColor', [0.34 0.42 0.54], 'LineWidth', 1.4);
            fill(ax, [42 88 88 42], [42 42 88 88], [0.16 0.19 0.26], 'EdgeColor', [0.28 0.38 0.50], 'LineWidth', 1.0);
            % Helipad
            hTheta = 0:0.3:2*pi;
            plot(ax, 72 + 8.5*cos(hTheta), 70 + 8.5*sin(hTheta), 'Color', [0.95 0.82 0.15], 'LineWidth', 1.4);
            text(ax, 72, 70, 'H', 'Color', [0.95 0.82 0.15], 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            % Photovoltaic solar array (3x2 grid)
            fill(ax, [46 62 62 46], [54 54 82 82], [0.08 0.18 0.30], 'EdgeColor', [0.20 0.45 0.65], 'LineWidth', 1.0);
            plot(ax, [46 62], [63 63], 'Color', [0.20 0.45 0.65], 'LineWidth', 0.8);
            plot(ax, [46 62], [73 73], 'Color', [0.20 0.45 0.65], 'LineWidth', 0.8);
            plot(ax, [54 54], [54 82], 'Color', [0.20 0.45 0.65], 'LineWidth', 0.8);
            text(ax, 68, 45, 'INNOVATION HUB', 'Color', [0.45 0.88 1.00], 'FontSize', 7.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

            % Bottom-Left (SW) Metro Civic & Residential Center
            fill(ax, [-93 -33 -33 -93], [-97 -97 -37 -37], [0.05 0.06 0.08], 'EdgeColor', 'none');
            fill(ax, [-95 -35 -35 -95], [-95 -95 -35 -35], [0.21 0.24 0.31], 'EdgeColor', [0.35 0.40 0.50], 'LineWidth', 1.4);
            % Central landscaped garden courtyard
            fill(ax, [-85 -45 -45 -85], [-68 -68 -45 -45], [0.12 0.30 0.18], 'EdgeColor', [0.18 0.48 0.28], 'LineWidth', 1.0);
            % Rooftop pool & timber sun deck
            fill(ax, [-88 -62 -62 -88], [-88 -88 -74 -74], [0.30 0.24 0.18], 'EdgeColor', [0.40 0.32 0.25]);
            fill(ax, [-85 -65 -65 -85], [-86 -86 -76 -76], [0.10 0.50 0.68], 'EdgeColor', [0.25 0.75 0.95], 'LineWidth', 1.0);
            % Penthouse utilities
            fill(ax, [-58 -44 -44 -58], [-88 -88 -76 -76], [0.16 0.18 0.24], 'EdgeColor', [0.28 0.32 0.42]);
            text(ax, -65, -91, 'METRO CIVIC COMPLEX', 'Color', [0.75 0.85 0.96], 'FontSize', 7.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

            % Bottom-Right (SE) Eco-Tech Green Campus & Sustainability Park
            fill(ax, [35 97 97 35], [-97 -97 -37 -37], [0.05 0.06 0.08], 'EdgeColor', 'none');
            fill(ax, [35 95 95 35], [-95 -95 -35 -35], [0.19 0.22 0.26], 'EdgeColor', [0.28 0.38 0.32], 'LineWidth', 1.4);
            % Living Sedum Green Roof
            fill(ax, [40 90 90 40], [-90 -90 -42 -42], [0.11 0.32 0.16], 'EdgeColor', [0.18 0.52 0.26], 'LineWidth', 1.2);
            % Glass conservatory / botanical dome
            fill(ax, [46 66 66 46], [-66 -66 -48 -48], [0.10 0.38 0.35], 'EdgeColor', [0.22 0.72 0.62], 'LineWidth', 1.2);
            plot(ax, [46 66], [-57 -57], 'Color', [0.22 0.72 0.62], 'LineWidth', 0.8);
            plot(ax, [56 56], [-66 -48], 'Color', [0.22 0.72 0.62], 'LineWidth', 0.8);
            % Solar pergola canopy
            fill(ax, [72 88 88 72], [-66 -66 -50 -50], [0.14 0.22 0.32], 'EdgeColor', [0.25 0.50 0.70]);
            text(ax, 65, -91, 'ECO-TECH CAMPUS', 'Color', [0.45 0.92 0.62], 'FontSize', 7.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

            % 3. Lush Top-Down Trees with Layered Organic Foliage
            treePositions = [
                -27, 44, 3.2;  -27, 60, 3.2;  -27, 76, 3.4;  -27, 90, 3.0;
                -44, 27, 3.2;  -60, 27, 3.4;  -76, 27, 3.2;  -90, 27, 3.0;
                 27, 44, 3.2;   27, 60, 3.2;   27, 76, 3.4;   27, 90, 3.0;
                 44, 27, 3.2;   60, 27, 3.4;   76, 27, 3.2;   90, 27, 3.0;
                -27, -44, 3.2; -27, -60, 3.2; -27, -76, 3.4; -27, -90, 3.0;
                -44, -27, 3.2; -60, -27, 3.4; -76, -27, 3.2; -90, -27, 3.0;
                 27, -44, 3.2;  27, -60, 3.2;  27, -76, 3.4;  27, -90, 3.0;
                 44, -27, 3.2;  60, -27, 3.4;  76, -27, 3.2;  90, -27, 3.0;
                -30, 31, 2.8;   30, 31, 2.8;  -30, -31, 2.8;   30, -31, 2.8
            ];
            for tIdx = 1:size(treePositions, 1)
                app.drawTree(ax, treePositions(tIdx, 1), treePositions(tIdx, 2), treePositions(tIdx, 3));
            end

            % 4. Modern Street Lamps along Sidewalks
            lampPositions = [
                -23, 52;  -23, 80;   23, 52;   23, 80;
                -23, -52; -23, -80;  23, -52;  23, -80;
                -52, 23;  -80, 23;   52, 23;   80, 23;
                -52, -23; -80, -23;  52, -23;  80, -23
            ];
            for lIdx = 1:size(lampPositions, 1)
                app.drawStreetLamp(ax, lampPositions(lIdx, 1), lampPositions(lIdx, 2));
            end

            % 5. Street Furniture: Roadside benches & Smart-City telemetry posts
            benchPositions = [-24, 68; 24, 68; -24, -68; 24, -68; -68, 24; 68, 24; -68, -24; 68, -24];
            for bIdx = 1:size(benchPositions, 1)
                bx = benchPositions(bIdx, 1);
                by = benchPositions(bIdx, 2);
                if abs(bx) < abs(by)
                    plot(ax, [bx-1.2 bx+1.2], [by by], 'Color', [0.45 0.38 0.28], 'LineWidth', 2.0);
                else
                    plot(ax, [bx bx], [by-1.2 by+1.2], 'Color', [0.45 0.38 0.28], 'LineWidth', 2.0);
                end
            end
            % Telemetry / camera sensor posts near corner ramps
            fill(ax, [-29 -27 -27 -29], [21 21 23 23], [0.16 0.22 0.32], 'EdgeColor', [0.35 0.50 0.70]);
            plot(ax, -28, 22, '.', 'Color', [0.10 0.95 0.40], 'MarkerSize', 5);
            fill(ax, [27 29 29 27], [-23 -23 -21 -21], [0.16 0.22 0.32], 'EdgeColor', [0.35 0.50 0.70]);
            plot(ax, 28, -22, '.', 'Color', [0.10 0.95 0.40], 'MarkerSize', 5);

            % 6. Concrete Beveled Curb Lines
            curbColor = [0.45 0.50 0.60];
            curbWidth = 2.2;
            plot(ax, [-100 -20 -20], [20 20 100], 'Color', curbColor, 'LineWidth', curbWidth);
            plot(ax, [100 20 20], [20 20 100], 'Color', curbColor, 'LineWidth', curbWidth);
            plot(ax, [-100 -20 -20], [-20 -20 -100], 'Color', curbColor, 'LineWidth', curbWidth);
            plot(ax, [100 20 20], [-20 -20 -100], 'Color', curbColor, 'LineWidth', curbWidth);

            % 7. Deep Slate Asphalt Road Surfaces
            roadColor = [0.12 0.13 0.17];
            fill(ax, [-100 100 100 -100], [-20 -20 20 20], roadColor, 'EdgeColor', 'none');
            fill(ax, [-20 -20 20 20], [-100 100 100 -100], roadColor, 'EdgeColor', 'none');

            % Road drainage gutters along curbs
            gutterColor = [0.09 0.10 0.13];
            plot(ax, [-100 -20], [19.2 19.2], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [20 100], [19.2 19.2], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [-100 -20], [-19.2 -19.2], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [20 100], [-19.2 -19.2], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [19.2 19.2], [20 100], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [19.2 19.2], [-100 -20], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [-19.2 -19.2], [20 100], 'Color', gutterColor, 'LineWidth', 1.0);
            plot(ax, [-19.2 -19.2], [-100 -20], 'Color', gutterColor, 'LineWidth', 1.0);

            % 8. Central Intersection Area & Yellow Box Junction
            fill(ax, [-20 20 20 -20], [-20 -20 20 20], [0.14 0.15 0.19], 'EdgeColor', 'none');
            boxColor = [0.96 0.78 0.14];
            plot(ax, [-19.5 19.5 19.5 -19.5 -19.5], [-19.5 -19.5 19.5 19.5 -19.5], 'Color', boxColor, 'LineWidth', 2.0);
            plot(ax, [-18.5 18.5 18.5 -18.5 -18.5], [-18.5 -18.5 18.5 18.5 -18.5], 'Color', boxColor, 'LineWidth', 1.0);
            plot(ax, [-18.5 18.5], [-18.5 18.5], 'Color', boxColor, 'LineWidth', 1.2);
            plot(ax, [-18.5 18.5], [18.5 -18.5], 'Color', boxColor, 'LineWidth', 1.2);
            plot(ax, [0 18.5 0 -18.5 0], [18.5 0 -18.5 0 18.5], 'Color', boxColor, 'LineWidth', 1.2);

            % 9. Pedestrian Zebra Crossings (Bright, crisp white alternating stripes)
            zebraColor = [0.96 0.97 0.99];
            for xs = -18 : 4.0 : 16
                fill(ax, [xs, xs+2.2, xs+2.2, xs], [21.5, 21.5, 27.5, 27.5], zebraColor, 'EdgeColor', 'none');
                fill(ax, [xs, xs+2.2, xs+2.2, xs], [-27.5, -27.5, -21.5, -21.5], zebraColor, 'EdgeColor', 'none');
            end
            for ys = -18 : 4.0 : 16
                fill(ax, [21.5, 27.5, 27.5, 21.5], [ys, ys, ys+2.2, ys+2.2], zebraColor, 'EdgeColor', 'none');
                fill(ax, [-27.5, -21.5, -21.5, -27.5], [ys, ys, ys+2.2, ys+2.2], zebraColor, 'EdgeColor', 'none');
            end

            % 10. Stop Lines (Solid White Thick Lines strictly at StopLineCoordinates)
            stopColor = [1.0 1.0 1.0];
            stopWidth = 4.0;
            plot(ax, app.IntersectionConfig.StopLineCoordinates.North.X, app.IntersectionConfig.StopLineCoordinates.North.Y, 'Color', stopColor, 'LineWidth', stopWidth);
            plot(ax, app.IntersectionConfig.StopLineCoordinates.South.X, app.IntersectionConfig.StopLineCoordinates.South.Y, 'Color', stopColor, 'LineWidth', stopWidth);
            plot(ax, app.IntersectionConfig.StopLineCoordinates.East.X, app.IntersectionConfig.StopLineCoordinates.East.Y, 'Color', stopColor, 'LineWidth', stopWidth);
            plot(ax, app.IntersectionConfig.StopLineCoordinates.West.X, app.IntersectionConfig.StopLineCoordinates.West.Y, 'Color', stopColor, 'LineWidth', stopWidth);

            % 11. Dashed Lane Divider Lines (Yellow Dashed Lines)
            yellowLine = [0.96 0.80 0.15];
            plot(ax, [-100 -28], [0 0], '--', 'Color', yellowLine, 'LineWidth', 2.0);
            plot(ax, [28 100], [0 0], '--', 'Color', yellowLine, 'LineWidth', 2.0);
            plot(ax, [0 0], [28 100], '--', 'Color', yellowLine, 'LineWidth', 2.0);
            plot(ax, [0 0], [-100 -28], '--', 'Color', yellowLine, 'LineWidth', 2.0);

            % 12. Directional Lane Arrows (White painted arrows on incoming lanes)
            arrowColor = [0.85 0.90 0.98];
            plot(ax, [-10 -10], [42 52], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [-12 -10 -8], [46 42 46], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [10 10], [-52 -42], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [8 10 12], [-46 -42 -46], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [42 52], [10 10], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [46 42 46], [12 10 8], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [-52 -42], [-10 -10], 'Color', arrowColor, 'LineWidth', 2.2);
            plot(ax, [-46 -42 -46], [-8 -10 -12], 'Color', arrowColor, 'LineWidth', 2.2);

            % 13. Directional Road Corridor Labels
            labelColor = [0.85 0.92 1.00];
            text(ax, 0, 93, 'NORTH CORRIDOR', 'Color', labelColor, 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            text(ax, 0, -93, 'SOUTH CORRIDOR', 'Color', labelColor, 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            text(ax, 92, 0, 'EAST CORRIDOR >>', 'Color', labelColor, 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Rotation', 270);
            text(ax, -92, 0, '<< WEST CORRIDOR', 'Color', labelColor, 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Rotation', 90);

            % 14. Phase 4 Traffic Signal Heads (North, South, East, West)
            app.drawTrafficSignals();

            hold(ax, 'off');
        end

        % -------------------------------------------------------------
        % Phase 4 Methods: Traffic Signals & Controller
        % -------------------------------------------------------------
        function initializeTrafficSignals(app)
            % Configures traffic signal parameters and sets initial state to ALL RED
            cfg = struct();
            cfg.GreenDuration = 10.0;       % 10 seconds active green base
            cfg.YellowDuration = 2.0;       % 2 seconds yellow change interval
            cfg.AllRedDuration = 1.0;       % 1 second all-red clearance
            cfg.YellowDecisionDist = 14.0;  % Threshold distance to stop on yellow
            cfg.StopBuffer = 1.0;           % Stopping buffer distance before stop line
            cfg.MinGreenHoldDuration = 2.5; % 2.5 seconds minimum green holding duration
            app.SignalTimingConfig = cfg;

            % Initial signal states: ALL RED
            app.TrafficSignalStates = struct(...
                'North', 'RED', ...
                'South', 'RED', ...
                'East',  'RED', ...
                'West',  'RED');

            app.SignalPhase = 'ALL_RED';
            app.SignalPhaseTimeRemaining = 0.0;
            app.SignalControllerRunning = false;

            % Update Dashboard labels if initialized
            if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                app.CurrentGreenRoadValue.Text = 'ALL RED';
            end
            if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                app.CurrentGreenTimeValue.Text = '0s';
            end

            % Update visual illumination if graphic elements exist
            app.updateSignalVisuals();
        end

        function drawTrafficSignals(app)
            % Draws 4 functional 3-aspect traffic signals (North, South, East, West)
            % with high-contrast safety backing plates, dark housings, and distinct RED, YELLOW, GREEN lamps.
            if isempty(app.TrafficSignalStates) || ~isfield(app.TrafficSignalStates, 'North')
                app.TrafficSignalStates = struct(...
                    'North', 'RED', ...
                    'South', 'RED', ...
                    'East',  'RED', ...
                    'West',  'RED');
            end

            ax = app.SimulationCanvas;
            app.TrafficSignalGraphics = struct();

            dirs = {'North', 'South', 'East', 'West'};
            for i = 1:numel(dirs)
                d = dirs{i};
                pos = app.IntersectionConfig.SignalPositions.(d);
                cx = pos.X;
                cy = pos.Y;

                % Mounting mast pole base
                plot(ax, [cx cx], [cy - 11, cy - 8.2], 'Color', [0.45 0.50 0.60], 'LineWidth', 2.4);

                % Safety yellow hazard border backplate
                rectangle(ax, ...
                    'Position', [cx - 3.8, cy - 8.8, 7.6, 17.6], ...
                    'Curvature', [0.25 0.25], ...
                    'FaceColor', [0.05 0.06 0.09], ...
                    'EdgeColor', [0.96 0.78 0.14], ...
                    'LineWidth', 1.2);

                % Main Housing: width 6.4, height 16.4 centered at (cx, cy)
                hBox = rectangle(ax, ...
                    'Position', [cx - 3.2, cy - 8.2, 6.4, 16.4], ...
                    'Curvature', [0.30 0.30], ...
                    'FaceColor', [0.07 0.08 0.12], ...
                    'EdgeColor', [0.50 0.58 0.70], ...
                    'LineWidth', 1.3);

                % Arched sun visors over each lamp
                plot(ax, [cx - 1.8, cx, cx + 1.8], [cy + 6.6, cy + 7.2, cy + 6.6], 'Color', [0.40 0.45 0.55], 'LineWidth', 1.5);
                plot(ax, [cx - 1.8, cx, cx + 1.8], [cy + 2.1, cy + 2.7, cy + 2.1], 'Color', [0.40 0.45 0.55], 'LineWidth', 1.5);
                plot(ax, [cx - 1.8, cx, cx + 1.8], [cy - 2.4, cy - 1.8, cy - 2.4], 'Color', [0.40 0.45 0.55], 'LineWidth', 1.5);

                % Top: RED Lamp (center at cy + 4.5, diameter 3.8)
                hRed = rectangle(ax, ...
                    'Position', [cx - 1.9, cy + 2.6, 3.8, 3.8], ...
                    'Curvature', [1 1], ...
                    'FaceColor', [0.22 0.05 0.05], ...
                    'EdgeColor', [0.16 0.04 0.04], ...
                    'LineWidth', 0.8);

                % Middle: YELLOW Lamp (center at cy, diameter 3.8)
                hYellow = rectangle(ax, ...
                    'Position', [cx - 1.9, cy - 1.9, 3.8, 3.8], ...
                    'Curvature', [1 1], ...
                    'FaceColor', [0.20 0.17 0.04], ...
                    'EdgeColor', [0.15 0.12 0.03], ...
                    'LineWidth', 0.8);

                % Bottom: GREEN Lamp (center at cy - 4.5, diameter 3.8)
                hGreen = rectangle(ax, ...
                    'Position', [cx - 1.9, cy - 6.4, 3.8, 3.8], ...
                    'Curvature', [1 1], ...
                    'FaceColor', [0.04 0.18 0.07], ...
                    'EdgeColor', [0.03 0.13 0.05], ...
                    'LineWidth', 0.8);

                % Direction indicator letter badge
                hLabel = text(ax, cx, cy + 10.4, d(1), ...
                    'Color', [0.90 0.95 1.00], ...
                    'FontSize', 9, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');

                % Store graphics handles (strictly preserving fieldnames Housing, RedLamp, YellowLamp, GreenLamp, Label)
                app.TrafficSignalGraphics.(d) = struct(...
                    'Housing', hBox, ...
                    'RedLamp', hRed, ...
                    'YellowLamp', hYellow, ...
                    'GreenLamp', hGreen, ...
                    'Label', hLabel);
            end

            % Update visual illumination state to match current TrafficSignalStates
            app.updateSignalVisuals();
        end

        function drawTree(~, ax, cx, cy, r)
            % Draws a stylized organic top-down canopy tree with multi-layered foliage and shadow
            theta = 0:0.25:2*pi;
            rOuter = r * (1 + 0.14*cos(4*theta) + 0.08*sin(3*theta));
            rMid   = r * 0.82 * (1 + 0.10*cos(4*theta + 0.5));
            rInner = r * 0.52 * (1 + 0.10*sin(4*theta + 1.0));
            
            % Soft ground shadow
            fill(ax, cx + 0.6 + (rOuter+0.3).*cos(theta), cy - 0.6 + (rOuter+0.3).*sin(theta), [0.05 0.06 0.08], 'EdgeColor', 'none');
            % Base dark foliage
            fill(ax, cx + rOuter.*cos(theta), cy + rOuter.*sin(theta), [0.07 0.24 0.13], 'EdgeColor', 'none');
            % Mid-tone organic canopy
            fill(ax, cx + rMid.*cos(theta), cy + rMid.*sin(theta), [0.12 0.45 0.22], 'EdgeColor', 'none');
            % Sunlit highlight foliage
            fill(ax, cx - r*0.18 + rInner.*cos(theta), cy + r*0.18 + rInner.*sin(theta), [0.22 0.65 0.32], 'EdgeColor', 'none');
            % Central trunk core
            plot(ax, cx, cy, '.', 'Color', [0.18 0.14 0.10], 'MarkerSize', 6);
        end

        function drawStreetLamp(~, ax, cx, cy)
            % Draws a modern top-down LED street lamp with warm circular pavement halo
            theta = 0:0.35:2*pi;
            fill(ax, cx + 3.2*cos(theta), cy + 3.2*sin(theta), [0.28 0.26 0.14], 'EdgeColor', 'none');
            fill(ax, cx + 1.8*cos(theta), cy + 1.8*sin(theta), [0.60 0.55 0.24], 'EdgeColor', 'none');
            plot(ax, [cx cx+0.8], [cy cy+0.8], 'Color', [0.50 0.55 0.65], 'LineWidth', 2.0);
            plot(ax, cx, cy, 'o', 'MarkerFaceColor', [1.00 0.98 0.85], 'MarkerEdgeColor', [0.90 0.80 0.35], 'MarkerSize', 5);
        end

        function updateSignalVisuals(app)
            % Visually illuminates active lamp and dims inactive lamps for all 4 signals
            if isempty(app.TrafficSignalGraphics) || ~isfield(app.TrafficSignalGraphics, 'North')
                return;
            end

            dirs = {'North', 'South', 'East', 'West'};
            for i = 1:numel(dirs)
                d = dirs{i};
                if ~isfield(app.TrafficSignalGraphics, d)
                    continue;
                end

                g = app.TrafficSignalGraphics.(d);
                if ~isvalid(g.RedLamp) || ~isvalid(g.YellowLamp) || ~isvalid(g.GreenLamp)
                    continue;
                end

                state = app.getSignalState(d);
                switch state
                    case 'RED'
                        set(g.RedLamp, ...
                            'FaceColor', [1.00 0.12 0.12], ...
                            'EdgeColor', [1.00 0.70 0.70], ...
                            'LineWidth', 1.4);
                        set(g.YellowLamp, ...
                            'FaceColor', [0.20 0.17 0.04], ...
                            'EdgeColor', [0.15 0.12 0.03], ...
                            'LineWidth', 0.8);
                        set(g.GreenLamp, ...
                            'FaceColor', [0.04 0.18 0.07], ...
                            'EdgeColor', [0.03 0.13 0.05], ...
                            'LineWidth', 0.8);

                    case 'YELLOW'
                        set(g.RedLamp, ...
                            'FaceColor', [0.22 0.05 0.05], ...
                            'EdgeColor', [0.16 0.04 0.04], ...
                            'LineWidth', 0.8);
                        set(g.YellowLamp, ...
                            'FaceColor', [1.00 0.84 0.10], ...
                            'EdgeColor', [1.00 0.96 0.60], ...
                            'LineWidth', 1.4);
                        set(g.GreenLamp, ...
                            'FaceColor', [0.04 0.18 0.07], ...
                            'EdgeColor', [0.03 0.13 0.05], ...
                            'LineWidth', 0.8);

                    case 'GREEN'
                        set(g.RedLamp, ...
                            'FaceColor', [0.22 0.05 0.05], ...
                            'EdgeColor', [0.16 0.04 0.04], ...
                            'LineWidth', 0.8);
                        set(g.YellowLamp, ...
                            'FaceColor', [0.20 0.17 0.04], ...
                            'EdgeColor', [0.15 0.12 0.03], ...
                            'LineWidth', 0.8);
                        set(g.GreenLamp, ...
                            'FaceColor', [0.10 0.95 0.38], ...
                            'EdgeColor', [0.65 1.00 0.75], ...
                            'LineWidth', 1.4);
                end
            end
        end

        function startSignalController(app)
            % Starts signal controller progression
            app.SignalControllerRunning = true;
        end

        function updateTrafficSignals(app, dt)
            % Queue/Traffic-Demand Signal Progression & Phase Transitions
            if nargin < 2 || isempty(dt)
                dt = app.SpawnSettings.TickPeriod;
            end

            % 1. Automatic emergency detection scan across all active vehicles
            emRoad = app.getEmergencyPriorityRoad();
            if ~isempty(emRoad) && ~app.EmergencyActive
                emVehs = app.getIncomingVehiclesForDirection(emRoad);
                for i = 1:numel(emVehs)
                    if isfield(emVehs(i), 'IsEmergency') && emVehs(i).IsEmergency
                        app.requestEmergencyPriority(emVehs(i));
                        break;
                    end
                end
            end

            % 2. Handle active emergency hold / preemption
            if app.EmergencyActive
                if strcmp(app.EmergencyPriorityState, 'ACTIVE')
                    app.EmergencyHoldTime = app.EmergencyHoldTime + dt;
                    if app.checkEmergencyCleared() || (app.EmergencyHoldTime >= app.EmergencyClearanceTimeout)
                        app.releaseEmergencyPriority();
                        return;
                    else
                        if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                            app.CurrentGreenTimeValue.Text = 'EMERGENCY';
                        end
                        return;
                    end
                elseif strcmp(app.EmergencyPriorityState, 'PREEMPTING')
                    app.EmergencyHoldTime = app.EmergencyHoldTime + dt;
                    if app.EmergencyHoldTime >= app.EmergencyClearanceTimeout
                        app.releaseEmergencyPriority();
                    end
                end
            end

            % 3. Handle Yellow / All-Red Safety Transitions
            if contains(app.SignalPhase, 'YELLOW') || contains(app.SignalPhase, 'ALL_RED')
                app.SignalPhaseTimeRemaining = app.SignalPhaseTimeRemaining - dt;

                if app.SignalPhaseTimeRemaining <= 0
                    switch app.SignalPhase
                        case {'NORTH_YELLOW', 'SOUTH_YELLOW', 'EAST_YELLOW', 'WEST_YELLOW', 'NS_YELLOW', 'EW_YELLOW'}
                            app.setSignalPhase('ALL_RED');
                        case {'ALL_RED', 'ALL_RED_1', 'ALL_RED_2'}
                            % Ensure intersection conflict zone is completely clear of committed non-emergency vehicles
                            if ~app.checkIntersectionConflictZoneClear()
                                app.SignalPhaseTimeRemaining = 0.0;
                                return;
                            end

                            % Safety transition complete -> Switch to Target GREEN Road!
                            if ~isempty(app.EmergencyQueue)
                                nextReq = app.EmergencyQueue(1);
                                app.EmergencyQueue(1) = [];
                                vIdx = find([app.ActiveVehicles.ID] == nextReq.ID, 1);
                                if ~isempty(vIdx)
                                    nextVeh = app.ActiveVehicles(vIdx);
                                    app.requestEmergencyPriority(nextVeh);
                                    targetPhase = sprintf('%s_GREEN', upper(nextVeh.Direction));
                                    app.setSignalPhase(targetPhase, app.EmergencyClearanceTimeout);
                                    app.EmergencyPriorityState = 'ACTIVE';
                                    app.updateEmergencyUI();
                                    return;
                                end
                            end

                            if app.EmergencyActive && strcmp(app.EmergencyPriorityState, 'PREEMPTING')
                                if ~isempty(app.EmergencyDirection)
                                    targetPhase = sprintf('%s_GREEN', upper(app.EmergencyDirection));
                                else
                                    targetPhase = 'NORTH_GREEN';
                                end
                                app.setSignalPhase(targetPhase, app.EmergencyClearanceTimeout);
                                app.EmergencyPriorityState = 'ACTIVE';
                                app.updateEmergencyUI();
                            else
                                app.EmergencyPriorityState = 'NORMAL';
                                if ~isempty(app.ControllerModeValue) && isvalid(app.ControllerModeValue)
                                    app.ControllerModeValue.Text = 'AI Adaptive';
                                    app.ControllerModeValue.FontColor = [0.15 0.80 1.00];
                                end
                                if ~isempty(app.SystemStatusValue) && isvalid(app.SystemStatusValue)
                                    if app.SimulationRunning
                                        app.SystemStatusValue.Text = 'RUNNING';
                                        app.SystemStatusValue.FontColor = [0.13 0.65 0.38];
                                    end
                                end

                                if ~isempty(app.TargetGreenRoad)
                                    targetPhase = sprintf('%s_GREEN', upper(app.TargetGreenRoad));
                                else
                                    decision = app.evaluateAIDecision();
                                    targetPhase = decision.NextPhase;
                                end
                                app.setSignalPhase(targetPhase);
                                app.TargetGreenRoad = '';
                                app.ActiveGreenDuration = 0.0;
                            end
                    end
                end
                return;
            end

            % 4. Active GREEN Phase Logic (Demand-Controlled)
            if contains(app.SignalPhase, 'GREEN')
                app.ActiveGreenDuration = app.ActiveGreenDuration + dt;

                decision = app.evaluateAIDecision();
                app.AIDecisionRecord = decision;

                if ~isempty(app.AIDecisionValue) && isvalid(app.AIDecisionValue)
                    app.AIDecisionValue.Text = decision.DecisionText;
                    app.AIDecisionValue.FontColor = [0.2 0.75 1.0];
                end

                if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                    activeSec = round(app.ActiveGreenDuration);
                    if activeSec ~= app.LastDisplayedGreenTime
                        app.LastDisplayedGreenTime = activeSec;
                        app.CurrentGreenTimeValue.Text = sprintf('%ds', activeSec);
                    end
                end

                currentRoad = app.getCurrentGreenRoadName();
                targetRoad = decision.SelectedRoad;

                if ~isempty(currentRoad) && ~strcmp(targetRoad, currentRoad)
                    % Enforce minimum green holding duration before starting yellow transition
                    minHold = 2.5;
                    if isfield(app.SignalTimingConfig, 'MinGreenHoldDuration')
                        minHold = app.SignalTimingConfig.MinGreenHoldDuration;
                    end
                    if app.ActiveGreenDuration >= minHold
                        app.TargetGreenRoad = targetRoad;
                        yellowPhase = sprintf('%s_YELLOW', upper(currentRoad));
                        app.setSignalPhase(yellowPhase);
                        app.ActiveGreenDuration = 0.0;
                    end
                end
            end
        end

        function setSignalState(app, direction, state)
            % Sets individual signal state with validation and safety invariant check
            validStates = {'RED', 'YELLOW', 'GREEN'};
            validDirs = {'North', 'South', 'East', 'West'};
            if ~ismember(direction, validDirs) || ~ismember(state, validStates)
                error('Invalid direction or signal state specified');
            end

            % Safety invariant: never allow conflicting directions to be GREEN simultaneously
            if strcmp(state, 'GREEN')
                if strcmp(direction, 'North') || strcmp(direction, 'South')
                    if strcmp(app.TrafficSignalStates.East, 'GREEN') || strcmp(app.TrafficSignalStates.West, 'GREEN')
                        error('Safety Violation: Cannot set North/South GREEN while East/West is GREEN');
                    end
                elseif strcmp(direction, 'East') || strcmp(direction, 'West')
                    if strcmp(app.TrafficSignalStates.North, 'GREEN') || strcmp(app.TrafficSignalStates.South, 'GREEN')
                        error('Safety Violation: Cannot set East/West GREEN while North/South is GREEN');
                    end
                end
            end

            app.TrafficSignalStates.(direction) = state;
            app.updateSignalVisuals();
        end

        function setSignalPhase(app, phaseName, optDuration)
            % Sets the active traffic signal phase and updates all signal states,
            % phase countdown timers, and Traffic Information Panel text.
            % optDuration is optional: if specified, overrides default green duration.
            if nargin >= 3 && ~isempty(optDuration)
                gDur = optDuration;
            else
                gDur = app.SignalTimingConfig.GreenDuration;
            end

            switch phaseName
                case {'NORTH_GREEN', 'North'}
                    app.TrafficSignalStates.North = 'GREEN';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'NORTH_GREEN';
                    app.SignalPhaseTimeRemaining = gDur;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'North GREEN';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.LastDisplayedGreenTime = round(app.SignalPhaseTimeRemaining);
                        app.CurrentGreenTimeValue.Text = sprintf('%ds', app.LastDisplayedGreenTime);
                    end

                case 'NORTH_YELLOW'
                    app.TrafficSignalStates.North = 'YELLOW';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'NORTH_YELLOW';
                    app.SignalPhaseTimeRemaining = app.SignalTimingConfig.YellowDuration;
                    app.LastDisplayedGreenTime = 0;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'North YELLOW';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.CurrentGreenTimeValue.Text = '0s';
                    end

                case {'SOUTH_GREEN', 'South'}
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'GREEN';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'SOUTH_GREEN';
                    app.SignalPhaseTimeRemaining = gDur;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'South GREEN';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.LastDisplayedGreenTime = round(app.SignalPhaseTimeRemaining);
                        app.CurrentGreenTimeValue.Text = sprintf('%ds', app.LastDisplayedGreenTime);
                    end

                case 'SOUTH_YELLOW'
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'YELLOW';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'SOUTH_YELLOW';
                    app.SignalPhaseTimeRemaining = app.SignalTimingConfig.YellowDuration;
                    app.LastDisplayedGreenTime = 0;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'South YELLOW';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.CurrentGreenTimeValue.Text = '0s';
                    end

                case {'EAST_GREEN', 'East'}
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'GREEN';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'EAST_GREEN';
                    app.SignalPhaseTimeRemaining = gDur;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'East GREEN';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.LastDisplayedGreenTime = round(app.SignalPhaseTimeRemaining);
                        app.CurrentGreenTimeValue.Text = sprintf('%ds', app.LastDisplayedGreenTime);
                    end

                case 'EAST_YELLOW'
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'YELLOW';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = 'EAST_YELLOW';
                    app.SignalPhaseTimeRemaining = app.SignalTimingConfig.YellowDuration;
                    app.LastDisplayedGreenTime = 0;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'East YELLOW';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.CurrentGreenTimeValue.Text = '0s';
                    end

                case {'WEST_GREEN', 'West'}
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'GREEN';
                    app.SignalPhase = 'WEST_GREEN';
                    app.SignalPhaseTimeRemaining = gDur;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'West GREEN';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.LastDisplayedGreenTime = round(app.SignalPhaseTimeRemaining);
                        app.CurrentGreenTimeValue.Text = sprintf('%ds', app.LastDisplayedGreenTime);
                    end

                case 'WEST_YELLOW'
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'YELLOW';
                    app.SignalPhase = 'WEST_YELLOW';
                    app.SignalPhaseTimeRemaining = app.SignalTimingConfig.YellowDuration;
                    app.LastDisplayedGreenTime = 0;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'West YELLOW';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.CurrentGreenTimeValue.Text = '0s';
                    end

                case {'ALL_RED', 'ALL_RED_1', 'ALL_RED_2'}
                    app.TrafficSignalStates.North = 'RED';
                    app.TrafficSignalStates.South = 'RED';
                    app.TrafficSignalStates.East  = 'RED';
                    app.TrafficSignalStates.West  = 'RED';
                    app.SignalPhase = phaseName;
                    app.SignalPhaseTimeRemaining = app.SignalTimingConfig.AllRedDuration;
                    app.LastDisplayedGreenTime = 0;
                    if ~isempty(app.CurrentGreenRoadValue) && isvalid(app.CurrentGreenRoadValue)
                        app.CurrentGreenRoadValue.Text = 'ALL RED';
                    end
                    if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                        app.CurrentGreenTimeValue.Text = '0s';
                    end

                case 'NS_GREEN'
                    if nargin >= 3 && ~isempty(optDuration)
                        app.setSignalPhase('NORTH_GREEN', optDuration);
                    else
                        app.setSignalPhase('NORTH_GREEN');
                    end
                    return;
                case 'NS_YELLOW'
                    app.setSignalPhase('NORTH_YELLOW');
                    return;
                case 'EW_GREEN'
                    if nargin >= 3 && ~isempty(optDuration)
                        app.setSignalPhase('EAST_GREEN', optDuration);
                    else
                        app.setSignalPhase('EAST_GREEN');
                    end
                    return;
                case 'EW_YELLOW'
                    app.setSignalPhase('EAST_YELLOW');
                    return;

                otherwise
                    error('Unknown signal phase: %s', phaseName);
            end

            app.updateSignalVisuals();
        end

        function state = getSignalState(app, direction)
            % Returns current state of the specified traffic signal ('RED', 'YELLOW', 'GREEN')
            if isfield(app.TrafficSignalStates, direction)
                state = app.TrafficSignalStates.(direction);
            else
                state = 'RED';
            end
        end

        function phase = getSignalPhase(app)
            % Returns current signal phase identifier
            phase = app.SignalPhase;
        end

        function decision = getStopDecision(app, veh)
            % Evaluates whether a vehicle must stop at the stop line or may proceed
            % based on vehicle position, direction, and traffic signal state.
            decision = struct();
            decision.Direction = veh.Direction;
            decision.SignalState = app.getSignalState(veh.Direction);

            % Calculate front bumper coordinate and distance to stop line
            L = veh.Length;
            stopBuffer = app.SignalTimingConfig.StopBuffer;
            yellowDist = app.SignalTimingConfig.YellowDecisionDist;

            switch veh.Direction
                case 'North'
                    % Moving downwards: front bumper is at Y - L/2, stop line is Y = 20
                    front = veh.Y - L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.North.Y(1);
                    hasCrossed = (front < stopLine);
                    distToStop = front - stopLine;

                case 'South'
                    % Moving upwards: front bumper is at Y + L/2, stop line is Y = -20
                    front = veh.Y + L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.South.Y(1);
                    hasCrossed = (front > stopLine);
                    distToStop = stopLine - front;

                case 'East'
                    % Moving leftwards: front bumper is at X - L/2, stop line is X = 20
                    front = veh.X - L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.East.X(1);
                    hasCrossed = (front < stopLine);
                    distToStop = front - stopLine;

                case 'West'
                    % Moving rightwards: front bumper is at X + L/2, stop line is X = -20
                    front = veh.X + L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.West.X(1);
                    hasCrossed = (front > stopLine);
                    distToStop = stopLine - front;

                otherwise
                    hasCrossed = false;
                    distToStop = 0;
            end

            decision.HasCrossedStopLine = hasCrossed;
            decision.DistToStopLine = distToStop;

            % Requirement 3: Check if vehicle is committed to crossing intersection
            isCommitted = app.isVehicleCommitted(veh);

            if hasCrossed || isCommitted
                % Requirement 13 & Emergency Safety: Committed vehicles continue route through intersection
                decision.MustStop = false;
                decision.AllowedAdvancement = veh.Speed;
            else
                % Vehicle is approaching stop line (uncommitted)
                headroom = distToStop - stopBuffer;
                switch decision.SignalState
                    case 'GREEN'
                        decision.MustStop = false;
                        decision.AllowedAdvancement = veh.Speed;

                    case 'YELLOW'
                        if distToStop < yellowDist
                            % Passed stopping decision point: clear safely
                            decision.MustStop = false;
                            decision.AllowedAdvancement = veh.Speed;
                        else
                            % Sufficient distance to stop safely before stop line
                            decision.MustStop = true;
                            decision.AllowedAdvancement = max(0, min(veh.Speed, headroom));
                        end

                    case 'RED'
                        % Must stop before stop line
                        decision.MustStop = true;
                        decision.AllowedAdvancement = max(0, min(veh.Speed, headroom));

                    otherwise
                        decision.MustStop = true;
                        decision.AllowedAdvancement = max(0, min(veh.Speed, headroom));
                end
            end
        end

        function [proceed, maxAdv] = canVehicleProceed(app, veh)
            % Returns boolean flag and maximum allowed advancement for vehicle
            dec = app.getStopDecision(veh);
            proceed = ~dec.MustStop;
            maxAdv = dec.AllowedAdvancement;
        end

        function counts = getVehicleCounts(app)
            % Calculates live active vehicle counts per approach based on stored origin Direction.
            counts = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);
            if isempty(app.ActiveVehicles)
                app.VehicleCounts = counts;
                return;
            end

            activeIDs = [app.ActiveVehicles.ID];
            [~, uniqueIdx] = unique(activeIDs, 'stable');
            uniqueVehicles = app.ActiveVehicles(uniqueIdx);

            dirs = {uniqueVehicles.Direction};
            counts.North = sum(strcmp(dirs, 'North'));
            counts.South = sum(strcmp(dirs, 'South'));
            counts.East  = sum(strcmp(dirs, 'East'));
            counts.West  = sum(strcmp(dirs, 'West'));

            app.VehicleCounts = counts;
        end

        function count = getVehicleCountByDirection(app, direction)
            validDirs = {'North', 'South', 'East', 'West'};
            if ~ismember(direction, validDirs)
                error('Invalid direction specified: %s. Must be North, South, East, or West.', direction);
            end

            counts = app.getVehicleCounts();
            count = counts.(direction);
        end

        function updateVehicleCounts(app)
            counts = app.getVehicleCounts();

            countsChanged = isempty(app.LastReportedCounts) || ...
                counts.North ~= app.LastReportedCounts.North || ...
                counts.South ~= app.LastReportedCounts.South || ...
                counts.East  ~= app.LastReportedCounts.East  || ...
                counts.West  ~= app.LastReportedCounts.West  || ...
                app.TotalVehiclesProcessed ~= app.LastReportedCounts.Processed;

            if countsChanged
                app.LastReportedCounts = struct(...
                    'North', counts.North, ...
                    'South', counts.South, ...
                    'East',  counts.East, ...
                    'West',  counts.West, ...
                    'Processed', app.TotalVehiclesProcessed);

                if ~isempty(app.NorthVehiclesValue) && isvalid(app.NorthVehiclesValue)
                    app.NorthVehiclesValue.Text = sprintf('%d', counts.North);
                end
                if ~isempty(app.SouthVehiclesValue) && isvalid(app.SouthVehiclesValue)
                    app.SouthVehiclesValue.Text = sprintf('%d', counts.South);
                end
                if ~isempty(app.EastVehiclesValue) && isvalid(app.EastVehiclesValue)
                    app.EastVehiclesValue.Text = sprintf('%d', counts.East);
                end
                if ~isempty(app.WestVehiclesValue) && isvalid(app.WestVehiclesValue)
                    app.WestVehiclesValue.Text = sprintf('%d', counts.West);
                end
                if ~isempty(app.VehiclesProcessedValue) && isvalid(app.VehiclesProcessedValue)
                    app.VehiclesProcessedValue.Text = sprintf('%d', app.TotalVehiclesProcessed);
                end

                app.calculateTrafficDensity();
                app.updateTrafficDensityUI();
            end
        end

        % -------------------------------------------------------------
        % Phase 6 Methods: Traffic Density Calculation & Monitoring
        % -------------------------------------------------------------
        function initializeTrafficDensity(app)
            if isempty(app.MaxVehiclesPerApproach) || app.MaxVehiclesPerApproach <= 0
                app.MaxVehiclesPerApproach = 10;
            end
            app.TrafficDensityConfig = struct('MaxVehiclesPerApproach', app.MaxVehiclesPerApproach);

            app.TrafficDensity = struct(...
                'North', struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
                'South', struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
                'East',  struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'), ...
                'West',  struct('Count', 0, 'Percentage', 0, 'Level', 'LOW'));

            app.SmoothedDensity = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);

            app.updateTrafficDensityUI();
        end

        function density = calculateDensityForDirection(app, direction)
            % Calculates normalized traffic density for INCOMING vehicles (Requirement 10)
            validDirs = {'North', 'South', 'East', 'West'};
            if ~ismember(direction, validDirs)
                error('Invalid direction specified: %s. Must be North, South, East, or West.', direction);
            end

            incomingVehs = app.getIncomingVehiclesForDirection(direction);
            cnt = numel(incomingVehs);

            maxCap = app.MaxVehiclesPerApproach;
            if isempty(maxCap) || maxCap <= 0
                maxCap = 10;
            end

            pct = min(round((cnt / maxCap) * 100), 100);
            lvl = app.getDensityLevel(pct);

            density = struct('Count', cnt, 'Percentage', pct, 'Level', lvl);
        end

        function densities = calculateTrafficDensity(app)
            % Calculates traffic density independently for North, South, East, West
            dirs = {'North', 'South', 'East', 'West'};
            for i = 1:numel(dirs)
                d = dirs{i};
                app.TrafficDensity.(d) = app.calculateDensityForDirection(d);
                pct = app.TrafficDensity.(d).Percentage;
                if ~isfield(app.SmoothedDensity, d) || isempty(app.SmoothedDensity.(d))
                    app.SmoothedDensity.(d) = pct;
                else
                    app.SmoothedDensity.(d) = 0.7 * app.SmoothedDensity.(d) + 0.3 * pct;
                end
            end
            densities = app.TrafficDensity;
        end

        function level = getDensityLevel(~, percent)
            % Categorizes density percentage into defined standard thresholds:
            % 0-30%: LOW, 31-60%: MEDIUM, 61-80%: HIGH, 81-100%: VERY HIGH
            if percent <= 30
                level = 'LOW';
            elseif percent <= 60
                level = 'MEDIUM';
            elseif percent <= 80
                level = 'HIGH';
            else
                level = 'VERY HIGH';
            end
        end

        function color = getDensityLevelColor(~, level)
            % Returns curated theme color for density status display
            switch upper(level)
                case 'LOW'
                    color = [0.4 0.85 0.5];    % Mint green
                case 'MEDIUM'
                    color = [0.95 0.8 0.2];    % Amber yellow
                case 'HIGH'
                    color = [0.95 0.55 0.15];  % Orange
                case 'VERY HIGH'
                    color = [0.95 0.25 0.25];  % Alert red
                otherwise
                    color = [1 1 1];           % Crisp white
            end
        end

        function updateTrafficDensityUI(app)
            % Synchronizes all directional density badges, Traffic Information panel,
            % and KPI Congestion Level card.
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end

            dirs = {'North', 'South', 'East', 'West'};
            dirLabels = {app.NorthDensityValue, app.SouthDensityValue, app.EastDensityValue, app.WestDensityValue};

            maxPct = -1;
            maxDir = 'North';
            maxLvl = 'LOW';

            for i = 1:numel(dirs)
                d = dirs{i};
                if isfield(app.TrafficDensity, d)
                    pct = app.TrafficDensity.(d).Percentage;
                    lvl = app.TrafficDensity.(d).Level;
                else
                    pct = 0;
                    lvl = 'LOW';
                end

                % Track maximum directional density
                if pct > maxPct
                    maxPct = pct;
                    maxDir = d;
                    maxLvl = lvl;
                end

                % Update directional readout badge
                hLbl = dirLabels{i};
                if ~isempty(hLbl) && isvalid(hLbl)
                    hLbl.Text = sprintf('%d%% (%s)', pct, lvl);
                    hLbl.FontColor = app.getDensityLevelColor(lvl);
                end

                % Update directional visual meter bars
                if isfield(app.DensityMeters, d) && numel(app.DensityMeters.(d)) == 4
                    bars = app.DensityMeters.(d);
                    offCol = [0.12 0.15 0.22];
                    lvlCol = app.getDensityLevelColor(lvl);
                    switch lvl
                        case 'LOW'
                            set(bars(1), 'BackgroundColor', lvlCol);
                            set(bars(2:4), 'BackgroundColor', offCol);
                        case 'MEDIUM'
                            set(bars(1:2), 'BackgroundColor', lvlCol);
                            set(bars(3:4), 'BackgroundColor', offCol);
                        case 'HIGH'
                            set(bars(1:3), 'BackgroundColor', lvlCol);
                            set(bars(4), 'BackgroundColor', offCol);
                        case 'VERY HIGH'
                            set(bars(1:4), 'BackgroundColor', lvlCol);
                        otherwise
                            set(bars(1:4), 'BackgroundColor', offCol);
                    end
                end
            end

            % Update Traffic Information Panel: Traffic Density
            if ~isempty(app.TrafficDensityValue) && isvalid(app.TrafficDensityValue)
                if maxPct <= 0
                    app.TrafficDensityValue.Text = '0%';
                    app.TrafficDensityValue.FontColor = [1 1 1];
                else
                    app.TrafficDensityValue.Text = sprintf('%s %d%% (%s)', maxDir, maxPct, maxLvl);
                    app.TrafficDensityValue.FontColor = app.getDensityLevelColor(maxLvl);
                end
            end

            % Update KPI Panel: Congestion Level (Title Case + percentage)
            if ~isempty(app.CongestionValue) && isvalid(app.CongestionValue)
                switch upper(maxLvl)
                    case 'LOW'
                        titleLvl = 'Low';
                    case 'MEDIUM'
                        titleLvl = 'Medium';
                    case 'HIGH'
                        titleLvl = 'High';
                    case 'VERY HIGH'
                        titleLvl = 'Very High';
                    otherwise
                        titleLvl = 'Low';
                end
                app.CongestionValue.Text = sprintf('%s (%d%%)', titleLvl, max(0, maxPct));
                app.CongestionValue.FontColor = app.getDensityLevelColor(maxLvl);
            end
        end

        % -------------------------------------------------------------
        % Phase 7 Methods: Dynamic Queue/Traffic-Demand Signal Controller Engine
        % -------------------------------------------------------------
        function [duration, level] = calculateGreenDuration(app, densityPercent)
            % Demand-controlled green phase duration (No fixed 5-30s timer)
            level = app.getDensityLevel(densityPercent);
            duration = Inf;
        end

        function [nsDemand, ewDemand, nsMaxDir, ewMaxDir] = getGroupDemands(app)
            app.calculateTrafficDensity();
            northPct = app.TrafficDensity.North.Percentage;
            southPct = app.TrafficDensity.South.Percentage;
            eastPct  = app.TrafficDensity.East.Percentage;
            westPct  = app.TrafficDensity.West.Percentage;

            if northPct >= southPct
                nsDemand = northPct;
                nsMaxDir = 'North';
            else
                nsDemand = southPct;
                nsMaxDir = 'South';
            end

            if eastPct >= westPct
                ewDemand = eastPct;
                ewMaxDir = 'East';
            else
                ewDemand = westPct;
                ewMaxDir = 'West';
            end
        end

        function vehs = getIncomingVehiclesForDirection(app, direction)
            vehs = struct([]);
            if isempty(app.ActiveVehicles)
                return;
            end
            isInc = false(1, numel(app.ActiveVehicles));
            for i = 1:numel(app.ActiveVehicles)
                v = app.ActiveVehicles(i);
                if strcmp(v.Direction, direction)
                    sigDec = app.getStopDecision(v);
                    if ~sigDec.HasCrossedStopLine
                        isInc(i) = true;
                    end
                end
            end
            vehs = app.ActiveVehicles(isInc);
        end

        function roadName = getCurrentGreenRoadName(app)
            roadName = '';
            switch app.SignalPhase
                case 'NORTH_GREEN', roadName = 'North';
                case 'SOUTH_GREEN', roadName = 'South';
                case 'EAST_GREEN',  roadName = 'East';
                case 'WEST_GREEN',  roadName = 'West';
            end
        end

        function emRoad = getEmergencyPriorityRoad(app)
            emRoad = '';
            if ~app.EmergencyPriorityEnabled
                return;
            end

            % Scan active incoming emergency vehicles
            emVehs = struct([]);
            if ~isempty(app.ActiveVehicles)
                isEm = false(1, numel(app.ActiveVehicles));
                for i = 1:numel(app.ActiveVehicles)
                    v = app.ActiveVehicles(i);
                    if isfield(v, 'IsEmergency') && v.IsEmergency
                        sigDec = app.getStopDecision(v);
                        if ~sigDec.HasCrossedStopLine
                            isEm(i) = true;
                        end
                    end
                end
                emVehs = app.ActiveVehicles(isEm);
            end

            if isempty(emVehs) && app.EmergencyActive && ~isempty(app.EmergencyDirection)
                emRoad = [upper(app.EmergencyDirection(1)) lower(app.EmergencyDirection(2:end))];
                return;
            end

            if isempty(emVehs)
                return;
            end

            % Priority rules for multiple emergency vehicles:
            % 1. Closest to intersection
            % 2. Highest number of emergency vehicles on that approach
            % 3. Fixed priority: NORTH -> EAST -> SOUTH -> WEST
            dirs = {'North', 'South', 'East', 'West'};
            fixedRank = [1, 3, 2, 4]; % North=1, East=2, South=3, West=4

            minDists = [Inf, Inf, Inf, Inf];
            counts = [0, 0, 0, 0];

            for i = 1:numel(emVehs)
                v = emVehs(i);
                dIdx = find(strcmp(dirs, v.Direction), 1);
                if ~isempty(dIdx)
                    dec = app.getStopDecision(v);
                    minDists(dIdx) = min(minDists(dIdx), max(0, dec.DistToStopLine));
                    counts(dIdx) = counts(dIdx) + 1;
                end
            end

            activeDirs = find(counts > 0);
            bestDIdx = activeDirs(1);
            for i = 2:numel(activeDirs)
                dIdx = activeDirs(i);
                if minDists(dIdx) < minDists(bestDIdx) - 0.01
                    bestDIdx = dIdx;
                elseif abs(minDists(dIdx) - minDists(bestDIdx)) <= 0.01
                    if counts(dIdx) > counts(bestDIdx)
                        bestDIdx = dIdx;
                    elseif counts(dIdx) == counts(bestDIdx)
                        if fixedRank(dIdx) < fixedRank(bestDIdx)
                            bestDIdx = dIdx;
                        end
                    end
                end
            end
            emRoad = dirs{bestDIdx};
        end

        function bestIdx = rankRoadsDeterministic(~, ~, smoothDensities, maxWaitTimes, rawCounts, candidateIndices)
            % Priority Order:
            % 1. Highest smoothed incoming density
            % 2. Longest waiting queue / oldest waiting vehicle
            % 3. Highest raw incoming vehicle count
            % 4. Fixed priority: NORTH -> EAST -> SOUTH -> WEST
            if isempty(candidateIndices)
                candidateIndices = 1:4;
            end

            fixedRank = [1, 3, 2, 4]; % North=1, East=2, South=3, West=4

            bestIdx = candidateIndices(1);
            for i = 2:numel(candidateIndices)
                cand = candidateIndices(i);
                if smoothDensities(cand) > smoothDensities(bestIdx) + 0.001
                    bestIdx = cand;
                elseif abs(smoothDensities(cand) - smoothDensities(bestIdx)) <= 0.001
                    if maxWaitTimes(cand) > maxWaitTimes(bestIdx) + 0.001
                        bestIdx = cand;
                    elseif abs(maxWaitTimes(cand) - maxWaitTimes(bestIdx)) <= 0.001
                        if rawCounts(cand) > rawCounts(bestIdx)
                            bestIdx = cand;
                        elseif rawCounts(cand) == rawCounts(bestIdx)
                            if fixedRank(cand) < fixedRank(bestIdx)
                                bestIdx = cand;
                            end
                        end
                    end
                end
            end
        end

        function decision = evaluateAIDecision(app)
            % True Queue/Traffic-Demand Signal Decision Engine
            app.calculateTrafficDensity();
            nPct = app.TrafficDensity.North.Percentage;
            sPct = app.TrafficDensity.South.Percentage;
            ePct = app.TrafficDensity.East.Percentage;
            wPct = app.TrafficDensity.West.Percentage;

            nSmooth = app.SmoothedDensity.North;
            sSmooth = app.SmoothedDensity.South;
            eSmooth = app.SmoothedDensity.East;
            wSmooth = app.SmoothedDensity.West;

            counts = app.getVehicleCounts();
            nCnt = counts.North;
            sCnt = counts.South;
            eCnt = counts.East;
            wCnt = counts.West;

            roads = {'North', 'South', 'East', 'West'};
            phases = {'NORTH_GREEN', 'SOUTH_GREEN', 'EAST_GREEN', 'WEST_GREEN'};
            smoothDensities = [nSmooth, sSmooth, eSmooth, wSmooth];
            rawCounts = [nCnt, sCnt, eCnt, wCnt];

            maxWaitTimes = [0, 0, 0, 0];
            for rIdx = 1:4
                rName = roads{rIdx};
                rVehs = app.getIncomingVehiclesForDirection(rName);
                if ~isempty(rVehs)
                    maxWaitTimes(rIdx) = max([rVehs.WaitTime]);
                end
            end

            emRoad = app.getEmergencyPriorityRoad();
            if ~isempty(emRoad)
                bestIdx = find(strcmp(roads, emRoad), 1);
                reason = sprintf('Emergency priority (%s)', app.EmergencyType);
            else
                currentGreenRoad = app.getCurrentGreenRoadName();
                if isempty(currentGreenRoad) && ~isempty(app.LastGreenGroup) && ismember(app.LastGreenGroup, roads)
                    currentGreenRoad = app.LastGreenGroup;
                end

                if ~isempty(currentGreenRoad)
                    cIdx = find(strcmp(roads, currentGreenRoad), 1);
                    cCount = rawCounts(cIdx);
                    cSmooth = smoothDensities(cIdx);

                    if cCount <= app.QueueClearThreshold
                        bestIdx = app.rankRoadsDeterministic(roads, smoothDensities, maxWaitTimes, rawCounts, 1:4);
                        if max(smoothDensities) == 0 && max(rawCounts) == 0
                            bestIdx = mod(cIdx, 4) + 1;
                        end
                        reason = 'Current green queue cleared -> Evaluated highest demand road';
                    else
                        diffs = smoothDensities - cSmooth;
                        higherIndices = find(diffs >= app.HysteresisThreshold);

                        if ~isempty(higherIndices)
                            bestIdx = app.rankRoadsDeterministic(roads, smoothDensities, maxWaitTimes, rawCounts, higherIndices);
                            reason = 'Another road exceeded hysteresis threshold (10% higher demand)';
                        else
                            bestIdx = cIdx;
                            reason = 'Current green road queue active (within hysteresis threshold)';
                        end
                    end
                else
                    bestIdx = app.rankRoadsDeterministic(roads, smoothDensities, maxWaitTimes, rawCounts, 1:4);
                    reason = 'Highest traffic demand';
                end
            end

            selectedRoad = roads{bestIdx};
            nextPhase = phases{bestIdx};
            selectedDensity = smoothDensities(bestIdx);
            selectedLevel = app.getDensityLevel(selectedDensity);

            arrowChar = char(8594);
            decText = sprintf('%s GREEN: %d veh incoming (%.0f%%) %s %s', ...
                upper(selectedRoad), rawCounts(bestIdx), selectedDensity, arrowChar, reason);

            decision = struct();
            decision.SelectedRoad = selectedRoad;
            decision.SelectedGroup = selectedRoad;
            decision.NextPhase = nextPhase;
            decision.GreenDuration = Inf;
            decision.SelectedLevel = selectedLevel;
            decision.SelectedDensity = selectedDensity;
            decision.NorthDensity = nPct;
            decision.SouthDensity = sPct;
            decision.EastDensity = ePct;
            decision.WestDensity = wPct;
            decision.StarvationPrevented = false;
            decision.Reason = reason;
            decision.DecisionText = decText;
        end

        function decision = selectNextAdaptivePhase(app)
            decision = app.evaluateAIDecision();
            app.AIDecisionRecord = decision;

            if strcmp(decision.SelectedGroup, app.LastGreenGroup)
                app.ConsecutiveGreenCount = app.ConsecutiveGreenCount + 1;
            else
                app.LastGreenGroup = decision.SelectedGroup;
                app.ConsecutiveGreenCount = 1;
            end

            if ~isempty(app.AIDecisionValue) && isvalid(app.AIDecisionValue)
                app.AIDecisionValue.Text = decision.DecisionText;
                app.AIDecisionValue.FontColor = [0.2 0.75 1.0];
            end

            app.setSignalPhase(decision.NextPhase);
        end

        % -------------------------------------------------------------
        % Phase 8 Methods: Emergency Vehicle Priority & Signal Preemption
        % -------------------------------------------------------------
        function veh = triggerEmergencyVehicle(app, direction, emergencyType)
            % Programmatically triggers an emergency vehicle spawn and activates signal preemption.
            % direction: 'North', 'South', 'East', 'West' (default: 'East')
            % emergencyType: 'Ambulance', 'Fire Truck', 'Police' (default: 'Ambulance')
            if nargin < 2 || isempty(direction)
                roads = {'North', 'South', 'East', 'West'};
                direction = roads{randi(numel(roads))};
            end
            if nargin < 3 || isempty(emergencyType)
                emTypes = {'Ambulance', 'Police', 'Fire Truck'};
                emergencyType = emTypes{randi(numel(emTypes))};
            end

            % Attempt to spawn vehicle
            veh = app.spawnSingleVehicle(direction, emergencyType);
            if isempty(veh)
                % If entry clearance was blocked, advance vehicles safely to relieve entry pressure
                app.updateVehicles();
                veh = app.spawnSingleVehicle(direction, emergencyType);
                if isempty(veh)
                    % If still blocked, safely remove vehicle closest to entry point
                    matchIdx = find(strcmp({app.ActiveVehicles.Direction}, direction));
                    if ~isempty(matchIdx)
                        switch direction
                            case 'North', [~, closeIdx] = max([app.ActiveVehicles(matchIdx).Y]);
                            case 'South', [~, closeIdx] = min([app.ActiveVehicles(matchIdx).Y]);
                            case 'East',  [~, closeIdx] = max([app.ActiveVehicles(matchIdx).X]);
                            case 'West',  [~, closeIdx] = min([app.ActiveVehicles(matchIdx).X]);
                        end
                        app.removeVehicle(matchIdx(closeIdx));
                        veh = app.spawnSingleVehicle(direction, emergencyType);
                    end
                end
            end

            if ~isempty(veh)
                app.requestEmergencyPriority(veh);
            end
        end

        function requestEmergencyPriority(app, veh)
            % Maps emergency vehicle's STORED origin direction to target signal phase:
            % North -> NORTH_GREEN, South -> SOUTH_GREEN, East -> EAST_GREEN, West -> WEST_GREEN
            originDir = veh.Direction;
            roadCap = [upper(originDir(1)) lower(originDir(2:end))];

            if strcmp(roadCap, 'North') || strcmp(roadCap, 'South')
                reqGroup = 'NS';
            else
                reqGroup = 'EW';
            end

            if app.AdaptiveTimingEnabled || ismember(app.SignalPhase, {'NORTH_GREEN', 'SOUTH_GREEN', 'EAST_GREEN', 'WEST_GREEN'})
                targetPhase = sprintf('%s_GREEN', upper(originDir));
            else
                if strcmp(reqGroup, 'NS')
                    targetPhase = 'NS_GREEN';
                else
                    targetPhase = 'EW_GREEN';
                end
            end

            if ~app.EmergencyPriorityEnabled
                return;
            end

            % Handle case where emergency priority is ALREADY active
            if app.EmergencyActive
                if strcmp(app.EmergencyTargetGroup, reqGroup) || strcmp(app.SignalPhase, targetPhase)
                    % Same signal group/phase: shares current priority green
                    if ~ismember(veh.ID, app.EmergencyVehicleID)
                        app.EmergencyVehicleID(end + 1) = veh.ID;
                    end
                    return;
                else
                    % Opposite/different signal group: enqueue request safely
                    req = struct('ID', veh.ID, 'Direction', originDir, ...
                                 'EmergencyType', veh.EmergencyType, 'Group', reqGroup);
                    if isempty(app.EmergencyQueue)
                        app.EmergencyQueue = req;
                    else
                        app.EmergencyQueue(end + 1) = req;
                    end
                    return;
                end
            end

            % Activate emergency priority
            app.EmergencyActive = true;
            app.EmergencyDirection = originDir;
            app.EmergencyType = veh.EmergencyType;
            app.EmergencyVehicleID = veh.ID;
            app.EmergencyTargetGroup = reqGroup;
            app.EmergencyHoldTime = 0.0;

            % Update UI components to clearly display Emergency Priority state
            app.updateEmergencyUI();

            % Signal preemption logic:
            % 1. If requested group/phase is ALREADY GREEN:
            %    Keep that phase GREEN. Do NOT restart or unnecessarily change the phase.
            % 2. If conflicting phase is currently GREEN:
            %    Safely transition IMMEDIATELY: Current GREEN -> YELLOW (2s) -> ALL RED (1s) -> Emergency GREEN.
            % 3. If currently in YELLOW or ALL RED:
            %    Let the transition safely conclude into the emergency GREEN.
            currentPhase = app.SignalPhase;
            isAlreadyGreen = strcmp(currentPhase, targetPhase) || ...
                (strcmp(currentPhase, 'EW_GREEN') && (strcmp(originDir, 'East') || strcmp(originDir, 'West'))) || ...
                (strcmp(currentPhase, 'NS_GREEN') && (strcmp(originDir, 'North') || strcmp(originDir, 'South')));

            if isAlreadyGreen
                % Target group/direction is already GREEN!
                app.EmergencyPriorityState = 'ACTIVE';
                app.SignalPhaseTimeRemaining = app.EmergencyClearanceTimeout;
                if ~isempty(app.CurrentGreenTimeValue) && isvalid(app.CurrentGreenTimeValue)
                    app.CurrentGreenTimeValue.Text = sprintf('%ds', round(app.EmergencyClearanceTimeout));
                end
            else
                % Target road is NOT currently green: switch active green to yellow IMMEDIATELY
                app.EmergencyPriorityState = 'PREEMPTING';
                switch currentPhase
                    case 'NORTH_GREEN'
                        app.setSignalPhase('NORTH_YELLOW');
                    case 'SOUTH_GREEN'
                        app.setSignalPhase('SOUTH_YELLOW');
                    case 'EAST_GREEN'
                        app.setSignalPhase('EAST_YELLOW');
                    case 'WEST_GREEN'
                        app.setSignalPhase('WEST_YELLOW');
                    case 'NS_GREEN'
                        app.setSignalPhase('NS_YELLOW');
                    case 'EW_GREEN'
                        app.setSignalPhase('EW_YELLOW');
                    otherwise
                        % If currently in YELLOW or ALL_RED, stay in PREEMPTING until ALL_RED transitions to targetPhase
                end
            end
        end

        function releaseEmergencyPriority(app)
            % Safely releases emergency priority through:
            % Emergency GREEN -> YELLOW (2s) -> ALL RED (1s) -> return to AI Adaptive.
            app.EmergencyActive = false;
            app.EmergencyPriorityState = 'CLEARING';

            % Transition current emergency green to Yellow
            switch app.SignalPhase
                case 'NORTH_GREEN'
                    app.setSignalPhase('NORTH_YELLOW');
                case 'SOUTH_GREEN'
                    app.setSignalPhase('SOUTH_YELLOW');
                case 'EAST_GREEN'
                    app.setSignalPhase('EAST_YELLOW');
                case 'WEST_GREEN'
                    app.setSignalPhase('WEST_YELLOW');
                case 'NS_GREEN'
                    app.setSignalPhase('NS_YELLOW');
                case 'EW_GREEN'
                    app.setSignalPhase('EW_YELLOW');
                otherwise
                    app.setSignalPhase('ALL_RED');
            end
        end

        function cleared = checkEmergencyCleared(app)
            % Evaluates whether all currently served emergency vehicles have completely
            % cleared the intersection conflict zone.
            cleared = true;
            if isempty(app.EmergencyVehicleID)
                return;
            end

            for i = 1:numel(app.EmergencyVehicleID)
                vId = app.EmergencyVehicleID(i);
                vIdx = find([app.ActiveVehicles.ID] == vId, 1);
                if isempty(vIdx)
                    % Vehicle no longer in active list (has exited canvas) -> cleared
                    continue;
                end

                v = app.ActiveVehicles(vIdx);
                % Check if vehicle has crossed beyond the far boundary of the intersection (-20 to +20)
                switch v.Direction
                    case 'North'
                        % Moving downwards: cleared when rear bumper <= -20.0
                        if (v.Y + v.Length / 2.0) > -20.0
                            cleared = false;
                            return;
                        end
                    case 'South'
                        % Moving upwards: cleared when rear bumper >= 20.0
                        if (v.Y - v.Length / 2.0) < 20.0
                            cleared = false;
                            return;
                        end
                    case 'East'
                        % Moving leftwards: cleared when rear bumper <= -20.0
                        if (v.X + v.Length / 2.0) > -20.0
                            cleared = false;
                            return;
                        end
                    case 'West'
                        % Moving rightwards: cleared when rear bumper >= 20.0
                end
            end
        end

        function committed = isVehicleCommitted(app, veh)
            % Evaluates whether a vehicle is committed to crossing the intersection.
            % A vehicle is committed if:
            % 1. Front bumper has crossed the stop line, OR
            % 2. Physical bounding box is inside central intersection conflict zone (abs(X) <= 22 & abs(Y) <= 22), OR
            % 3. Signal is YELLOW and vehicle is near stop line (distToStop <= YellowDecisionDist [14m]).
            L = veh.Length;
            yellowDist = app.SignalTimingConfig.YellowDecisionDist;
            sigState = app.getSignalState(veh.Direction);

            switch veh.Direction
                case 'North'
                    front = veh.Y - L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.North.Y(1);
                    hasCrossed = (front < stopLine);
                    distToStop = front - stopLine;
                case 'South'
                    front = veh.Y + L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.South.Y(1);
                    hasCrossed = (front > stopLine);
                    distToStop = stopLine - front;
                case 'East'
                    front = veh.X - L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.East.X(1);
                    hasCrossed = (front < stopLine);
                    distToStop = front - stopLine;
                case 'West'
                    front = veh.X + L / 2.0;
                    stopLine = app.IntersectionConfig.StopLineCoordinates.West.X(1);
                    hasCrossed = (front > stopLine);
                    distToStop = stopLine - front;
                otherwise
                    hasCrossed = false;
                    distToStop = Inf;
            end

            isInsideConflict = (abs(veh.X) <= 22.0 && abs(veh.Y) <= 22.0);
            isNearYellowStopLine = (strcmp(sigState, 'YELLOW') && ~hasCrossed && distToStop >= 0 && distToStop <= yellowDist);

            committed = hasCrossed || isInsideConflict || isNearYellowStopLine;
        end

        function clear = checkIntersectionConflictZoneClear(app)
            % Evaluates whether the central intersection conflict zone ([-22, +22] x [-22, +22])
            % is completely clear of non-emergency committed vehicles before granting Emergency GREEN.
            clear = true;
            if isempty(app.ActiveVehicles)
                return;
            end

            for i = 1:numel(app.ActiveVehicles)
                v = app.ActiveVehicles(i);
                if isfield(v, 'IsEmergency') && v.IsEmergency
                    continue; % Emergency vehicles are exempt from this clearance check
                end

                % Check if vehicle is inside the intersection conflict zone
                if abs(v.X) <= 22.0 && abs(v.Y) <= 22.0
                    hasExited = false;
                    switch v.Direction
                        case 'North'
                            hasExited = (v.Y < -22.0);
                        case 'South'
                            hasExited = (v.Y > 22.0);
                        case 'East'
                            hasExited = (v.X < -22.0);
                        case 'West'
                            hasExited = (v.X > 22.0);
                    end

                    if ~hasExited
                        clear = false;
                        return;
                    end
                end
            end
        end

        function updateEmergencyUI(app)
            % Synchronizes dashboard UI during emergency priority
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end
            arrowChar = char(8594);
            if app.EmergencyActive
                if ~isempty(app.ControllerModeValue) && isvalid(app.ControllerModeValue)
                    app.ControllerModeValue.Text = 'EMERGENCY PRIORITY';
                    app.ControllerModeValue.FontColor = [0.95 0.25 0.25];
                end
                if ~isempty(app.AIDecisionValue) && isvalid(app.AIDecisionValue)
                    app.AIDecisionValue.Text = sprintf('Emergency: %s from %s %s %s priority', ...
                        app.EmergencyType, app.EmergencyDirection, arrowChar, upper(app.EmergencyDirection));
                    app.AIDecisionValue.FontColor = [0.95 0.25 0.25];
                end
                if ~isempty(app.SystemStatusValue) && isvalid(app.SystemStatusValue)
                    if app.SimulationRunning
                        app.SystemStatusValue.Text = 'RUNNING - EMERGENCY';
                    else
                        app.SystemStatusValue.Text = 'EMERGENCY MODE';
                    end
                    app.SystemStatusValue.FontColor = [0.92 0.52 0.05];
                end
            end
        end

        % -------------------------------------------------------------
        % Phase 9 Methods: Pedestrian / Human Simulation
        % -------------------------------------------------------------
        function initializePedestrians(app)
            % Clean up any existing active pedestrian graphics
            for pIdx = 1:numel(app.ActivePedestrians)
                if isfield(app.ActivePedestrians(pIdx), 'GraphicHandle') && ...
                        ~isempty(app.ActivePedestrians(pIdx).GraphicHandle) && ...
                        isvalid(app.ActivePedestrians(pIdx).GraphicHandle)
                    delete(app.ActivePedestrians(pIdx).GraphicHandle);
                end
                if isfield(app.ActivePedestrians(pIdx), 'HeadHandle') && ...
                        ~isempty(app.ActivePedestrians(pIdx).HeadHandle) && ...
                        isvalid(app.ActivePedestrians(pIdx).HeadHandle)
                    delete(app.ActivePedestrians(pIdx).HeadHandle);
                end
            end

            app.ActivePedestrians = struct(...
                'ID', {}, ...
                'X', {}, ...
                'Y', {}, ...
                'Direction', {}, ...
                'Speed', {}, ...
                'Path', {}, ...
                'GraphicHandle', {}, ...
                'HeadHandle', {}, ...
                'Color', {});

            app.NextPedestrianID = 1;

            if isempty(app.SimulationCanvas) || ~isvalid(app.SimulationCanvas)
                return;
            end

            % Palette of vibrant pedestrian coat colors
            pal = [
                0.20, 0.75, 0.95;  % Azure Cyan
                0.95, 0.40, 0.20;  % Vivid Coral
                0.90, 0.78, 0.15;  % Golden Amber
                0.35, 0.82, 0.45;  % Mint Emerald
                0.85, 0.35, 0.85;  % Orchid Magenta
                0.30, 0.55, 0.95;  % Royal Blue
                0.95, 0.30, 0.45;  % Ruby Crimson
                0.25, 0.85, 0.80   % Bright Turquoise
            ];

            % Initial spawning of 8 pedestrians (2 per corridor):
            % Corridor 1: North Sidewalk (X = 31, Y in [32, 92])
            app.spawnSinglePedestrian('North', 31, 48, 'North', 0.45, pal(1, :));
            app.spawnSinglePedestrian('North', 31, 78, 'South', 0.40, pal(2, :));

            % Corridor 2: South Sidewalk (X = -31, Y in [-92, -32])
            app.spawnSinglePedestrian('South', -31, -78, 'North', 0.45, pal(3, :));
            app.spawnSinglePedestrian('South', -31, -48, 'South', 0.40, pal(4, :));

            % Corridor 3: East Sidewalk (Y = 31, X in [32, 92])
            app.spawnSinglePedestrian('East', 48, 31, 'East', 0.45, pal(5, :));
            app.spawnSinglePedestrian('East', 78, 31, 'West', 0.40, pal(6, :));

            % Corridor 4: West Sidewalk (Y = -31, X in [-92, -32])
            app.spawnSinglePedestrian('West', -78, -31, 'East', 0.45, pal(7, :));
            app.spawnSinglePedestrian('West', -48, -31, 'West', 0.40, pal(8, :));
        end

        function ped = spawnSinglePedestrian(app, path, optX, optY, optDir, optSpeed, optColor)
            % Spawns a single pedestrian along a designated sidewalk corridor.
            % Geometrically enforces exact fixed coordinate and path boundary limits.
            ped = [];
            if isempty(app.SimulationCanvas) || ~isvalid(app.SimulationCanvas)
                return;
            end

            cfg = app.IntersectionConfig.PedestrianConfig;
            pathCfg = cfg.Paths.(path);

            % Determine default coordinates & direction if not provided
            if nargin < 3 || isempty(optX) || nargin < 4 || isempty(optY)
                if strcmp(pathCfg.Axis, 'Y')
                    posX = pathCfg.FixedCoord;
                    posY = mean(pathCfg.Range);
                else
                    posX = mean(pathCfg.Range);
                    posY = pathCfg.FixedCoord;
                end
            else
                posX = optX;
                posY = optY;
            end

            % Geometrical enforcement: lock strictly to fixed corridor coordinate
            if strcmp(pathCfg.Axis, 'Y')
                posX = pathCfg.FixedCoord;
                posY = min(max(posY, pathCfg.Range(1)), pathCfg.Range(2));
            else
                posY = pathCfg.FixedCoord;
                posX = min(max(posX, pathCfg.Range(1)), pathCfg.Range(2));
            end

            if nargin < 5 || isempty(optDir)
                if strcmp(pathCfg.Axis, 'Y')
                    optDir = 'North';
                else
                    optDir = 'East';
                end
            end

            if nargin < 6 || isempty(optSpeed)
                spd = cfg.Speed;
            else
                spd = optSpeed;
            end

            if nargin < 7 || isempty(optColor)
                col = [0.20, 0.75, 0.95];
            else
                col = optColor;
            end

            % Spacing clearance check against existing pedestrians on same path
            minClearance = cfg.MinSpacing;
            for i = 1:numel(app.ActivePedestrians)
                existPed = app.ActivePedestrians(i);
                if strcmp(existPed.Path, path)
                    d = sqrt((posX - existPed.X)^2 + (posY - existPed.Y)^2);
                    if d < minClearance
                        % Cannot spawn on top of an existing pedestrian
                        return;
                    end
                end
            end

            % Create graphics: Rounded body torso + circular head
            ax = app.SimulationCanvas;
            hBody = rectangle(ax, ...
                'Position', [posX - 1.1, posY - 1.1, 2.2, 2.2], ...
                'Curvature', [0.7 0.7], ...
                'FaceColor', col, ...
                'EdgeColor', [0.95 0.98 1.00], ...
                'LineWidth', 1.1);

            hHead = rectangle(ax, ...
                'Position', [posX - 0.6, posY - 0.6, 1.2, 1.2], ...
                'Curvature', [1 1], ...
                'FaceColor', [0.96 0.84 0.72], ...
                'EdgeColor', [0.20 0.20 0.25], ...
                'LineWidth', 0.8);

            % Store head handle in UserData for safe cascade deletion
            hBody.UserData = struct('HeadHandle', hHead);
            hBody.DeleteFcn = @(src, ~) app.cleanupPedestrianGraphics(src);

            newPed = struct();
            newPed.ID = app.NextPedestrianID;
            app.NextPedestrianID = app.NextPedestrianID + 1;
            newPed.X = posX;
            newPed.Y = posY;
            newPed.Direction = optDir;
            newPed.Speed = spd;
            newPed.Path = path;
            newPed.GraphicHandle = hBody;
            newPed.HeadHandle = hHead;
            newPed.Color = col;

            if isempty(app.ActivePedestrians)
                app.ActivePedestrians = newPed;
            else
                app.ActivePedestrians(end + 1) = newPed;
            end
            ped = newPed;
        end

        function cleanupPedestrianGraphics(~, src)
            % Safely deletes head graphic when main body graphic is deleted
            if isvalid(src) && isprop(src, 'UserData') && ~isempty(src.UserData) && isstruct(src.UserData)
                if isfield(src.UserData, 'HeadHandle') && ~isempty(src.UserData.HeadHandle) && isvalid(src.UserData.HeadHandle)
                    delete(src.UserData.HeadHandle);
                end
            end
        end

        function updatePedestrians(app)
            % Updates pedestrian positions along sidewalk corridors, enforcing:
            % 1. Sidewalk range boundaries and safe turnaround.
            % 2. Strict minimum pedestrian-to-pedestrian spacing (3.5 m).
            % 3. Strict vehicle safety buffer (>= 4.0 m from road lanes).
            % 4. Continuous movement without deadlocks or permanent stationary state.
            % 5. In-place graphic updates without re-instantiation.
            if isempty(app.ActivePedestrians)
                return;
            end

            cfg = app.IntersectionConfig.PedestrianConfig;
            minSpacing = cfg.MinSpacing; % 3.5 m
            pathNames = {'North', 'South', 'East', 'West'};

            for pNameIdx = 1:numel(pathNames)
                pathName = pathNames{pNameIdx};
                pathCfg = cfg.Paths.(pathName);
                isY = strcmp(pathCfg.Axis, 'Y');
                rMin = pathCfg.Range(1);
                rMax = pathCfg.Range(2);

                % Get pedestrian indices for this path
                idxs = find(strcmp({app.ActivePedestrians.Path}, pathName));
                numOnPath = numel(idxs);
                if numOnPath == 0
                    continue;
                end

                % Extract positions, directions (+1 or -1), and speeds
                pos = zeros(1, numOnPath);
                dirVal = zeros(1, numOnPath);
                spd = zeros(1, numOnPath);

                for k = 1:numOnPath
                    ped = app.ActivePedestrians(idxs(k));
                    if isY
                        pos(k) = ped.Y;
                        if strcmp(ped.Direction, 'North')
                            dirVal(k) = 1;
                        else
                            dirVal(k) = -1;
                        end
                    else
                        pos(k) = ped.X;
                        if strcmp(ped.Direction, 'East')
                            dirVal(k) = 1;
                        else
                            dirVal(k) = -1;
                        end
                    end
                    spd(k) = ped.Speed;
                end

                % 1. Boundary turnaround check
                for k = 1:numOnPath
                    if pos(k) >= rMax && dirVal(k) == 1
                        dirVal(k) = -1;
                    elseif pos(k) <= rMin && dirVal(k) == -1
                        dirVal(k) = 1;
                    end
                end

                desiredStep = spd;

                % 2. Dynamic interaction & spacing check
                for k = 1:numOnPath
                    % Find closest neighbor in front of pedestrian k
                    closestDist = Inf;
                    closestIdx = -1;
                    for m = 1:numOnPath
                        if k == m
                            continue;
                        end
                        if dirVal(k) == 1 && pos(m) > pos(k)
                            d = pos(m) - pos(k);
                            if d < closestDist
                                closestDist = d;
                                closestIdx = m;
                            end
                        elseif dirVal(k) == -1 && pos(m) < pos(k)
                            d = pos(k) - pos(m);
                            if d < closestDist
                                closestDist = d;
                                closestIdx = m;
                            end
                        end
                    end

                    if closestIdx > 0
                        gap = closestDist;
                        turnBuffer = minSpacing + spd(k) + spd(closestIdx);
                        if dirVal(k) ~= dirVal(closestIdx)
                            % Walking towards each other (head-on)
                            if gap <= turnBuffer
                                if pos(k) >= rMax - 1.0 || pos(closestIdx) >= rMax - 1.0
                                    % Near upper/right boundary: both turn towards lower/left (-1)
                                    dirVal(k) = -1;
                                    dirVal(closestIdx) = -1;
                                elseif pos(k) <= rMin + 1.0 || pos(closestIdx) <= rMin + 1.0
                                    % Near lower/left boundary: both turn towards upper/right (+1)
                                    dirVal(k) = 1;
                                    dirVal(closestIdx) = 1;
                                else
                                    % Open corridor: turnaround away from each other
                                    dirVal(k) = -dirVal(k);
                                    dirVal(closestIdx) = -dirVal(closestIdx);
                                end
                            end
                        else
                            % Walking in same direction: trailing pedestrian maintains minimum gap
                            desiredStep(k) = min(desiredStep(k), max(0, gap - minSpacing));
                        end
                    end
                end

                % 3. Apply position updates & in-place graphics update
                for k = 1:numOnPath
                    idx = idxs(k);
                    newCoord = min(rMax, max(rMin, pos(k) + dirVal(k) * desiredStep(k)));

                    if isY
                        app.ActivePedestrians(idx).Y = newCoord;
                        app.ActivePedestrians(idx).X = pathCfg.FixedCoord;
                        if dirVal(k) == 1
                            app.ActivePedestrians(idx).Direction = 'North';
                        else
                            app.ActivePedestrians(idx).Direction = 'South';
                        end
                    else
                        app.ActivePedestrians(idx).X = newCoord;
                        app.ActivePedestrians(idx).Y = pathCfg.FixedCoord;
                        if dirVal(k) == 1
                            app.ActivePedestrians(idx).Direction = 'East';
                        else
                            app.ActivePedestrians(idx).Direction = 'West';
                        end
                    end

                    % In-place graphics update
                    p = app.ActivePedestrians(idx);
                    if isvalid(p.GraphicHandle)
                        set(p.GraphicHandle, 'Position', [p.X - 1.1, p.Y - 1.1, 2.2, 2.2]);
                    end
                    if isfield(p, 'HeadHandle') && isvalid(p.HeadHandle)
                        set(p.HeadHandle, 'Position', [p.X - 0.6, p.Y - 0.6, 1.2, 1.2]);
                    end
                end
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and configure properties
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [60 40 1340 850];
            app.UIFigure.Name = 'VegMitra - AI Based Smart Traffic Light Management System';
            app.UIFigure.Color = [0.04 0.05 0.08]; % Deep obsidian space background

            % Create MainGridLayout (3 rows: Header, Main Area, KPIs)
            app.MainGridLayout = uigridlayout(app.UIFigure);
            app.MainGridLayout.RowHeight = {68, '1x', 112};
            app.MainGridLayout.ColumnWidth = {'1x'};
            app.MainGridLayout.Padding = [12 12 12 12];
            app.MainGridLayout.RowSpacing = 10;

            % -------------------------------------------------------------
            % 1. Header Panel
            % -------------------------------------------------------------
            app.HeaderPanel = uipanel(app.MainGridLayout);
            app.HeaderPanel.Layout.Row = 1;
            app.HeaderPanel.Layout.Column = 1;
            app.HeaderPanel.BackgroundColor = [0.06 0.08 0.14];
            app.HeaderPanel.BorderType = 'line';
            app.HeaderPanel.HighlightColor = [0.14 0.18 0.28];

            app.HeaderGrid = uigridlayout(app.HeaderPanel);
            app.HeaderGrid.RowHeight = {'1x'};
            app.HeaderGrid.ColumnWidth = {'1.5x', '1x'};
            app.HeaderGrid.Padding = [16 6 16 6];

            % Left: Brand Title and Subtitle
            leftHeaderGrid = uigridlayout(app.HeaderGrid, [2 1], 'Padding', [0 0 0 0], 'RowSpacing', 1);
            leftHeaderGrid.Layout.Row = 1;
            leftHeaderGrid.Layout.Column = 1;
            app.TitleLabel = uilabel(leftHeaderGrid);
            app.TitleLabel.Text = 'VegMitra';
            app.TitleLabel.FontSize = 24;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0.05 0.92 0.58]; % Vibrant Emerald Green

            app.SubtitleLabel = uilabel(leftHeaderGrid);
            app.SubtitleLabel.Text = 'AI-Based Smart Traffic Light Management System';
            app.SubtitleLabel.FontSize = 11;
            app.SubtitleLabel.FontColor = [0.65 0.74 0.85];

            % Right: Mission Slogan and Live Status Badge
            rightHeaderGrid = uigridlayout(app.HeaderGrid, [2 1], 'Padding', [0 0 0 0], 'RowSpacing', 2);
            rightHeaderGrid.Layout.Row = 1;
            rightHeaderGrid.Layout.Column = 2;
            uilabel(rightHeaderGrid, 'Text', 'Smarter Signals | Greener Cities | Better Tomorrows', ...
                'FontColor', [0.35 0.80 0.58], 'FontSize', 11, 'HorizontalAlignment', 'right');
            uilabel(rightHeaderGrid, 'Text', '[ LIVE ]  |  AI ADAPTIVE ENGINE', ...
                'FontColor', [0.10 0.96 0.45], 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

            % -------------------------------------------------------------
            % 2. Middle Area (Split into Left: Simulation, Right: Controls & Telemetry)
            % -------------------------------------------------------------
            app.MiddleGrid = uigridlayout(app.MainGridLayout);
            app.MiddleGrid.Layout.Row = 2;
            app.MiddleGrid.Layout.Column = 1;
            app.MiddleGrid.RowHeight = {'1x'};
            app.MiddleGrid.ColumnWidth = {'1.42x', '1x'};
            app.MiddleGrid.Padding = [0 0 0 0];
            app.MiddleGrid.ColumnSpacing = 10;

            % --- Left: Simulation Panel (Dominant Hero Element) ---
            app.SimulationPanel = uipanel(app.MiddleGrid);
            app.SimulationPanel.Layout.Row = 1;
            app.SimulationPanel.Layout.Column = 1;
            app.SimulationPanel.Title = 'Traffic Simulation';
            app.SimulationPanel.FontSize = 13;
            app.SimulationPanel.FontWeight = 'bold';
            app.SimulationPanel.ForegroundColor = [0.85 0.92 1.00];
            app.SimulationPanel.BackgroundColor = [0.06 0.08 0.14];
            app.SimulationPanel.BorderType = 'line';
            app.SimulationPanel.HighlightColor = [0.14 0.18 0.28];

            app.SimulationGrid = uigridlayout(app.SimulationPanel);
            app.SimulationGrid.RowHeight = {'1x', 22};
            app.SimulationGrid.ColumnWidth = {'1x'};
            app.SimulationGrid.Padding = [6 4 6 4];

            % Canvas axes for Phase 2 road intersection
            app.SimulationCanvas = uiaxes(app.SimulationGrid);
            app.SimulationCanvas.Layout.Row = 1;
            app.SimulationCanvas.Layout.Column = 1;

            app.SimSubLabel = uilabel(app.SimulationGrid);
            app.SimSubLabel.Layout.Row = 2;
            app.SimSubLabel.Layout.Column = 1;
            app.SimSubLabel.Text = '4-Road Intersection | Real-Time Vehicle Movement & Smart City Environment';
            app.SimSubLabel.HorizontalAlignment = 'center';
            app.SimSubLabel.FontColor = [0.55 0.62 0.74];
            app.SimSubLabel.FontSize = 11;

            % Initialize Intersection Config & Draw Intersection Graphics
            app.initializeIntersectionConfig();
            app.drawIntersection();

            % Initialize Phase 3 Simulation Engine
            app.initializeSimulation();

            % --- Right Column Grid (Status, Telemetry, Controls, Banner) ---
            app.RightPanel = uipanel(app.MiddleGrid);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.BackgroundColor = [0.04 0.05 0.08];
            app.RightPanel.BorderType = 'none';

            app.RightGrid = uigridlayout(app.RightPanel);
            app.RightGrid.RowHeight = {'1.55x', '1.45x', '1x', 36};
            app.RightGrid.ColumnWidth = {'1x'};
            app.RightGrid.Padding = [0 0 0 0];
            app.RightGrid.RowSpacing = 8;

            % A. Status Panel: Hero Signal Status & AI Decision Engine (Row 1 for top visual hierarchy)
            app.StatusPanel = uipanel(app.RightGrid);
            app.StatusPanel.Layout.Row = 1;
            app.StatusPanel.Layout.Column = 1;
            app.StatusPanel.Title = 'Current Signal Status';
            app.StatusPanel.FontSize = 13;
            app.StatusPanel.FontWeight = 'bold';
            app.StatusPanel.ForegroundColor = [0.85 0.92 1.00];
            app.StatusPanel.BackgroundColor = [0.06 0.08 0.14];
            app.StatusPanel.BorderType = 'line';
            app.StatusPanel.HighlightColor = [0.14 0.18 0.28];

            app.StatusGrid = uigridlayout(app.StatusPanel);
            app.StatusGrid.RowHeight = {56, 46, 20, 20, 20};
            app.StatusGrid.ColumnWidth = {'1.3x', '1x'};
            app.StatusGrid.Padding = [8 6 8 6];
            app.StatusGrid.RowSpacing = 4;

            % Row 1: Hero Signal split card
            heroGreenCard = uipanel(app.StatusGrid, 'BackgroundColor', [0.08 0.12 0.20], 'BorderType', 'line', 'HighlightColor', [0.16 0.24 0.38]);
            heroGreenCard.Layout.Row = 1;
            heroGreenCard.Layout.Column = 1;
            hgGrid = uigridlayout(heroGreenCard, [2 1], 'Padding', [8 4 8 4], 'RowSpacing', 1);
            hgGrid.RowHeight = {14, '1x'};
            app.CurrentGreenRoadLabel = uilabel(hgGrid, 'Text', 'Current Green Road:', 'FontColor', [0.62 0.70 0.82], 'FontSize', 10);
            app.CurrentGreenRoadValue = uilabel(hgGrid, 'Text', 'North + South', 'FontColor', [0.05 0.95 0.55], 'FontWeight', 'bold', 'FontSize', 15);

            heroTimerCard = uipanel(app.StatusGrid, 'BackgroundColor', [0.08 0.12 0.20], 'BorderType', 'line', 'HighlightColor', [0.16 0.24 0.38]);
            heroTimerCard.Layout.Row = 1;
            heroTimerCard.Layout.Column = 2;
            htGrid = uigridlayout(heroTimerCard, [2 1], 'Padding', [6 4 6 4], 'RowSpacing', 1);
            htGrid.RowHeight = {14, '1x'};
            app.CurrentGreenTimeLabel = uilabel(htGrid, 'Text', 'Time Remaining:', 'FontColor', [0.62 0.70 0.82], 'FontSize', 10, 'HorizontalAlignment', 'center');
            app.CurrentGreenTimeValue = uilabel(htGrid, 'Text', '10s', 'FontColor', [0.05 0.95 0.55], 'FontWeight', 'bold', 'FontSize', 22, 'HorizontalAlignment', 'center');

            % Row 2: AI Traffic Decision Hero Card (Spanning both columns)
            aiCard = uipanel(app.StatusGrid, 'BackgroundColor', [0.08 0.12 0.20], 'BorderType', 'line', 'HighlightColor', [0.18 0.28 0.44]);
            aiCard.Layout.Row = 2;
            aiCard.Layout.Column = [1 2];
            aiCardGrid = uigridlayout(aiCard, [2 1], 'Padding', [8 3 8 3], 'RowSpacing', 1);
            aiCardGrid.RowHeight = {14, '1x'};
            app.AIDecisionLabel = uilabel(aiCardGrid, 'Text', 'AI Decision:', 'FontColor', [0.45 0.78 0.98], 'FontSize', 10, 'FontWeight', 'bold');
            app.AIDecisionValue = uilabel(aiCardGrid, 'Text', 'Standby', 'FontColor', [0.25 0.88 0.58], 'FontWeight', 'bold', 'FontSize', 11);

            % Row 3: Traffic Density
            app.TrafficDensityLabel = uilabel(app.StatusGrid, 'Text', 'Traffic Density:', 'FontColor', [0.65 0.72 0.82], 'FontSize', 11);
            app.TrafficDensityLabel.Layout.Row = 3;
            app.TrafficDensityLabel.Layout.Column = 1;
            app.TrafficDensityValue = uilabel(app.StatusGrid, 'Text', '0%', 'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 11);
            app.TrafficDensityValue.Layout.Row = 3;
            app.TrafficDensityValue.Layout.Column = 2;

            % Row 4: Controller Mode
            app.ControllerModeLabel = uilabel(app.StatusGrid, 'Text', 'Controller Mode:', 'FontColor', [0.65 0.72 0.82], 'FontSize', 11);
            app.ControllerModeLabel.Layout.Row = 4;
            app.ControllerModeLabel.Layout.Column = 1;
            app.ControllerModeValue = uilabel(app.StatusGrid, 'Text', 'AI Adaptive', 'FontColor', [0.05 0.88 0.55], 'FontWeight', 'bold', 'FontSize', 11);
            app.ControllerModeValue.Layout.Row = 4;
            app.ControllerModeValue.Layout.Column = 2;

            % Row 5: System Status
            app.SystemStatusLabel = uilabel(app.StatusGrid, 'Text', 'System Status:', 'FontColor', [0.65 0.72 0.82], 'FontSize', 11);
            app.SystemStatusLabel.Layout.Row = 5;
            app.SystemStatusLabel.Layout.Column = 1;
            app.SystemStatusValue = uilabel(app.StatusGrid, 'Text', 'READY', 'FontColor', [0.25 0.65 0.95], 'FontWeight', 'bold', 'FontSize', 11);
            app.SystemStatusValue.Layout.Row = 5;
            app.SystemStatusValue.Layout.Column = 2;

            % B. Traffic Information Panel (4 Directional Cards in 2x2 Grid with Visual Level Meters)
            app.InfoPanel = uipanel(app.RightGrid);
            app.InfoPanel.Layout.Row = 2;
            app.InfoPanel.Layout.Column = 1;
            app.InfoPanel.Title = 'Traffic Information';
            app.InfoPanel.FontSize = 13;
            app.InfoPanel.FontWeight = 'bold';
            app.InfoPanel.ForegroundColor = [0.85 0.92 1.00];
            app.InfoPanel.BackgroundColor = [0.06 0.08 0.14];
            app.InfoPanel.BorderType = 'line';
            app.InfoPanel.HighlightColor = [0.14 0.18 0.28];

            app.InfoGrid = uigridlayout(app.InfoPanel);
            app.InfoGrid.RowHeight = {'1x', '1x'};
            app.InfoGrid.ColumnWidth = {'1x', '1x'};
            app.InfoGrid.Padding = [8 6 8 6];
            app.InfoGrid.RowSpacing = 6;
            app.InfoGrid.ColumnSpacing = 6;

            % Card 1: North (Row 1, Column 1)
            cardNorth = uipanel(app.InfoGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            cardNorthGrid = uigridlayout(cardNorth, [4 1], 'Padding', [6 3 6 3], 'RowSpacing', 1);
            cardNorthGrid.RowHeight = {16, '1x', 16, 5};
            app.NorthVehiclesLabel = uilabel(cardNorthGrid, 'Text', '▲ North', 'FontColor', [0.30 0.80 1.00], 'FontSize', 11, 'FontWeight', 'bold');
            app.NorthVehiclesValue = uilabel(cardNorthGrid, 'Text', '0', 'FontColor', [1 1 1], 'FontSize', 22, 'FontWeight', 'bold');
            app.NorthDensityValue = uilabel(cardNorthGrid, 'Text', '0% (LOW)', 'FontColor', [0.40 0.88 0.55], 'FontSize', 11, 'FontWeight', 'bold');
            meterNGrid = uigridlayout(cardNorthGrid, [1 4], 'Padding', [0 0 0 0], 'ColumnSpacing', 3);
            meterNGrid.RowHeight = {5};
            bN1 = uipanel(meterNGrid, 'BackgroundColor', [0.35 0.82 0.45], 'BorderType', 'none');
            bN2 = uipanel(meterNGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bN3 = uipanel(meterNGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bN4 = uipanel(meterNGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            app.DensityMeters.North = [bN1, bN2, bN3, bN4];

            % Card 2: South (Row 1, Column 2)
            cardSouth = uipanel(app.InfoGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            cardSouthGrid = uigridlayout(cardSouth, [4 1], 'Padding', [6 3 6 3], 'RowSpacing', 1);
            cardSouthGrid.RowHeight = {16, '1x', 16, 5};
            app.SouthVehiclesLabel = uilabel(cardSouthGrid, 'Text', '▼ South', 'FontColor', [0.98 0.78 0.20], 'FontSize', 11, 'FontWeight', 'bold');
            app.SouthVehiclesValue = uilabel(cardSouthGrid, 'Text', '0', 'FontColor', [1 1 1], 'FontSize', 22, 'FontWeight', 'bold');
            app.SouthDensityValue = uilabel(cardSouthGrid, 'Text', '0% (LOW)', 'FontColor', [0.40 0.88 0.55], 'FontSize', 11, 'FontWeight', 'bold');
            meterSGrid = uigridlayout(cardSouthGrid, [1 4], 'Padding', [0 0 0 0], 'ColumnSpacing', 3);
            meterSGrid.RowHeight = {5};
            bS1 = uipanel(meterSGrid, 'BackgroundColor', [0.35 0.82 0.45], 'BorderType', 'none');
            bS2 = uipanel(meterSGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bS3 = uipanel(meterSGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bS4 = uipanel(meterSGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            app.DensityMeters.South = [bS1, bS2, bS3, bS4];

            % Card 3: East (Row 2, Column 1)
            cardEast = uipanel(app.InfoGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            cardEastGrid = uigridlayout(cardEast, [4 1], 'Padding', [6 3 6 3], 'RowSpacing', 1);
            cardEastGrid.RowHeight = {16, '1x', 16, 5};
            app.EastVehiclesLabel = uilabel(cardEastGrid, 'Text', '► East', 'FontColor', [0.96 0.38 0.42], 'FontSize', 11, 'FontWeight', 'bold');
            app.EastVehiclesValue = uilabel(cardEastGrid, 'Text', '0', 'FontColor', [1 1 1], 'FontSize', 22, 'FontWeight', 'bold');
            app.EastDensityValue = uilabel(cardEastGrid, 'Text', '0% (LOW)', 'FontColor', [0.40 0.88 0.55], 'FontSize', 11, 'FontWeight', 'bold');
            meterEGrid = uigridlayout(cardEastGrid, [1 4], 'Padding', [0 0 0 0], 'ColumnSpacing', 3);
            meterEGrid.RowHeight = {5};
            bE1 = uipanel(meterEGrid, 'BackgroundColor', [0.35 0.82 0.45], 'BorderType', 'none');
            bE1.Tag = 'bE1';
            bE2 = uipanel(meterEGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bE3 = uipanel(meterEGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bE4 = uipanel(meterEGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            app.DensityMeters.East = [bE1, bE2, bE3, bE4];

            % Card 4: West (Row 2, Column 2)
            cardWest = uipanel(app.InfoGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            cardWestGrid = uigridlayout(cardWest, [4 1], 'Padding', [6 3 6 3], 'RowSpacing', 1);
            cardWestGrid.RowHeight = {16, '1x', 16, 5};
            app.WestVehiclesLabel = uilabel(cardWestGrid, 'Text', '◄ West', 'FontColor', [0.72 0.50 0.98], 'FontSize', 11, 'FontWeight', 'bold');
            app.WestVehiclesValue = uilabel(cardWestGrid, 'Text', '0', 'FontColor', [1 1 1], 'FontSize', 22, 'FontWeight', 'bold');
            app.WestDensityValue = uilabel(cardWestGrid, 'Text', '0% (LOW)', 'FontColor', [0.40 0.88 0.55], 'FontSize', 11, 'FontWeight', 'bold');
            meterWGrid = uigridlayout(cardWestGrid, [1 4], 'Padding', [0 0 0 0], 'ColumnSpacing', 3);
            meterWGrid.RowHeight = {5};
            bW1 = uipanel(meterWGrid, 'BackgroundColor', [0.35 0.82 0.45], 'BorderType', 'none');
            bW2 = uipanel(meterWGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bW3 = uipanel(meterWGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            bW4 = uipanel(meterWGrid, 'BackgroundColor', [0.12 0.15 0.22], 'BorderType', 'none');
            app.DensityMeters.West = [bW1, bW2, bW3, bW4];

            % C. Control Panel
            app.ControlPanel = uipanel(app.RightGrid);
            app.ControlPanel.Layout.Row = 3;
            app.ControlPanel.Layout.Column = 1;
            app.ControlPanel.Title = 'Control Section';
            app.ControlPanel.FontSize = 13;
            app.ControlPanel.FontWeight = 'bold';
            app.ControlPanel.ForegroundColor = [0.85 0.92 1.00];
            app.ControlPanel.BackgroundColor = [0.06 0.08 0.14];
            app.ControlPanel.BorderType = 'line';
            app.ControlPanel.HighlightColor = [0.14 0.18 0.28];

            app.ControlGrid = uigridlayout(app.ControlPanel);
            app.ControlGrid.RowHeight = {'1x', '1x'};
            app.ControlGrid.ColumnWidth = {'1x', '1x'};
            app.ControlGrid.Padding = [8 6 8 6];
            app.ControlGrid.RowSpacing = 6;
            app.ControlGrid.ColumnSpacing = 8;

            app.StartButton = uibutton(app.ControlGrid, 'push');
            app.StartButton.Layout.Row = 1;
            app.StartButton.Layout.Column = 1;
            app.StartButton.Text = 'Start Simulation';
            app.StartButton.FontWeight = 'bold';
            app.StartButton.FontSize = 11;
            app.StartButton.BackgroundColor = [0.06 0.65 0.38]; % Primary Emerald
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.ButtonPushedFcn = @(src, event) app.StartButtonPushed(event);

            app.StopButton = uibutton(app.ControlGrid, 'push');
            app.StopButton.Layout.Row = 1;
            app.StopButton.Layout.Column = 2;
            app.StopButton.Text = 'Stop Simulation';
            app.StopButton.FontWeight = 'bold';
            app.StopButton.FontSize = 11;
            app.StopButton.BackgroundColor = [0.78 0.18 0.22]; % Danger Crimson
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.ButtonPushedFcn = @(src, event) app.StopButtonPushed(event);

            app.ResetButton = uibutton(app.ControlGrid, 'push');
            app.ResetButton.Layout.Row = 2;
            app.ResetButton.Layout.Column = 1;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.FontWeight = 'bold';
            app.ResetButton.FontSize = 11;
            app.ResetButton.BackgroundColor = [0.18 0.42 0.78]; % Slate Steel Blue
            app.ResetButton.FontColor = [1 1 1];
            app.ResetButton.ButtonPushedFcn = @(src, event) app.ResetButtonPushed(event);

            app.EmergencyButton = uibutton(app.ControlGrid, 'push');
            app.EmergencyButton.Layout.Row = 2;
            app.EmergencyButton.Layout.Column = 2;
            app.EmergencyButton.Text = 'Emergency Mode';
            app.EmergencyButton.FontWeight = 'bold';
            app.EmergencyButton.FontSize = 11;
            app.EmergencyButton.BackgroundColor = [0.82 0.48 0.10]; % High-Alert Amber
            app.EmergencyButton.FontColor = [1 1 1];
            app.EmergencyButton.ButtonPushedFcn = @(src, event) app.EmergencyButtonPushed(event);

            % D. Smart City Mission Quote Card
            quotePanel = uipanel(app.RightGrid, 'BackgroundColor', [0.06 0.08 0.14], 'BorderType', 'line', 'HighlightColor', [0.14 0.18 0.28]);
            quotePanel.Layout.Row = 4;
            quotePanel.Layout.Column = 1;
            qGrid = uigridlayout(quotePanel, [1 1], 'Padding', [8 2 8 2]);
            uilabel(qGrid, 'Text', '"Autonomous AI Signals for Greener, Flowing Cities"', ...
                'FontColor', [0.30 0.88 0.58], 'FontAngle', 'italic', 'FontSize', 10.5, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

            % -------------------------------------------------------------
            % 3. Bottom Row: Key Performance Indicators (KPIs)
            % -------------------------------------------------------------
            app.KPIPanel = uipanel(app.MainGridLayout);
            app.KPIPanel.Layout.Row = 3;
            app.KPIPanel.Layout.Column = 1;
            app.KPIPanel.Title = 'Key Performance Indicators (KPIs)';
            app.KPIPanel.FontSize = 13;
            app.KPIPanel.FontWeight = 'bold';
            app.KPIPanel.ForegroundColor = [0.85 0.92 1.00];
            app.KPIPanel.BackgroundColor = [0.06 0.08 0.14];
            app.KPIPanel.BorderType = 'line';
            app.KPIPanel.HighlightColor = [0.14 0.18 0.28];

            app.KPIGrid = uigridlayout(app.KPIPanel);
            app.KPIGrid.RowHeight = {'1x'};
            app.KPIGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.KPIGrid.Padding = [10 8 10 8];
            app.KPIGrid.ColumnSpacing = 10;

            % Card 1: Average Waiting Time
            app.AvgWaitCard = uipanel(app.KPIGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            card1Grid = uigridlayout(app.AvgWaitCard, [2 1], 'Padding', [6 6 6 6], 'RowSpacing', 2);
            app.AvgWaitTitle = uilabel(card1Grid, 'Text', '[ TIME ]  Avg Waiting Time', 'FontColor', [0.65 0.74 0.85], 'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
            app.AvgWaitValue = uilabel(card1Grid, 'Text', '0.0 s', 'FontColor', [0.15 0.80 1.00], 'HorizontalAlignment', 'center', 'FontSize', 22, 'FontWeight', 'bold');

            % Card 2: Vehicles Processed
            app.VehiclesProcessedCard = uipanel(app.KPIGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            card2Grid = uigridlayout(app.VehiclesProcessedCard, [2 1], 'Padding', [6 6 6 6], 'RowSpacing', 2);
            app.VehiclesProcessedTitle = uilabel(card2Grid, 'Text', '[ FLOW ]  Vehicles Processed', 'FontColor', [0.65 0.74 0.85], 'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
            app.VehiclesProcessedValue = uilabel(card2Grid, 'Text', '0', 'FontColor', [0.10 0.92 0.52], 'HorizontalAlignment', 'center', 'FontSize', 22, 'FontWeight', 'bold');

            % Card 3: Congestion Level
            app.CongestionCard = uipanel(app.KPIGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            card3Grid = uigridlayout(app.CongestionCard, [2 1], 'Padding', [6 6 6 6], 'RowSpacing', 2);
            app.CongestionTitle = uilabel(card3Grid, 'Text', '[ LOAD ]  Congestion Level', 'FontColor', [0.65 0.74 0.85], 'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
            app.CongestionValue = uilabel(card3Grid, 'Text', 'Low (0%)', 'FontColor', [0.96 0.78 0.18], 'HorizontalAlignment', 'center', 'FontSize', 22, 'FontWeight', 'bold');

            % Card 4: Fuel/Time Saving
            app.FuelSavedCard = uipanel(app.KPIGrid, 'BackgroundColor', [0.08 0.11 0.18], 'BorderType', 'line', 'HighlightColor', [0.16 0.22 0.35]);
            card4Grid = uigridlayout(app.FuelSavedCard, [2 1], 'Padding', [6 6 6 6], 'RowSpacing', 2);
            app.FuelSavedTitle = uilabel(card4Grid, 'Text', '[ ECO ]  Fuel/Time Saving', 'FontColor', [0.65 0.74 0.85], 'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
            app.FuelSavedValue = uilabel(card4Grid, 'Text', '0.0 L', 'FontColor', [0.72 0.52 0.98], 'HorizontalAlignment', 'center', 'FontSize', 22, 'FontWeight', 'bold');

            % Initialize Phase 4 Traffic Signals & Controller
            app.initializeTrafficSignals();

            % Initialize Phase 6 Traffic Density & Monitoring
            app.initializeTrafficDensity();

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = VegMitraApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        function success = syncYOLOState(app, jsonFilePath)
            % Syncs MATLAB GUI display with live YOLO traffic state exported from Python
            if nargin < 2 || isempty(jsonFilePath)
                mPath = fileparts(mfilename('fullpath'));
                jsonFilePath = fullfile(mPath, 'traffic_state.json');
                if ~exist(jsonFilePath, 'file')
                    jsonFilePath = fullfile(fileparts(mPath), 'output', 'traffic_state.json');
                end
            end

            success = false;
            if ~exist(jsonFilePath, 'file')
                return;
            end

            try
                fid = fopen(jsonFilePath, 'r');
                if fid == -1, return; end
                raw = fread(fid, '*char')';
                fclose(fid);
                data = jsondecode(raw);

                % Update vehicle counts & density UI values
                if isfield(data, 'counts')
                    app.NorthVehiclesValue.Text = num2str(data.counts.North);
                    app.SouthVehiclesValue.Text = num2str(data.counts.South);
                    app.EastVehiclesValue.Text = num2str(data.counts.East);
                    app.WestVehiclesValue.Text = num2str(data.counts.West);
                end

                if isfield(data, 'density')
                    app.NorthDensityValue.Text = sprintf('%.1f%%', data.density.North);
                    app.SouthDensityValue.Text = sprintf('%.1f%%', data.density.South);
                    app.EastDensityValue.Text = sprintf('%.1f%%', data.density.East);
                    app.WestDensityValue.Text = sprintf('%.1f%%', data.density.West);
                end

                % Update selected single green road & signal lamps
                if isfield(data, 'selected_green_road') && ~isempty(data.selected_green_road)
                    selectedRoad = data.selected_green_road;
                    app.CurrentGreenRoadValue.Text = sprintf('%s GREEN', upper(selectedRoad));

                    % Set true single-road signal states
                    app.TrafficSignalStates = struct(...
                        'North', 'RED', ...
                        'South', 'RED', ...
                        'East',  'RED', ...
                        'West',  'RED');
                    
                    % Capitalize first letter to match struct field
                    roadCap = [upper(selectedRoad(1)) lower(selectedRoad(2:end))];
                    if isfield(app.TrafficSignalStates, roadCap)
                        app.TrafficSignalStates.(roadCap) = 'GREEN';
                    end

                    % Refresh visual lamps on canvas
                    if ismethod(app, 'updateSignalVisuals')
                        app.updateSignalVisuals();
                    end
                end

                if isfield(data, 'emergency_active') && data.emergency_active
                    app.EmergencyActive = true;
                    if isfield(data, 'emergency_road') && ~isempty(data.emergency_road)
                        app.EmergencyDirection = data.emergency_road;
                    end
                    if isfield(data, 'emergency_class') && ~isempty(data.emergency_class)
                        app.EmergencyType = data.emergency_class;
                    end
                    app.updateEmergencyUI();
                else
                    app.EmergencyActive = false;
                end

                success = true;
            catch ME
                success = false;
            end
        end



        % Code that executes before app deletion
        function delete(app)

            % Safely stop and delete simulation timer
            if ~isempty(app.SimulationTimer) && isvalid(app.SimulationTimer)
                stop(app.SimulationTimer);
                delete(app.SimulationTimer);
            end

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
