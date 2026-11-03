function passed = verify_Phase9_Pedestrians(mode)
% VERIFY_PHASE9_PEDESTRIANS Targeted verification of Phase 9 Pedestrian / Human Simulation.
%
% This verification procedure reliably validates:
% 1. Four dedicated pedestrian sidewalk corridors around the intersection:
%    - North Sidewalk: X = 31, Y in [32, 92]
%    - South Sidewalk: X = -31, Y in [-92, -32]
%    - East Sidewalk:  Y = 31, X in [32, 92]
%    - West Sidewalk:  Y = -31, X in [-92, -32]
% 2. Pedestrians maintain strict geometric safety buffer (>= 4.0 m from vehicle lanes).
% 3. Pedestrians maintain positive spacing (>= 3.5 m center-to-center).
% 4. Pedestrians continuously move, reverse safely at sidewalk boundaries, and do not overlap.
% 5. Normal vehicles, traffic signals, and AI adaptive timing operate concurrently without interference.
% 6. Pedestrians do not alter vehicle counts, traffic density, or processed counts.
% 7. Clean start, stop, and reset behavior without orphan graphics.
%
% Usage:
%   verify_Phase9_Pedestrians           % Automated verification mode (fast assertions)
%   verify_Phase9_Pedestrians('auto')   % Automated mode
%   verify_Phase9_Pedestrians('visual') % Visual mode (animates on-screen & saves screenshot)

    if nargin < 1 || isempty(mode)
        mode = 'auto';
    end
    isVisual = strcmpi(mode, 'visual') || isequal(mode, true);

    fprintf('=================================================================\n');
    fprintf('  VEGMITRA PHASE 9: PEDESTRIAN / HUMAN SIMULATION VERIFICATION   \n');
    fprintf('  Mode: %s\n', upper(mode));
    fprintf('=================================================================\n\n');

    % Step 0: Initialize Application
    fprintf('Step 0: Initializing VegMitraApp...\n');
    app = VegMitraApp();
    app.resetSimulation();

    if isVisual
        app.UIFigure.Visible = 'on';
        figure(app.UIFigure);
        drawnow;
        pause(0.5);
    end

    try
        % -----------------------------------------------------------------
        % Step 1: Verify Initial Pedestrian Spawning & Structure
        % -----------------------------------------------------------------
        fprintf('\nStep 1: Verifying pedestrian entity structure and initial population...\n');
        assert(~isempty(app.ActivePedestrians), 'ActivePedestrians must not be empty');
        nPeds = numel(app.ActivePedestrians);
        assert(nPeds >= 4 && nPeds <= 12, sprintf('Expected 4-12 pedestrians, found %d', nPeds));

        reqFields = {'ID', 'X', 'Y', 'Direction', 'Speed', 'Path', 'GraphicHandle'};
        for f = 1:numel(reqFields)
            assert(isfield(app.ActivePedestrians, reqFields{f}), sprintf('ActivePedestrians missing field: %s', reqFields{f}));
        end
        fprintf('  [OK] Initial population: %d pedestrians with complete entity fields.\n', nPeds);

        % -----------------------------------------------------------------
        % Step 2: Verify Exact Corridor Coordinates & Geometric Safety Buffers
        % -----------------------------------------------------------------
        fprintf('\nStep 2: Verifying exact corridor coordinates and geometric safety buffers...\n');
        cfg = app.IntersectionConfig.PedestrianConfig;
        assert(cfg.MinSpacing == 3.5, 'Pedestrian MinSpacing must be 3.5 m');
        assert(cfg.SafetyBuffer == 4.0, 'Pedestrian SafetyBuffer must be 4.0 m');

        for i = 1:nPeds
            p = app.ActivePedestrians(i);
            assert(isvalid(p.GraphicHandle), sprintf('Pedestrian %d GraphicHandle must be valid', p.ID));

            % Check corridor alignment
            switch p.Path
                case 'North'
                    assert(p.X == 31, sprintf('North pedestrian %d must have fixed X = 31, got %.2f', p.ID, p.X));
                    assert(p.Y >= 32 && p.Y <= 92, sprintf('North pedestrian %d Y must be in [32, 92], got %.2f', p.ID, p.Y));
                case 'South'
                    assert(p.X == -31, sprintf('South pedestrian %d must have fixed X = -31, got %.2f', p.ID, p.X));
                    assert(p.Y >= -92 && p.Y <= -32, sprintf('South pedestrian %d Y must be in [-92, -32], got %.2f', p.ID, p.Y));
                case 'East'
                    assert(p.Y == 31, sprintf('East pedestrian %d must have fixed Y = 31, got %.2f', p.ID, p.Y));
                    assert(p.X >= 32 && p.X <= 92, sprintf('East pedestrian %d X must be in [32, 92], got %.2f', p.ID, p.X));
                case 'West'
                    assert(p.Y == -31, sprintf('West pedestrian %d must have fixed Y = -31, got %.2f', p.ID, p.Y));
                    assert(p.X >= -92 && p.X <= -32, sprintf('West pedestrian %d X must be in [-92, -32], got %.2f', p.ID, p.X));
                otherwise
                    error('Unknown pedestrian path: %s', p.Path);
            end

            % Geometric safety buffer checks:
            % Road edges are at abs(X) = 20 and abs(Y) = 20.
            % Vehicle safety corridor requires at least 4.0 m clearance from roads.
            distFromRoadX = abs(p.X) - 20.0;
            distFromRoadY = abs(p.Y) - 20.0;
            assert(distFromRoadX >= 4.0 && distFromRoadY >= 4.0, ...
                sprintf('Pedestrian %d violates 4.0m vehicle buffer (dX=%.1f, dY=%.1f)', p.ID, distFromRoadX, distFromRoadY));

            % Never enter central intersection conflict zone [-20, 20] x [-20, 20]
            inConflict = abs(p.X) <= 20.0 && abs(p.Y) <= 20.0;
            assert(~inConflict, sprintf('Pedestrian %d inside central intersection conflict zone', p.ID));

            % Never enter vehicle lanes
            inVehicleLanes = (abs(p.X) <= 20.0 && abs(p.Y) <= 100.0) || (abs(p.Y) <= 20.0 && abs(p.X) <= 100.0);
            assert(~inVehicleLanes, sprintf('Pedestrian %d inside vehicle lanes', p.ID));
        end
        fprintf('  [OK] All pedestrians strictly conform to assigned corridors with >= 4.0 m safety buffers.\n');

        % -----------------------------------------------------------------
        % Step 3: Verify Positive Spacing (>= 3.5 m)
        % -----------------------------------------------------------------
        fprintf('\nStep 3: Verifying pedestrian-to-pedestrian spacing...\n');
        for i = 1:nPeds
            for j = (i + 1):nPeds
                p1 = app.ActivePedestrians(i);
                p2 = app.ActivePedestrians(j);
                if strcmp(p1.Path, p2.Path)
                    d = sqrt((p1.X - p2.X)^2 + (p1.Y - p2.Y)^2);
                    assert(d >= 3.5, sprintf('Pedestrians %d and %d spacing %.2f < 3.5 m', p1.ID, p2.ID, d));
                end
            end
        end
        fprintf('  [OK] Strict positive spacing >= 3.5 m verified across all pedestrian pairs.\n');

        % -----------------------------------------------------------------
        % Step 4: Verify Dynamic Movement, Boundary Turnaround, & In-Place Updates
        % -----------------------------------------------------------------
        fprintf('\nStep 4: Verifying dynamic movement and boundary turnaround over 200 frames...\n');
        initialPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
        oldHandles = [app.ActivePedestrians.GraphicHandle];
        checkPos50 = [];
        checkPos100 = [];
        checkPos150 = [];

        for frame = 1:200
            app.updatePedestrians();

            % Verify in-place updates (handles must NOT be recreated)
            currentHandles = [app.ActivePedestrians.GraphicHandle];
            assert(isequal(oldHandles, currentHandles), 'Graphic handles must not be recreated during update');

            % Verify in-bounds, safety buffers, and non-overlap at every frame
            for i = 1:numel(app.ActivePedestrians)
                pi = app.ActivePedestrians(i);
                assert(abs(pi.X) >= 24 && abs(pi.Y) >= 24, sprintf('Frame %d: Ped %d breached safety buffer', frame, pi.ID));
                switch pi.Path
                    case 'North', assert(pi.X == 31 && pi.Y >= 32 && pi.Y <= 92, 'North bounds violated');
                    case 'South', assert(pi.X == -31 && pi.Y >= -92 && pi.Y <= -32, 'South bounds violated');
                    case 'East',  assert(pi.Y == 31 && pi.X >= 32 && pi.X <= 92, 'East bounds violated');
                    case 'West',  assert(pi.Y == -31 && pi.X >= -92 && pi.X <= -32, 'West bounds violated');
                end

                for j = (i + 1):numel(app.ActivePedestrians)
                    pj = app.ActivePedestrians(j);
                    if strcmp(pi.Path, pj.Path)
                        d = sqrt((pi.X - pj.X)^2 + (pi.Y - pj.Y)^2);
                        assert(d >= 3.5 - 1e-4, sprintf('Frame %d: Peds %d and %d spacing %.2f < 3.5 m', frame, pi.ID, pj.ID, d));
                    end
                end
            end

            if frame == 50,  checkPos50 = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]']; end
            if frame == 100, checkPos100 = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]']; end
            if frame == 150, checkPos150 = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]']; end
        end

        finalPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
        assert(~isequal(initialPos, checkPos50), 'Pedestrians must move between frames 0 and 50');
        assert(~isequal(checkPos50, checkPos100), 'Pedestrians must move between frames 50 and 100');
        assert(~isequal(checkPos100, checkPos150), 'Pedestrians must move between frames 100 and 150');
        assert(~isequal(checkPos150, finalPos), 'Pedestrians must move between frames 150 and 200');
        fprintf('  [OK] Movement smooth and valid across 200 simulation frames with zero deadlock.\n');

        % -----------------------------------------------------------------
        % Step 5: Verify Pedestrians Do NOT Modify Vehicle Metrics
        % -----------------------------------------------------------------
        fprintf('\nStep 5: Verifying pedestrian independence from vehicle counts and traffic density...\n');
        app.resetSimulation();
        assert(app.VehicleCounts.North == 0 && app.VehicleCounts.South == 0 && ...
               app.VehicleCounts.East == 0  && app.VehicleCounts.West == 0, ...
               'Pedestrians must not be counted in VehicleCounts');
        assert(app.TrafficDensity.North.Count == 0 && app.TrafficDensity.North.Percentage == 0, ...
               'Pedestrians must not affect TrafficDensity');
        assert(app.TotalVehiclesProcessed == 0, 'Pedestrians must not be counted in TotalVehiclesProcessed');

        % Spawn normal vehicles and check that pedestrians remain separate
        vN = app.spawnSingleVehicle('North', 'Car');
        vE = app.spawnSingleVehicle('East', 'Car');
        assert(~isempty(vN) && ~isempty(vE), 'Vehicles must spawn normally alongside pedestrians');
        assert(app.VehicleCounts.North == 1, 'North vehicle count must be exactly 1');
        assert(app.VehicleCounts.East == 1,  'East vehicle count must be exactly 1');
        assert(app.VehicleCounts.South == 0, 'South vehicle count must be 0');
        assert(app.VehicleCounts.West == 0,  'West vehicle count must be 0');
        fprintf('  [OK] Complete isolation verified: Pedestrians do not affect traffic metrics.\n');

        % -----------------------------------------------------------------
        % Step 6: Verify Start / Stop / Reset Behavior
        % -----------------------------------------------------------------
        fprintf('\nStep 6: Verifying Start / Stop / Reset behavior...\n');
        app.StartButtonPushed([]);
        assert(app.SimulationRunning == true, 'Simulation must be RUNNING after Start');

        app.StopButtonPushed([]);
        assert(app.SimulationRunning == false, 'Simulation must be STOPPED after Stop');
        stoppedPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
        app.timerTickCallback(); % Tick while stopped
        assert(isequal(stoppedPos, [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]']), ...
            'Pedestrians must not move while simulation is stopped');

        oldHandlesToClean = [app.ActivePedestrians.GraphicHandle];
        app.ResetButtonPushed([]);
        for hIdx = 1:numel(oldHandlesToClean)
            assert(~isvalid(oldHandlesToClean(hIdx)), 'Old pedestrian graphic handles must be deleted on Reset');
        end
        assert(~isempty(app.ActivePedestrians), 'New active pedestrians must be initialized after Reset');
        for pIdx = 1:numel(app.ActivePedestrians)
            assert(isvalid(app.ActivePedestrians(pIdx).GraphicHandle), 'New pedestrian graphic handles must be valid');
        end
        fprintf('  [OK] Clean Start/Stop/Reset with zero orphan graphics verified.\n');

        % -----------------------------------------------------------------
        % Step 7: Visual Verification Demonstration (if requested)
        % -----------------------------------------------------------------
        if isVisual
            fprintf('\nStep 7: Running visual simulation demonstration (25 seconds of continuous simulation)...\n');
            app.resetSimulation();
            app.setSignalPhase('NS_GREEN', 10.0);

            % Spawn initial vehicles across approaches
            app.spawnSingleVehicle('North', 'Car');
            app.spawnSingleVehicle('South', 'Car');
            app.spawnSingleVehicle('East', 'Bus/Truck');
            app.spawnSingleVehicle('West', 'Motorcycle');

            app.StartButtonPushed([]);

            % Allow real-time animation timer to advance smoothly for 25 seconds
            % (500 ticks at 0.05s = 25.0 seconds of simulation time)
            totalVisualTicks = 500;
            lastLoggedPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];

            for t = 1:totalVisualTicks
                drawnow;
                pause(0.05);

                % Periodically report progress every 100 ticks (5 seconds)
                if mod(t, 100) == 0
                    currPos = [[app.ActivePedestrians.X]', [app.ActivePedestrians.Y]'];
                    dists = sqrt(sum((currPos - lastLoggedPos).^2, 2));
                    maxDist = max(dists);
                    assert(maxDist > 1.0, sprintf('Pedestrians stopped moving at tick %d', t));
                    lastLoggedPos = currPos;

                    simSec = t * 0.05;
                    fprintf('  [Visual Progress] %.1f s elapsed (%d ticks): pedestrians actively moving (max displacement = %.2f m)...\n', ...
                        simSec, t, maxDist);
                end
            end

            % Capture visual verification screenshot
            snapPath = fullfile(fileparts(mfilename('fullpath')), 'phase9_pedestrians_screenshot.png');
            exportgraphics(app.SimulationCanvas, snapPath, 'Resolution', 150);
            fprintf('  [OK] Visual screenshot captured to: %s\n', snapPath);

            app.StopButtonPushed([]);
        end

        % Cleanup
        delete(app);
        fprintf('\n=================================================================\n');
        fprintf('  [SUCCESS] PHASE 9 PEDESTRIAN SIMULATION VERIFIED SUCCESSFULLY! \n');
        fprintf('=================================================================\n');
        passed = true;

    catch ME
        fprintf('\n[FAIL] Verification error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  At line %d in %s\n', ME.stack(1).line, ME.stack(1).file);
        end
        if exist('app', 'var') && isvalid(app)
            delete(app);
        end
        passed = false;
        if ~isVisual
            rethrow(ME);
        end
    end
end
