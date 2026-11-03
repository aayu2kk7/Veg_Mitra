function passed = verify_Phase8_EmergencyPriority(mode)
% VERIFY_PHASE8_EMERGENCYPRIORITY Targeted verification of Phase 8 Emergency Priority.
%
% This verification procedure reliably reproduces and validates:
% 1. Start normal AI Adaptive traffic (NS GREEN).
% 2. Spawn an ambulance from East.
% 3. Show EW emergency priority request.
% 4. Safely transition signals if NS was green (NS GREEN -> NS YELLOW 2s -> ALL RED 1s -> EW GREEN).
% 5. Show East + West priority GREEN established and UI state updated.
% 6. Show ambulance moving through the intersection.
% 7. Show normal NS traffic safely stopped at RED.
% 8. Show ambulance clearing the conflict zone (past X = -20).
% 9. Transition through EW YELLOW (2s) + ALL RED (1s).
% 10. Return to AI Adaptive mode.
% 11. Demonstrate that adaptive timing resumes and recalculates from live density.
%
% Usage:
%   verify_Phase8_EmergencyPriority           % Automated verification mode (fast, assertions)
%   verify_Phase8_EmergencyPriority('visual') % Visual mode (shows GUI, animates steps)

    if nargin < 1 || isempty(mode)
        mode = 'auto';
    end
    isVisual = strcmpi(mode, 'visual') || isequal(mode, true);

    fprintf('=================================================================\n');
    fprintf('  VEGMITRA PHASE 8: EMERGENCY VEHICLE PRIORITY VERIFICATION       \n');
    fprintf('  Scenario: Ambulance from East -> Safe Signal Preemption -> Clear \n');
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
        % Step 1: Start normal AI Adaptive traffic (NS GREEN)
        % -----------------------------------------------------------------
        fprintf('\nStep 1: Setting up normal traffic with NS GREEN...\n');
        app.setSignalPhase('NS_GREEN', 12.0);
        
        % Spawn normal vehicles in North and South
        vN1 = app.spawnSingleVehicle('North', 'Car');
        vN1.Y = 35;
        app.ActiveVehicles(1) = vN1;
        
        vS1 = app.spawnSingleVehicle('South', 'Car');
        vS1.Y = -35;
        app.ActiveVehicles(2) = vS1;
        
        app.updateVehicleCounts();
        app.calculateTrafficDensity();
        app.updateTrafficDensityUI();

        assert(strcmp(app.getSignalState('North'), 'GREEN'), 'North signal must be GREEN');
        assert(strcmp(app.getSignalState('South'), 'RED'),   'South signal must be RED');
        assert(strcmp(app.getSignalState('East'),  'RED'),   'East signal must be RED');
        assert(strcmp(app.getSignalState('West'),  'RED'),   'West signal must be RED');
        assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Controller Mode must be AI Adaptive');
        fprintf('  [OK] Normal traffic active with NS GREEN.\n');

        if isVisual
            drawnow;
            pause(0.8);
        end

        % -----------------------------------------------------------------
        % Step 2 & 3: Spawn Ambulance from East & Request EW Emergency Priority
        % -----------------------------------------------------------------
        fprintf('\nStep 2 & 3: Triggering Ambulance from East and requesting EW priority...\n');
        vAmb = app.triggerEmergencyVehicle('East', 'Ambulance');
        assert(~isempty(vAmb), 'Ambulance must spawn successfully');
        assert(vAmb.IsEmergency == true, 'Ambulance must be marked IsEmergency == true');
        assert(strcmp(vAmb.EmergencyType, 'Ambulance'), 'EmergencyType must be Ambulance');
        assert(app.EmergencyActive == true, 'Emergency priority must become active');
        assert(strcmp(app.EmergencyTargetGroup, 'EW'), 'Emergency target group must be EW');
        assert(strcmp(app.EmergencyDirection, 'East'), 'Emergency origin direction must be East');
        assert(strcmp(app.ControllerModeValue.Text, 'EMERGENCY PRIORITY'), 'Controller Mode must be EMERGENCY PRIORITY');
        fprintf('  [OK] Ambulance spawned on East with IsEmergency=true, EW priority active.\n');

        if isVisual
            drawnow;
            pause(0.8);
        end

        % -----------------------------------------------------------------
        % Step 4: Verify Safe Preemption Transition (NS_GREEN -> YELLOW 2s -> ALL_RED 1s -> EW_GREEN)
        % -----------------------------------------------------------------
        fprintf('\nStep 4: Verifying safe preemption transition sequence...\n');
        assert(strcmp(app.SignalPhase, 'NS_YELLOW'), 'Conflicting NS_GREEN must transition immediately to NS_YELLOW');
        assert(app.SignalPhaseTimeRemaining == 2.0, 'Yellow interval must be exactly 2.0 seconds');
        fprintf('  [OK] Preemption initiated: NS_YELLOW (2s).\n');

        if isVisual
            for t = 1:4
                app.updateTrafficSignals(0.5);
                drawnow;
                pause(0.2);
            end
        else
            app.updateTrafficSignals(2.0);
        end

        assert(strcmp(app.SignalPhase, 'ALL_RED_1'), 'Yellow must transition to ALL_RED_1');
        assert(app.SignalPhaseTimeRemaining == 1.0, 'All-Red interval must be exactly 1.0 second');
        fprintf('  [OK] Safety clearance: ALL_RED_1 (1s).\n');

        if isVisual
            for t = 1:2
                app.updateTrafficSignals(0.5);
                drawnow;
                pause(0.2);
            end
        else
            app.updateTrafficSignals(1.0);
        end

        % -----------------------------------------------------------------
        % Step 5: Verify East Priority GREEN Established
        % -----------------------------------------------------------------
        fprintf('\nStep 5: Verifying East Priority GREEN established...\n');
        assert(strcmp(app.SignalPhase, 'EAST_GREEN') || strcmp(app.SignalPhase, 'EW_GREEN'), 'Phase must transition to EAST_GREEN or EW_GREEN');
        assert(strcmp(app.getSignalState('East'),  'GREEN'), 'East signal must be GREEN');
        assert(strcmp(app.getSignalState('North'), 'RED'),   'North signal must be RED');
        assert(strcmp(app.getSignalState('South'), 'RED'),   'South signal must be RED');
        assert(strcmp(app.EmergencyPriorityState, 'ACTIVE'), 'Emergency priority state must be ACTIVE');
        assert(contains(app.CurrentGreenRoadValue.Text, 'East'), 'Green road must display East');
        fprintf('  [OK] East Priority GREEN illuminated. Conflicting NS signals strictly RED.\n');

        if isVisual
            drawnow;
            pause(0.8);
        end

        % -----------------------------------------------------------------
        % Step 6 & 7: Advance Ambulance through Intersection & Check NS Stays Stopped
        % -----------------------------------------------------------------
        fprintf('\nStep 6 & 7: Advancing vehicles; verifying NS stops and Ambulance advances...\n');
        % Position ambulance near East stop line at X = 26
        aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
        app.ActiveVehicles(aIdx).X = 26;
        
        % Position North car near North stop line at Y = 25
        nIdx = find([app.ActiveVehicles.ID] == vN1.ID, 1);
        app.ActiveVehicles(nIdx).Y = 25;

        for step = 1:20
            app.updateVehicles();
            app.updateTrafficSignals(0.1);
            if isVisual && mod(step, 2) == 0
                drawnow;
                pause(0.05);
            end
        end

        % North vehicle must have remained stopped before stop line (Y >= 20.0)
        nIdx = find([app.ActiveVehicles.ID] == vN1.ID, 1);
        frontN = app.ActiveVehicles(nIdx).Y - app.ActiveVehicles(nIdx).Length / 2.0;
        assert(frontN >= 20.0, sprintf('Conflicting North vehicle must halt at RED (front = %.1f >= 20.0)', frontN));
        fprintf('  [OK] Conflicting North vehicle halted at RED stop line (front = %.1f >= 20.0).\n', frontN);

        % Ambulance must have crossed the stop line into the intersection
        aIdx = find([app.ActiveVehicles.ID] == vAmb.ID, 1);
        frontAmb = app.ActiveVehicles(aIdx).X - app.ActiveVehicles(aIdx).Length / 2.0;
        assert(frontAmb < 20.0, sprintf('Ambulance must advance on priority GREEN (front = %.1f < 20.0)', frontAmb));
        fprintf('  [OK] Ambulance proceeded across East stop line on priority GREEN.\n');

        % -----------------------------------------------------------------
        % Step 8: Complete Ambulance Clearance Past Intersection (X <= -20)
        % -----------------------------------------------------------------
        fprintf('\nStep 8: Ambulance completes intersection crossing and clears conflict zone...\n');
        app.ActiveVehicles(aIdx).X = -26; % Far past conflict boundary
        assert(app.checkEmergencyCleared() == true, 'checkEmergencyCleared must return true');
        fprintf('  [OK] Event-based clearance detected: Ambulance has exited intersection conflict zone.\n');

        if isVisual
            drawnow;
            pause(0.6);
        end

        % -----------------------------------------------------------------
        % Step 9: Verify Safe Post-Emergency Transition (EW_YELLOW 2s -> ALL_RED_2 1s)
        % -----------------------------------------------------------------
        fprintf('\nStep 9: Verifying post-emergency safe transition (YELLOW 2s -> ALL RED 1s)...\n');
        app.updateTrafficSignals(0.1);
        assert(app.EmergencyActive == false, 'EmergencyActive must be released');
        assert(strcmp(app.EmergencyPriorityState, 'CLEARING'), 'Priority state must be CLEARING');
        assert(strcmp(app.SignalPhase, 'EW_YELLOW') || strcmp(app.SignalPhase, 'EAST_YELLOW'), 'Signal must transition to YELLOW');
        fprintf('  [OK] Emergency green released -> YELLOW (2s).\n');

        if isVisual
            for t = 1:4
                app.updateTrafficSignals(0.5);
                drawnow;
                pause(0.2);
            end
        else
            app.updateTrafficSignals(2.0);
        end

        assert(strcmp(app.SignalPhase, 'ALL_RED') || strcmp(app.SignalPhase, 'ALL_RED_2'), 'Phase must transition to ALL_RED');
        fprintf('  [OK] Clearance transition -> ALL_RED_2 (1s).\n');

        if isVisual
            for t = 1:2
                app.updateTrafficSignals(0.5);
                drawnow;
                pause(0.2);
            end
        else
            app.updateTrafficSignals(1.0);
        end

        % -----------------------------------------------------------------
        % Step 10 & 11: Return to AI Adaptive and Recalculate Live Timing
        % -----------------------------------------------------------------
        fprintf('\nStep 10 & 11: Verifying seamless restoration of Phase 7 AI Adaptive mode...\n');
        assert(strcmp(app.ControllerModeValue.Text, 'AI Adaptive'), 'Controller Mode must return to AI Adaptive');
        assert(strcmp(app.EmergencyPriorityState, 'NORMAL'), 'EmergencyPriorityState must return to NORMAL');
        assert(ismember(app.SignalPhase, {'NORTH_GREEN', 'SOUTH_GREEN', 'EAST_GREEN', 'WEST_GREEN', 'NS_GREEN', 'EW_GREEN'}), 'Phase must return to a valid adaptive GREEN');
        assert(app.SignalPhaseTimeRemaining >= 5.0 && app.SignalPhaseTimeRemaining <= 30.0, ...
            'Green duration must recalculate from current traffic density (5-30s)');
        fprintf('  [OK] AI Adaptive controller restored. Next phase selected with dynamic timing: %.0fs green.\n', ...
            app.SignalPhaseTimeRemaining);

        if isVisual
            drawnow;
            pause(1.0);
        end

        % Clean up
        delete(app);

        fprintf('\n=================================================================\n');
        fprintf('  [PASS] ALL PHASE 8 VERIFICATION CHECKS COMPLETED SUCCESSFULLY! \n');
        fprintf('=================================================================\n');
        passed = true;

    catch ME
        fprintf('\n[FAIL] Phase 8 Verification Error: %s\n', ME.message);
        fprintf('In file: %s (Line %d)\n', ME.stack(1).file, ME.stack(1).line);
        if isvalid(app)
            delete(app);
        end
        passed = false;
    end
end
