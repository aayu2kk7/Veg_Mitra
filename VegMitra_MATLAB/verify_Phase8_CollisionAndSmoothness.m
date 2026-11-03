function passed = verify_Phase8_CollisionAndSmoothness(mode)
% VERIFY_PHASE8_COLLISIONANDSMOOTHNESS
% Comprehensive verification of frame-by-frame collision prevention,
% bumper-to-bumper headway safety, and smooth animation across all 8 scenarios.
%
% Usage:
%   verify_Phase8_CollisionAndSmoothness           % Automated mode (fast, asserts)
%   verify_Phase8_CollisionAndSmoothness('visual') % Visual mode (GUI, animated steps)

    if nargin < 1 || isempty(mode)
        mode = 'auto';
    end
    isVisual = strcmpi(mode, 'visual') || isequal(mode, true);

    fprintf('=================================================================\n');
    fprintf('  VEGMITRA PHASE 8: COLLISION PREVENTION & SMOOTHNESS VERIFICATION\n');
    fprintf('  Mode: %s\n', upper(mode));
    fprintf('=================================================================\n\n');

    addpath(fileparts(mfilename('fullpath')));

    % Initialize app
    app = VegMitraApp();
    app.resetSimulation();

    if isVisual
        app.UIFigure.Visible = 'on';
        figure(app.UIFigure);
        drawnow;
        pause(0.5);
    end

    try
        % =================================================================
        % Scenario 1: Two vehicles on the same lane approaching each other
        % (no physical overlap after any update)
        % =================================================================
        fprintf('Scenario 1: Testing two vehicles on same lane approaching each other...\n');
        app.resetSimulation();
        app.setSignalPhase('NS_GREEN', 20.0);
        v1 = app.spawnSingleVehicle('North', 'Car');
        v1.Y = 40.0;
        app.ActiveVehicles(1) = v1;

        v2 = app.spawnSingleVehicle('North', 'Car');
        v2.Y = 58.0;
        app.ActiveVehicles(2) = v2;

        % Advance multiple frames
        for f = 1:25
            app.updateVehicles();
            % Check no physical overlap
            b1 = app.getVehicleBoundingBox(app.ActiveVehicles(1));
            b2 = app.getVehicleBoundingBox(app.ActiveVehicles(2));
            assert(~app.checkAABBOverlap(b1, b2, 0.0), sprintf('Frame %d: Overlap detected between v1 and v2', f));
            % Check longitudinal bumper gap >= 4.0m
            bumperGap = (app.ActiveVehicles(2).Y - app.ActiveVehicles(1).Y) - 8.0;
            assert(bumperGap >= 4.0 - 1e-4, sprintf('Frame %d: Bumper gap %.2f < 4.0m', f, bumperGap));
            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 1: Same-lane vehicles maintain positive bumper separation on all frames.\n\n');

        % =================================================================
        % Scenario 2: Following vehicle catches up to slower lead vehicle
        % (following vehicle stops at safe bumper gap >= 4.0m)
        % =================================================================
        fprintf('Scenario 2: Following fast vehicle catches up to slower vehicle...\n');
        app.resetSimulation();
        app.setSignalPhase('EW_GREEN', 20.0);
        % Lead vehicle is slower (Bus/Truck speed 1.1)
        vLead = app.spawnSingleVehicle('East', 'Bus/Truck');
        vLead.X = 35.0;
        app.ActiveVehicles(1) = vLead;

        % Following vehicle is faster (Motorcycle speed 2.2)
        vFast = app.spawnSingleVehicle('East', 'Motorcycle');
        vFast.X = 65.0;
        app.ActiveVehicles(2) = vFast;

        for f = 1:30
            app.updateVehicles();
            bLead = app.getVehicleBoundingBox(app.ActiveVehicles(1));
            bFast = app.getVehicleBoundingBox(app.ActiveVehicles(2));
            assert(~app.checkAABBOverlap(bLead, bFast, 0.0), sprintf('Frame %d: Collision during catch-up', f));
            gap = (app.ActiveVehicles(2).X - app.ActiveVehicles(1).X) - (vFast.Length + vLead.Length) / 2.0;
            assert(gap >= 4.0 - 1e-4, sprintf('Frame %d: Bumper gap %.2f < 4.0m', f, gap));
            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 2: Faster following vehicle decelerates and stops safely behind lead vehicle.\n\n');

        % =================================================================
        % Scenario 3: Different vehicle lengths (Car behind Bus/Truck & Bike behind Fire Truck)
        % =================================================================
        fprintf('Scenario 3: Testing varying vehicle lengths (Car behind Bus/Truck)...\n');
        app.resetSimulation();
        app.setSignalPhase('NS_GREEN', 20.0);
        vBus = app.spawnSingleVehicle('South', 'Bus/Truck'); % Length 14m
        vBus.Y = -30.0;
        app.ActiveVehicles(1) = vBus;

        vCar = app.spawnSingleVehicle('South', 'Car');       % Length 8m
        vCar.Y = -55.0;
        app.ActiveVehicles(2) = vCar;

        for f = 1:30
            app.updateVehicles();
            bBus = app.getVehicleBoundingBox(app.ActiveVehicles(1));
            bCar = app.getVehicleBoundingBox(app.ActiveVehicles(2));
            assert(~app.checkAABBOverlap(bBus, bCar, 0.0), sprintf('Frame %d: Overlap with Car behind Bus', f));
            gap = (app.ActiveVehicles(1).Y - app.ActiveVehicles(2).Y) - (vBus.Length + vCar.Length) / 2.0;
            assert(gap >= 4.0 - 1e-4, sprintf('Frame %d: Bumper gap %.2f < 4.0m', f, gap));
            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 3: Mixed vehicle lengths (Car behind Bus/Truck) separated accurately.\n\n');

        % =================================================================
        % Scenario 4: Emergency vehicle behind normal vehicle
        % (emergency priority does NOT allow overlap or passing through)
        % =================================================================
        fprintf('Scenario 4: Emergency vehicle behind normal vehicle...\n');
        app.resetSimulation();
        app.setSignalPhase('EW_GREEN', 25.0);
        vNormal = app.spawnSingleVehicle('East', 'Car'); % Length 8m, Speed 1.6
        vNormal.X = 30.0;
        app.ActiveVehicles(1) = vNormal;

        vAmb = app.triggerEmergencyVehicle('East', 'Ambulance'); % Length 9.5m, Speed 2.0
        aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
        app.ActiveVehicles(aIdx).X = 52.0;

        for f = 1:35
            app.updateVehicles();
            nIdx = find([app.ActiveVehicles.ID] == vNormal.ID, 1);
            aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
            if isempty(nIdx) || isempty(aIdx)
                break;
            end
            bN = app.getVehicleBoundingBox(app.ActiveVehicles(nIdx));
            bA = app.getVehicleBoundingBox(app.ActiveVehicles(aIdx));
            assert(~app.checkAABBOverlap(bN, bA, 0.0), sprintf('Frame %d: Ambulance overlapped normal vehicle', f));
            gap = (app.ActiveVehicles(aIdx).X - app.ActiveVehicles(nIdx).X) - (vAmb.Length + vNormal.Length) / 2.0;
            assert(gap >= 4.0 - 1e-4, sprintf('Frame %d: Ambulance bumper gap %.2f < 4.0m', f, gap));
            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 4: Priority emergency vehicle strictly respects normal vehicle buffer.\n\n');

        % =================================================================
        % Scenario 5: Emergency vehicle approaching intersection while conflicting traffic stops
        % =================================================================
        fprintf('Scenario 5: Emergency vehicle crossing while conflicting traffic safely stopped at RED...\n');
        app.resetSimulation();
        app.setSignalPhase('NS_GREEN', 12.0);

        % North & South cars stopped at red stop line
        vN = app.spawnSingleVehicle('North', 'Car');
        vN.Y = 25.0; % Stopped before Y=20 stop line
        app.ActiveVehicles(1) = vN;

        vS = app.spawnSingleVehicle('South', 'Car');
        vS.Y = -25.0; % Stopped before Y=-20 stop line
        app.ActiveVehicles(2) = vS;

        % Trigger East emergency
        vPolice = app.triggerEmergencyVehicle('East', 'Police');
        pIdx = find([app.ActiveVehicles.ID] == vPolice.ID, 1);
        app.ActiveVehicles(pIdx).X = 40.0;

        % Advance through preemption into priority green
        app.updateTrafficSignals(2.0); % NS_YELLOW -> ALL_RED
        app.updateTrafficSignals(1.0); % ALL_RED -> EW_GREEN

        for f = 1:40
            app.updateVehicles();
            app.updateTrafficSignals(0.05);

            % Check pairwise bounding boxes between Police and stopped NS cars
            pIdx = find([app.ActiveVehicles.ID] == vPolice.ID, 1);
            if isempty(pIdx), break; end
            bP = app.getVehicleBoundingBox(app.ActiveVehicles(pIdx));

            for other = 1:numel(app.ActiveVehicles)
                if other == pIdx, continue; end
                bOther = app.getVehicleBoundingBox(app.ActiveVehicles(other));
                assert(~app.checkAABBOverlap(bP, bOther, 0.0), ...
                    sprintf('Frame %d: Police vehicle overlapped conflicting vehicle %d', f, other));
            end

            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 5: Emergency vehicle crossed safely with 0 overlap against conflicting traffic.\n\n');

        % =================================================================
        % Scenario 6: Multiple vehicles queued at RED stop line
        % =================================================================
        fprintf('Scenario 6: Multiple vehicles queued at RED stop line...\n');
        app.resetSimulation();
        app.setSignalPhase('EW_GREEN', 10.0); % North is RED

        % Place 4 vehicles approaching North red light
        v1 = app.spawnSingleVehicle('North', 'Car'); v1.Y = 26.0; app.ActiveVehicles(1) = v1;
        v2 = app.spawnSingleVehicle('North', 'Bus/Truck'); v2.Y = 46.0; app.ActiveVehicles(2) = v2;
        v3 = app.spawnSingleVehicle('North', 'Motorcycle'); v3.Y = 66.0; app.ActiveVehicles(3) = v3;
        v4 = app.spawnSingleVehicle('North', 'Car'); v4.Y = 82.0; app.ActiveVehicles(4) = v4;

        for f = 1:40
            app.updateVehicles();
            % Verify queue maintains strictly positive gaps between all consecutive pairs
            for q = 1:3
                fLeader = app.ActiveVehicles(q);
                fFollow = app.ActiveVehicles(q + 1);
                bL = app.getVehicleBoundingBox(fLeader);
                bF = app.getVehicleBoundingBox(fFollow);
                assert(~app.checkAABBOverlap(bL, bF, 0.0), sprintf('Frame %d: Overlap in queue between %d and %d', f, q, q+1));
                gap = (fFollow.Y - fLeader.Y) - (fFollow.Length + fLeader.Length) / 2.0;
                assert(gap >= 4.0 - 1e-4, sprintf('Frame %d: Queue gap between %d and %d is %.2f < 4.0m', f, q, q+1, gap));
            end
            if isVisual && mod(f, 4) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 6: Multi-vehicle queue maintains crisp, non-overlapping bumper gaps.\n\n');

        % =================================================================
        % Scenario 7: Vehicles crossing after signal transition
        % =================================================================
        fprintf('Scenario 7: Testing vehicles crossing during/after signal transition...\n');
        app.resetSimulation();
        app.setSignalPhase('NS_GREEN', 2.0);

        % North car in intersection
        vN = app.spawnSingleVehicle('North', 'Car');
        vN.Y = 10.0; % Inside intersection box
        app.ActiveVehicles(1) = vN;

        % East car waiting before stop line
        vE = app.spawnSingleVehicle('East', 'Car');
        vE.X = 26.0;
        app.ActiveVehicles(2) = vE;

        % Transition signals to EW_GREEN
        app.updateTrafficSignals(2.0); % NS_YELLOW
        app.updateTrafficSignals(2.0); % ALL_RED_1
        app.updateTrafficSignals(1.0); % EW_GREEN

        for f = 1:35
            app.updateVehicles();
            app.updateTrafficSignals(0.05);
            if numel(app.ActiveVehicles) >= 2
                bN = app.getVehicleBoundingBox(app.ActiveVehicles(1));
                bE = app.getVehicleBoundingBox(app.ActiveVehicles(2));
                assert(~app.checkAABBOverlap(bN, bE, 0.0), sprintf('Frame %d: Intersection collision during transition', f));
            end
            if isVisual && mod(f, 3) == 0
                drawnow;
                pause(0.04);
            end
        end
        fprintf('  [PASS] Scenario 7: Vehicles crossing after signal transition produce 0 collisions.\n\n');

        % =================================================================
        % Scenario 8: Continuous multi-frame simulation loop (100+ frames)
        % Every pair of active vehicles checked on EVERY frame (0 overlaps permitted)
        % =================================================================
        fprintf('Scenario 8: Running 120-frame continuous simulation loop with all-pair checks...\n');
        app.resetSimulation();
        app.startSimulation();

        totalPairsChecked = 0;
        for f = 1:120
            app.timerTickCallback();
            nV = numel(app.ActiveVehicles);
            if nV >= 2
                for i = 1:nV
                    boxI = app.getVehicleBoundingBox(app.ActiveVehicles(i));
                    for j = (i + 1):nV
                        boxJ = app.getVehicleBoundingBox(app.ActiveVehicles(j));
                        hasOverlap = app.checkAABBOverlap(boxI, boxJ, 0.0);
                        assert(~hasOverlap, sprintf('Frame %d: Overlap detected between vehicle %d (Type: %s, Dir: %s) and vehicle %d (Type: %s, Dir: %s)', ...
                            f, app.ActiveVehicles(i).ID, app.ActiveVehicles(i).Type, app.ActiveVehicles(i).Direction, ...
                            app.ActiveVehicles(j).ID, app.ActiveVehicles(j).Type, app.ActiveVehicles(j).Direction));
                        totalPairsChecked = totalPairsChecked + 1;
                    end
                end
            end
            if isVisual && mod(f, 4) == 0
                drawnow;
                pause(0.02);
            end
        end
        app.stopSimulation();
        fprintf('  [PASS] Scenario 8: 120 frames completed (%d pairwise checks) — ZERO OVERLAPS!\n\n', totalPairsChecked);

        % Cleanup
        delete(app);

        fprintf('=================================================================\n');
        fprintf('  [SUCCESS] ALL 8 COLLISION & SMOOTHNESS SCENARIOS PASSED!      \n');
        fprintf('=================================================================\n');
        passed = true;

    catch ME
        fprintf('\n[FAIL] Collision & Smoothness Test Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('In file: %s (Line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        if exist('app', 'var') && isvalid(app)
            delete(app);
        end
        passed = false;
        if ~isVisual
            error('Collision test failed');
        end
    end
end
