% test_critical_acceptance.m
% Verification of True Queue/Traffic-Demand-Based Signal Controller

try
    disp('====================================================');
    disp('  RUNNING CRITICAL ACCEPTANCE SCENARIO TEST SUITE   ');
    disp('====================================================');

    addpath(fileparts(mfilename('fullpath')));
    app = VegMitraApp();

    % --------------------------------------------------
    % Test Scenario 1: Requirement 20 Step 1
    % North = 4, South = 3, East = 8, West = 2 -> Expected: EAST GREEN
    % --------------------------------------------------
    disp('1. Testing Requirement 20 - Step 1 (North=4, South=3, East=8, West=2)...');
    app.SmoothedDensity.North = 40;
    app.SmoothedDensity.South = 30;
    app.SmoothedDensity.East  = 80;
    app.SmoothedDensity.West  = 20;

    decision1 = app.evaluateAIDecision();
    fprintf('   Selected Road: %s (Phase: %s)\n', decision1.SelectedRoad, decision1.NextPhase);
    assert(strcmp(decision1.SelectedRoad, 'East'), 'Step 1 must select East road for GREEN');
    assert(strcmp(decision1.NextPhase, 'EAST_GREEN'), 'Step 1 must set phase EAST_GREEN');
    disp('   [PASS] Step 1 verified: EAST GREEN');

    % Execute phase selection
    app.selectNextAdaptivePhase();
    assert(strcmp(app.getSignalState('East'), 'GREEN'), 'East signal must be GREEN');
    assert(strcmp(app.getSignalState('North'), 'RED'), 'North signal must be RED');
    assert(strcmp(app.getSignalState('South'), 'RED'), 'South signal must be RED');
    assert(strcmp(app.getSignalState('West'), 'RED'), 'West signal must be RED');
    disp('   [PASS] Single-road invariant verified (only EAST is GREEN)');

    % --------------------------------------------------
    % Test Scenario 2: Requirement 20 Step 2
    % After East clears (East=0): North=10, South=3, East=0, West=5 -> Expected: NORTH GREEN
    % --------------------------------------------------
    disp('2. Testing Requirement 20 - Step 2 (East clears, North=10, South=3, East=0, West=5)...');
    app.SmoothedDensity.North = 100;
    app.SmoothedDensity.South = 30;
    app.SmoothedDensity.East  = 0;
    app.SmoothedDensity.West  = 50;

    decision2 = app.evaluateAIDecision();
    fprintf('   Selected Road: %s (Phase: %s)\n', decision2.SelectedRoad, decision2.NextPhase);
    assert(strcmp(decision2.SelectedRoad, 'North'), 'Step 2 must select North road for GREEN after East clears');
    assert(strcmp(decision2.NextPhase, 'NORTH_GREEN'), 'Step 2 must set phase NORTH_GREEN');
    disp('   [PASS] Step 2 verified: NORTH GREEN');

    % --------------------------------------------------
    % Test Scenario 3: Requirement 20 Step 3
    % North clears (North=1): North=1, South=12, East=2, West=6 -> Expected: SOUTH GREEN
    % --------------------------------------------------
    disp('3. Testing Requirement 20 - Step 3 (North clears, South=12, North=1, East=2, West=6)...');
    app.setSignalPhase('NORTH_GREEN');
    app.SmoothedDensity.North = 10;
    app.SmoothedDensity.South = 100;
    app.SmoothedDensity.East  = 20;
    app.SmoothedDensity.West  = 60;

    decision3 = app.evaluateAIDecision();
    fprintf('   Selected Road: %s (Phase: %s)\n', decision3.SelectedRoad, decision3.NextPhase);
    assert(strcmp(decision3.SelectedRoad, 'South'), 'Step 3 must select South road for GREEN after North clears');
    assert(strcmp(decision3.NextPhase, 'SOUTH_GREEN'), 'Step 3 must set phase SOUTH_GREEN');
    disp('   [PASS] Step 3 verified: SOUTH GREEN');

    % --------------------------------------------------
    % Test Scenario 4: Requirement 20 Step 4
    % South clears (South=0): South=0, North=2, East=3, West=15 -> Expected: WEST GREEN
    % --------------------------------------------------
    disp('4. Testing Requirement 20 - Step 4 (South clears, South=0, North=2, East=3, West=15)...');
    app.setSignalPhase('SOUTH_GREEN');
    app.SmoothedDensity.South = 0;
    app.SmoothedDensity.North = 20;
    app.SmoothedDensity.East  = 30;
    app.SmoothedDensity.West  = 100;

    decision4 = app.evaluateAIDecision();
    fprintf('   Selected Road: %s (Phase: %s)\n', decision4.SelectedRoad, decision4.NextPhase);
    assert(strcmp(decision4.SelectedRoad, 'West'), 'Step 4 must select West road for GREEN after South clears');
    assert(strcmp(decision4.NextPhase, 'WEST_GREEN'), 'Step 4 must set phase WEST_GREEN');
    disp('   [PASS] Step 4 verified: WEST GREEN');

    % --------------------------------------------------
    % Test 5: Deterministic Tie-Breaking Order Verification
    % North = 8, South = 5, East = 8, West = 3 (Tied North & East)
    % Priority: NORTH -> EAST -> SOUTH -> WEST
    % --------------------------------------------------
    disp('5. Testing Deterministic Tie-Breaking (North=8, South=5, East=8, West=3)...');
    app.setSignalPhase('SOUTH_GREEN'); % Current green South cleared (0)
    app.SmoothedDensity.South = 0;
    app.SmoothedDensity.North = 80;
    app.SmoothedDensity.East  = 80;
    app.SmoothedDensity.West  = 30;

    decisionTie = app.evaluateAIDecision();
    fprintf('   Selected Road on Tie: %s (Phase: %s)\n', decisionTie.SelectedRoad, decisionTie.NextPhase);
    assert(strcmp(decisionTie.SelectedRoad, 'North'), 'Exact tie between North and East must break in favor of NORTH (NORTH > EAST > SOUTH > WEST)');
    disp('   [PASS] Deterministic tie-breaking verified (NORTH selected over EAST)');

    % --------------------------------------------------
    % Test 6: Vehicle Route Assignment (STRAIGHT, LEFT, RIGHT)
    % --------------------------------------------------
    disp('6. Testing Vehicle Route Assignment (STRAIGHT, LEFT, RIGHT)...');
    vN = app.spawnSingleVehicle('North', 'Car');
    vS = app.spawnSingleVehicle('South', 'Motorcycle');
    vE = app.spawnSingleVehicle('East', 'Bus/Truck');
    assert(ismember(vN.Route, {'STRAIGHT', 'LEFT', 'RIGHT'}), 'Vehicle must have route STRAIGHT, LEFT, or RIGHT');
    assert(ismember(vS.Route, {'STRAIGHT', 'LEFT', 'RIGHT'}), 'Vehicle must have route STRAIGHT, LEFT, or RIGHT');
    assert(ismember(vE.Route, {'STRAIGHT', 'LEFT', 'RIGHT'}), 'Vehicle must have route STRAIGHT, LEFT, or RIGHT');
    disp('   [PASS] Vehicle routes (STRAIGHT, LEFT, RIGHT) assigned properly');

    % Delete app
    delete(app);

    disp('====================================================');
    disp('  ALL CRITICAL ACCEPTANCE TESTS PASSED SUCCESSFULLY! ');
    disp('====================================================');

catch ME
    fprintf('[FAIL] Error during Critical Acceptance Test:\n%s\nFile: %s (line %d)\n', ...
        ME.message, ME.stack(1).file, ME.stack(1).line);
    exit(1);
end
