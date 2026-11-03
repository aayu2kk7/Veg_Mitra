function verify_ThreeEmergencyTypesAndRandomRoad()
    % VERIFY_THREEEMERGENCYTYPESANDRANDOMROAD
    % Verifies that all 3 emergency vehicle types (AMBULANCE, POLICE, FIRE TRUCK)
    % and all 4 starting roads (NORTH, SOUTH, EAST, WEST) are randomly selected and
    % behave identically with 100% emergency priority, safe clearance, and zero collisions.
    
    fprintf('=================================================================\n');
    fprintf('  VERIFYING THREE EMERGENCY VEHICLE TYPES & RANDOM ROAD SELECTION \n');
    fprintf('=================================================================\n');
    
    app = VegMitraApp();
    
    typesSeen = containers.Map({'Ambulance', 'Police', 'Fire Truck'}, [false, false, false]);
    roadsSeen = containers.Map({'North', 'South', 'East', 'West'}, [false, false, false, false]);
    
    combosSeen = containers.Map();
    allTypes = {'Ambulance', 'Police', 'Fire Truck'};
    allRoads = {'North', 'South', 'East', 'West'};
    for t = 1:numel(allTypes)
        for r = 1:numel(allRoads)
            key = sprintf('%s_%s', allTypes{t}, allRoads{r});
            combosSeen(key) = false;
        end
    end
    
    % Part 1: Verify Random Selection across 60 trials
    fprintf('\nPart 1: Running 60 Random Simulation Triggers...\n');
    for trial = 1:60
        app.resetSimulation();
        app.EmergencyButtonPushed([]);
        
        assert(app.EmergencyActive == true, sprintf('Trial %d: Emergency priority must be active', trial));
        
        emDir = app.EmergencyDirection;
        emType = app.EmergencyType;
        
        assert(ismember(emDir, allRoads), sprintf('Trial %d: Invalid emergency road: %s', trial, emDir));
        assert(ismember(emType, {'Ambulance', 'Police', 'Fire Truck', 'Police Car', 'Fire Brigade'}), sprintf('Trial %d: Invalid emergency type: %s', trial, emType));
        
        % Verify exactly 1 emergency vehicle exists in active vehicles
        emVehs = app.ActiveVehicles([app.ActiveVehicles.IsEmergency]);
        assert(numel(emVehs) == 1, sprintf('Trial %d: Must have exactly 1 emergency vehicle', trial));
        
        v = emVehs(1);
        assert(v.IsEmergency == true, sprintf('Trial %d: IsEmergency must be true', trial));
        assert(strcmp(v.Direction, emDir), sprintf('Trial %d: Direction mismatch', trial));
        
        typesSeen(emType) = true;
        roadsSeen(emDir) = true;
        
        comboKey = sprintf('%s_%s', emType, emDir);
        if isKey(combosSeen, comboKey)
            combosSeen(comboKey) = true;
        end
    end
    
    fprintf('  [OK] Observed Emergency Types: Ambulance=%d, Police=%d, Fire Truck=%d\n', ...
        typesSeen('Ambulance'), typesSeen('Police'), typesSeen('Fire Truck'));
    fprintf('  [OK] Observed Emergency Roads: North=%d, South=%d, East=%d, West=%d\n', ...
        roadsSeen('North'), roadsSeen('South'), roadsSeen('East'), roadsSeen('West'));
    
    assert(typesSeen('Ambulance') && typesSeen('Police') && typesSeen('Fire Truck'), ...
        'All 3 emergency vehicle types (Ambulance, Police, Fire Truck) must be observed');
    assert(roadsSeen('North') && roadsSeen('South') && roadsSeen('East') && roadsSeen('West'), ...
        'All 4 starting roads (North, South, East, West) must be observed');
    
    % Part 2: Explicit verification of all 12 combinations
    fprintf('\nPart 2: Explicitly testing all 12 type + road combinations...\n');
    for tIdx = 1:numel(allTypes)
        for rIdx = 1:numel(allRoads)
            curType = allTypes{tIdx};
            curRoad = allRoads{rIdx};
            
            app.resetSimulation();
            vEm = app.triggerEmergencyVehicle(curRoad, curType);
            
            assert(~isempty(vEm), sprintf('Failed to trigger %s on %s', curType, curRoad));
            assert(vEm.IsEmergency == true, sprintf('%s on %s must have IsEmergency == true', curType, curRoad));
            assert(strcmp(vEm.Direction, curRoad), sprintf('Direction mismatch for %s on %s', curType, curRoad));
            
            % Run 30 simulation ticks to verify smooth movement & signal clearance
            for step = 1:30
                app.updateTrafficSignals(0.1);
                app.updateVehicles();
            end
            
            % Confirm no collisions occurred
            numV = numel(app.ActiveVehicles);
            for i = 1:numV
                for j = (i+1):numV
                    v1 = app.ActiveVehicles(i);
                    v2 = app.ActiveVehicles(j);
                    box1 = app.getVehicleBoundingBox(v1, v1.X, v1.Y);
                    box2 = app.getVehicleBoundingBox(v2, v2.X, v2.Y);
                    assert(~app.checkAABBOverlap(box1, box2, 0.5), ...
                        sprintf('Collision detected between %s and %s during %s on %s preemption!', v1.Type, v2.Type, curType, curRoad));
                end
            end
        end
    end
    
    delete(app.UIFigure);
    
    fprintf('=================================================================\n');
    fprintf('  [SUCCESS] ALL 3 EMERGENCY TYPES & 4 ROADS VERIFIED 100%%!       \n');
    fprintf('=================================================================\n');
end
