function passed = verify_Phase7_EW_VeryHigh(mode)
% VERIFY_PHASE7_EW_VERYHIGH Targeted verification of Phase 7 Adaptive Timing.
%
% This verification procedure reliably reproduces and validates the scenario where:
% 1. EW demand is VERY HIGH: East = 90%, West = 90% (9 vehicles each, capacity 10).
% 2. NS demand is lower: North = 50%, South = 50% (5 vehicles each).
% 3. A new adaptive green-phase selection is triggered after densities are set.
% 4. The newly selected EW green phase receives:
%    - Green duration = 20 seconds
%    - AI Decision indicates: "EW selected: VERY HIGH traffic -> 20s green"
%    - Current Green Road = "East + West"
%    - Current Green Time starts at approximately 20s.
% 5. The 20s green duration does NOT continuously change merely because live density
%    changes while the green phase is active.
% 6. The subsequent phase transitions preserve:
%    - Yellow = 2s
%    - All-Red = 1s
%    - Conflicting directions are never green simultaneously.
%
% Usage:
%   verify_Phase7_EW_VeryHigh           % Automated verification mode (fast, automated checks)
%   verify_Phase7_EW_VeryHigh('visual') % Visual mode (shows GUI, animates steps for inspection)

    if nargin < 1 || isempty(mode)
        mode = 'auto';
    end
    isVisual = strcmpi(mode, 'visual') || isequal(mode, true);

    fprintf('=================================================================\n');
    fprintf('  VEGMITRA PHASE 7: TARGETED ADAPTIVE TIMING VERIFICATION        \n');
    fprintf('  Scenario: EW VERY HIGH (90%%) vs NS MEDIUM (50%%)              \n');
    fprintf('  Mode: %s\n', upper(mode));
    fprintf('=================================================================\n\n');

    % Step 0: Initialize Application
    fprintf('Step 0: Initializing VegMitraApp...\n');
    app = VegMitraApp();
    app.resetSimulation();

    if isVisual
        app.UIFigure.Visible = 'on';
        figure(app.UIFigure); % Bring to front
        drawnow;
        pause(0.5);
    end

    try
        % -----------------------------------------------------------------
        % Step 1 & 2: Set EW demand to VERY HIGH (90%) and NS demand to 50%
        % -----------------------------------------------------------------
        fprintf('\nStep 1 & 2: Setting EW demand to 90%% (VERY HIGH) and NS demand to 50%% (MEDIUM)...\n');
        
        % Spawn 9 vehicles on East (90% VERY HIGH)
        for k = 1:9
            eIdx = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
            for j = 1:numel(eIdx)
                app.ActiveVehicles(eIdx(j)).X = 24 + (j - 1) * 6;
            end
            app.spawnSingleVehicle('East', 'Car');
        end

        % Spawn 9 vehicles on West (90% VERY HIGH)
        for k = 1:9
            wIdx = find(strcmp({app.ActiveVehicles.Direction}, 'West'));
            for j = 1:numel(wIdx)
                app.ActiveVehicles(wIdx(j)).X = -24 - (j - 1) * 6;
            end
            app.spawnSingleVehicle('West', 'Car');
        end

        % Spawn 5 vehicles on North (50% MEDIUM)
        for k = 1:5
            nIdx = find(strcmp({app.ActiveVehicles.Direction}, 'North'));
            for j = 1:numel(nIdx)
                app.ActiveVehicles(nIdx(j)).Y = 24 + (j - 1) * 6;
            end
            app.spawnSingleVehicle('North', 'Car');
        end

        % Spawn 5 vehicles on South (50% MEDIUM)
        for k = 1:5
            sIdx = find(strcmp({app.ActiveVehicles.Direction}, 'South'));
            for j = 1:numel(sIdx)
                app.ActiveVehicles(sIdx(j)).Y = -24 - (j - 1) * 6;
            end
            app.spawnSingleVehicle('South', 'Car');
        end

        % Update counts and calculate density
        app.updateVehicleCounts();
        densities = app.calculateTrafficDensity();
        app.updateTrafficDensityUI();

        if isVisual
            drawnow;
            pause(1.0);
        end

        % Assert directional densities
        assert(densities.East.Percentage == 90, sprintf('East density expected 90%%, got %d%%', densities.East.Percentage));
        assert(strcmp(densities.East.Level, 'VERY HIGH'), sprintf('East level expected VERY HIGH, got %s', densities.East.Level));
        assert(densities.West.Percentage == 90, sprintf('West density expected 90%%, got %d%%', densities.West.Percentage));
        assert(strcmp(densities.West.Level, 'VERY HIGH'), sprintf('West level expected VERY HIGH, got %s', densities.West.Level));
        assert(densities.North.Percentage == 50, sprintf('North density expected 50%%, got %d%%', densities.North.Percentage));
        assert(strcmp(densities.North.Level, 'MEDIUM'), sprintf('North level expected MEDIUM, got %s', densities.North.Level));
        assert(densities.South.Percentage == 50, sprintf('South density expected 50%%, got %d%%', densities.South.Percentage));
        assert(strcmp(densities.South.Level, 'MEDIUM'), sprintf('South level expected MEDIUM, got %s', densities.South.Level));

        [nsDemand, ewDemand] = app.getGroupDemands();
        assert(ewDemand == 90, sprintf('EW demand expected 90%%, got %d%%', ewDemand));
        assert(nsDemand == 50, sprintf('NS demand expected 50%%, got %d%%', nsDemand));

        fprintf('  [PASS] East Density:  %d%% (%s)\n', densities.East.Percentage, densities.East.Level);
        fprintf('  [PASS] West Density:  %d%% (%s)\n', densities.West.Percentage, densities.West.Level);
        fprintf('  [PASS] North Density: %d%% (%s)\n', densities.North.Percentage, densities.North.Level);
        fprintf('  [PASS] South Density: %d%% (%s)\n', densities.South.Percentage, densities.South.Level);
        fprintf('  [PASS] Group Demands: EW = %d%% (VERY HIGH), NS = %d%% (MEDIUM)\n', ewDemand, nsDemand);

        % -----------------------------------------------------------------
        % Step 3: Trigger a NEW adaptive green-phase selection
        % -----------------------------------------------------------------
        fprintf('\nStep 3: Triggering a NEW adaptive green-phase selection...\n');
        decision = app.selectNextAdaptivePhase();

        if isVisual
            drawnow;
            pause(1.0);
        end

        % -----------------------------------------------------------------
        % Step 4: Verify newly selected EW green phase properties
        % -----------------------------------------------------------------
        fprintf('\nStep 4: Verifying newly selected EW green phase properties...\n');
        
        % 4a. Active phase must be EW_GREEN
        assert(strcmp(app.getSignalPhase(), 'EW_GREEN'), ...
            sprintf('Expected phase EW_GREEN, got %s', app.getSignalPhase()));
        fprintf('  [PASS] Active Signal Phase: %s\n', app.getSignalPhase());

        % 4b. Green duration must be exactly 20 seconds
        assert(decision.GreenDuration == 20.0, ...
            sprintf('Decision GreenDuration expected 20s, got %0.1fs', decision.GreenDuration));
        assert(abs(app.SignalPhaseTimeRemaining - 20.0) < 1e-4, ...
            sprintf('SignalPhaseTimeRemaining expected 20s, got %0.1fs', app.SignalPhaseTimeRemaining));
        fprintf('  [PASS] Green Duration: %0.1fs\n', app.SignalPhaseTimeRemaining);

        % 4c. AI Decision indicates "EW selected: VERY HIGH traffic -> 20s green"
        arrowChar = char(8594);
        expectedDecText = sprintf('EW selected: VERY HIGH traffic %s 20s green', arrowChar);
        assert(strcmp(decision.DecisionText, expectedDecText), ...
            sprintf('DecisionText mismatch:\n  Expected: "%s"\n  Got:      "%s"', expectedDecText, decision.DecisionText));
        assert(strcmp(app.AIDecisionValue.Text, expectedDecText), ...
            sprintf('AIDecisionValue.Text mismatch:\n  Expected: "%s"\n  Got:      "%s"', expectedDecText, app.AIDecisionValue.Text));
        fprintf('  [PASS] AI Decision Text: "%s"\n', app.AIDecisionValue.Text);

        % 4d. Current Green Road = "East + West"
        assert(strcmp(app.CurrentGreenRoadValue.Text, 'East + West'), ...
            sprintf('CurrentGreenRoad expected "East + West", got "%s"', app.CurrentGreenRoadValue.Text));
        fprintf('  [PASS] Current Green Road: "%s"\n', app.CurrentGreenRoadValue.Text);

        % 4e. Current Green Time starts at approximately 20s
        assert(strcmp(app.CurrentGreenTimeValue.Text, '20s'), ...
            sprintf('CurrentGreenTimeValue expected "20s", got "%s"', app.CurrentGreenTimeValue.Text));
        fprintf('  [PASS] Current Green Time: "%s"\n', app.CurrentGreenTimeValue.Text);

        % 4f. Verify signal lamp states (EW GREEN, NS RED)
        assert(strcmp(app.getSignalState('East'),  'GREEN'), 'East signal must be GREEN');
        assert(strcmp(app.getSignalState('West'),  'GREEN'), 'West signal must be GREEN');
        assert(strcmp(app.getSignalState('North'), 'RED'),   'North signal must be RED');
        assert(strcmp(app.getSignalState('South'), 'RED'),   'South signal must be RED');
        fprintf('  [PASS] Signal Lamp States: East=GREEN, West=GREEN, North=RED, South=RED\n');

        % -----------------------------------------------------------------
        % Step 5: Verify 20s duration does NOT continuously change mid-phase
        %         when live density changes
        % -----------------------------------------------------------------
        fprintf('\nStep 5: Verifying duration does NOT change mid-phase when live density changes...\n');

        % Simulate 5 seconds of active EW_GREEN elapsed
        elapsedDt = 5.0;
        stepDt = 0.5;
        numSteps = round(elapsedDt / stepDt);
        for s = 1:numSteps
            app.updateTrafficSignals(stepDt);
            if isVisual && mod(s, 2) == 0
                drawnow;
                pause(0.1);
            end
        end

        expectedRemaining = 20.0 - elapsedDt; % 15.0s
        assert(abs(app.SignalPhaseTimeRemaining - expectedRemaining) < 1e-4, ...
            sprintf('Remaining time expected %0.1fs, got %0.1fs', expectedRemaining, app.SignalPhaseTimeRemaining));
        assert(strcmp(app.CurrentGreenTimeValue.Text, '15s'), ...
            sprintf('CurrentGreenTimeValue expected "15s", got "%s"', app.CurrentGreenTimeValue.Text));
        fprintf('  [PASS] After %0.1fs countdown: Time Remaining = %0.1fs, UI = "%s"\n', ...
            elapsedDt, app.SignalPhaseTimeRemaining, app.CurrentGreenTimeValue.Text);

        % Now drastically change live density mid-phase (e.g. 8 East cars exit or clear, dropping East to 10% LOW)
        fprintf('  Simulating live density change mid-phase (clearing 8 East vehicles)...\n');
        eastIndices = find(strcmp({app.ActiveVehicles.Direction}, 'East'));
        if numel(eastIndices) >= 8
            app.ActiveVehicles(eastIndices(1:8)) = [];
        end
        app.updateVehicleCounts();
        changedDensities = app.calculateTrafficDensity();
        app.updateTrafficDensityUI();

        assert(changedDensities.East.Percentage == 10, ...
            sprintf('East density should now be 10%%, got %d%%', changedDensities.East.Percentage));
        assert(strcmp(changedDensities.East.Level, 'LOW'), ...
            sprintf('East level should now be LOW, got %s', changedDensities.East.Level));
        fprintf('  [PASS] Live East Density changed to: %d%% (%s)\n', ...
            changedDensities.East.Percentage, changedDensities.East.Level);

        if isVisual
            drawnow;
            pause(1.0);
        end

        % Advance another 1.0 second of simulation time
        app.updateTrafficSignals(1.0);
        if isVisual
            drawnow;
        end

        % Verify duration remained based on the 20s phase allocation (now 14.0s)
        % and did NOT suddenly jump, shorten to 8s (LOW), or recalculate mid-phase
        assert(abs(app.SignalPhaseTimeRemaining - 14.0) < 1e-4, ...
            sprintf('SignalPhaseTimeRemaining must continue down to 14.0s, got %0.1fs', app.SignalPhaseTimeRemaining));
        assert(strcmp(app.CurrentGreenTimeValue.Text, '14s'), ...
            sprintf('CurrentGreenTimeValue expected "14s", got "%s"', app.CurrentGreenTimeValue.Text));

        % Verify AI Decision label was NOT altered mid-phase
        assert(strcmp(app.AIDecisionValue.Text, expectedDecText), ...
            sprintf('AIDecisionValue text must remain fixed mid-phase, got "%s"', app.AIDecisionValue.Text));
        fprintf('  [PASS] Mid-phase stability verified: Remaining = %0.1fs, UI = "%s", AI Decision remains "%s"\n', ...
            app.SignalPhaseTimeRemaining, app.CurrentGreenTimeValue.Text, app.AIDecisionValue.Text);

        % -----------------------------------------------------------------
        % Step 6: Verify next phase transition preserves Yellow=2s, All-Red=1s,
        %         and no conflicting greens
        % -----------------------------------------------------------------
        fprintf('\nStep 6: Verifying safety intervals (Yellow=2s, All-Red=1s) and no conflicting greens...\n');

        % Advance remaining 14 seconds to complete the EW_GREEN phase
        app.updateTrafficSignals(14.0);
        if isVisual
            drawnow;
            pause(1.0);
        end

        % Verify transition to EW_YELLOW
        assert(strcmp(app.getSignalPhase(), 'EW_YELLOW'), ...
            sprintf('Expected phase EW_YELLOW, got %s', app.getSignalPhase()));
        assert(app.SignalPhaseTimeRemaining == 2.0, ...
            sprintf('Yellow duration expected 2s, got %0.1fs', app.SignalPhaseTimeRemaining));
        assert(strcmp(app.getSignalState('East'),  'YELLOW'), 'East signal must be YELLOW');
        assert(strcmp(app.getSignalState('West'),  'YELLOW'), 'West signal must be YELLOW');
        assert(strcmp(app.getSignalState('North'), 'RED'),    'North signal must be RED');
        assert(strcmp(app.getSignalState('South'), 'RED'),    'South signal must be RED');
        fprintf('  [PASS] Phase transitioned to EW_YELLOW (Duration: %0.1fs)\n', app.SignalPhaseTimeRemaining);
        fprintf('  [PASS] Signal States: East=YELLOW, West=YELLOW, North=RED, South=RED\n');

        % Advance 2 seconds to complete EW_YELLOW
        app.updateTrafficSignals(2.0);
        if isVisual
            drawnow;
            pause(1.0);
        end

        % Verify transition to ALL_RED_2
        assert(strcmp(app.getSignalPhase(), 'ALL_RED_2'), ...
            sprintf('Expected phase ALL_RED_2, got %s', app.getSignalPhase()));
        assert(app.SignalPhaseTimeRemaining == 1.0, ...
            sprintf('All-Red duration expected 1s, got %0.1fs', app.SignalPhaseTimeRemaining));
        assert(strcmp(app.getSignalState('East'),  'RED'), 'East signal must be RED');
        assert(strcmp(app.getSignalState('West'),  'RED'), 'West signal must be RED');
        assert(strcmp(app.getSignalState('North'), 'RED'), 'North signal must be RED');
        assert(strcmp(app.getSignalState('South'), 'RED'), 'South signal must be RED');
        fprintf('  [PASS] Phase transitioned to ALL_RED_2 (Duration: %0.1fs)\n', app.SignalPhaseTimeRemaining);
        fprintf('  [PASS] Signal States: All 4 directions RED (Zero conflicting greens)\n');

        % Advance 1 second to complete ALL_RED_2 and trigger next adaptive phase
        app.updateTrafficSignals(1.0);
        if isVisual
            drawnow;
            pause(1.0);
        end

        nextPhase = app.getSignalPhase();
        fprintf('  [PASS] Next adaptive phase initiated cleanly: %s\n', nextPhase);
        assert(ismember(nextPhase, {'NS_GREEN', 'EW_GREEN'}), 'Next phase must be a valid green phase');

        % Final Safety Verification: Conflicting directions NEVER green simultaneously
        eState = app.getSignalState('East');
        wState = app.getSignalState('West');
        nState = app.getSignalState('North');
        sState = app.getSignalState('South');
        isEWGreen = strcmp(eState, 'GREEN') || strcmp(wState, 'GREEN');
        isNSGreen = strcmp(nState, 'GREEN') || strcmp(sState, 'GREEN');
        assert(~(isEWGreen && isNSGreen), 'CRITICAL SAFETY VIOLATION: EW and NS cannot be green simultaneously!');
        fprintf('  [PASS] Safety Invariant Verified: Zero conflicting greens.\n');

        passed = true;
        fprintf('\n=================================================================\n');
        fprintf('  [SUCCESS] ALL VERIFICATION CHECKS PASSED PERFECTLY!            \n');
        fprintf('  Adaptive Timing logic in Phase 7 operates correctly as designed.\n');
        fprintf('=================================================================\n\n');

    catch ME
        passed = false;
        fprintf('\n[FAIL] Verification encountered an error:\n%s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('In %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end

    % Clean up figure in automated mode
    if ~isVisual && ~isempty(app.UIFigure) && isvalid(app.UIFigure)
        delete(app.UIFigure);
    elseif isVisual
        fprintf('Visual mode: App window left open for inspection.\n');
        fprintf('To close, run: delete(app.UIFigure) or close the window.\n');
    end
end
