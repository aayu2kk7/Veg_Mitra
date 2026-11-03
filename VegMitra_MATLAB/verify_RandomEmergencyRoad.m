function verify_RandomEmergencyRoad()
    % VERIFY_RANDOMEMERGENCYROAD
    % Verifies that Emergency Mode button triggers a randomly selected starting road
    % among NORTH, SOUTH, EAST, and WEST across multiple simulation resets/runs.
    
    fprintf('=================================================================\n');
    fprintf('  VERIFYING RANDOM EMERGENCY VEHICLE STARTING ROAD SELECTION    \n');
    fprintf('=================================================================\n');
    
    app = VegMitraApp();
    
    roadsSeen = containers.Map({'North', 'South', 'East', 'West'}, [false, false, false, false]);
    roadCounts = struct('North', 0, 'South', 0, 'East', 0, 'West', 0);
    
    numTrials = 40;
    for trial = 1:numTrials
        app.resetSimulation();
        app.EmergencyButtonPushed([]);
        
        assert(app.EmergencyActive == true, sprintf('Trial %d: Emergency priority must be active', trial));
        
        emDir = app.EmergencyDirection;
        assert(ismember(emDir, {'North', 'South', 'East', 'West'}), sprintf('Trial %d: Invalid emergency road: %s', trial, emDir));
        
        % Verify exactly 1 emergency vehicle exists in active vehicles
        emVehs = app.ActiveVehicles([app.ActiveVehicles.IsEmergency]);
        assert(numel(emVehs) == 1, sprintf('Trial %d: Must have exactly 1 emergency vehicle', trial));
        
        vAmb = emVehs(1);
        assert(strcmp(vAmb.Direction, emDir), sprintf('Trial %d: Vehicle direction (%s) must match EmergencyDirection (%s)', trial, vAmb.Direction, emDir));
        assert(strcmp(vAmb.EmergencyType, 'Ambulance'), sprintf('Trial %d: Vehicle EmergencyType must be Ambulance', trial));
        
        % Verify position and lane orientation correspond to selected road
        switch emDir
            case 'North'
                assert(vAmb.Y > 20, 'North emergency vehicle must spawn above North stop line (Y > 20)');
                assert(vAmb.X < 0, 'North incoming lane must be X < 0');
            case 'South'
                assert(vAmb.Y < -20, 'South emergency vehicle must spawn below South stop line (Y < -20)');
                assert(vAmb.X > 0, 'South incoming lane must be X > 0');
            case 'East'
                assert(vAmb.X > 20, 'East emergency vehicle must spawn right of East stop line (X > 20)');
                assert(vAmb.Y > 0, 'East incoming lane must be Y > 0');
            case 'West'
                assert(vAmb.X < -20, 'West emergency vehicle must spawn left of West stop line (X < -20)');
                assert(vAmb.Y < 0, 'West incoming lane must be Y < 0');
        end
        
        roadsSeen(emDir) = true;
        roadCounts.(emDir) = roadCounts.(emDir) + 1;
    end
    
    fprintf('Selection Breakdown across %d trials:\n', numTrials);
    fprintf('  NORTH: %d times\n', roadCounts.North);
    fprintf('  SOUTH: %d times\n', roadCounts.South);
    fprintf('  EAST : %d times\n', roadCounts.East);
    fprintf('  WEST : %d times\n', roadCounts.West);
    
    % Verify all 4 roads were selected at least once
    allFourObserved = roadsSeen('North') && roadsSeen('South') && roadsSeen('East') && roadsSeen('West');
    assert(allFourObserved, 'Emergency vehicle must appear on all 4 roads (North, South, East, West) over multiple runs');
    
    delete(app.UIFigure);
    
    fprintf('=================================================================\n');
    fprintf('  [SUCCESS] RANDOM EMERGENCY ROAD SELECTION VERIFIED 100%%!      \n');
    fprintf('=================================================================\n');
end
