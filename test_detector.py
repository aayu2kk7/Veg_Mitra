import time
import unittest
from unittest.mock import MagicMock, patch
import numpy as np
from detector import VehicleDetector


class DummyBox:
    def __init__(self, xyxy, conf, cls_id, track_id=None):
        self.xyxy = [xyxy]
        self.conf = [conf]
        self.cls = [cls_id]
        self.id = [track_id] if track_id is not None else None


class TestVehicleDetector(unittest.TestCase):
    @patch("detector.YOLO")
    def setUp(self, mock_yolo):
        self.mock_model = MagicMock()
        mock_yolo.return_value = self.mock_model

        # Model class map
        self.mock_model.names = {
            0: "car",
            1: "motorcycle",
            2: "bus",
            3: "truck",
            4: "person",
            5: "ambulance"
        }

        self.detector = VehicleDetector(
            model_name="yolov8n.pt",
            max_road_capacity={"North": 10, "South": 10, "East": 10, "West": 10},
            window_size=10,
            min_green_duration=0.5,  # Short real-time hold for test execution speed
            switch_threshold=10.0
        )
        self.detector.model = self.mock_model

    def create_mock_results(self, boxes_data):
        """Helper to build mock YOLO results."""
        boxes = []
        for item in boxes_data:
            if len(item) == 4:
                xyxy, conf, cls_id, track_id = item
            else:
                xyxy, conf, cls_id = item
                track_id = 101
            boxes.append(DummyBox(xyxy, conf, cls_id, track_id))

        result_obj = MagicMock()
        result_obj.boxes = boxes
        return [result_obj]

    def test_1_north_incoming_assignment(self):
        # Frame 200x200 -> Center (100, 100). North incoming lane: cx=90, cy=30
        region, state, _ = self.detector.classify_vehicle_movement(1, cx=90, cy=30, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "North")

    def test_2_south_incoming_assignment(self):
        # South incoming lane: cx=110, cy=170
        region, state, _ = self.detector.classify_vehicle_movement(2, cx=110, cy=170, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "South")

    def test_3_east_incoming_assignment(self):
        # East incoming lane: cx=170, cy=110
        region, state, _ = self.detector.classify_vehicle_movement(3, cx=170, cy=110, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "East")

    def test_4_west_incoming_assignment(self):
        # West incoming lane: cx=30, cy=90
        region, state, _ = self.detector.classify_vehicle_movement(4, cx=30, cy=90, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "West")

    def test_5_east_outgoing_ignored(self):
        # Vehicle #5 on East Outgoing lane (cx=170, cy=70) moving away
        self.detector.track_history[5] = [(160, 70, 1, 60.0), (170, 70, 2, 70.0)]
        region, state, _ = self.detector.classify_vehicle_movement(5, cx=170, cy=70, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "East")
        self.assertEqual(state, "OUTGOING")

    def test_6_west_outgoing_ignored(self):
        # Vehicle #6 on West Outgoing lane (cx=30, cy=110) moving away
        self.detector.track_history[6] = [(40, 110, 1, 60.0), (30, 110, 2, 70.0)]
        region, state, _ = self.detector.classify_vehicle_movement(6, cx=30, cy=110, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "West")
        self.assertEqual(state, "OUTGOING")

    def test_7_north_outgoing_ignored(self):
        # Vehicle #7 on North Outgoing lane (cx=110, cy=30) moving away
        self.detector.track_history[7] = [(110, 40, 1, 60.0), (110, 30, 2, 70.0)]
        region, state, _ = self.detector.classify_vehicle_movement(7, cx=110, cy=30, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "North")
        self.assertEqual(state, "OUTGOING")

    def test_8_south_outgoing_ignored(self):
        # Vehicle #8 on South Outgoing lane (cx=90, cy=170) moving away
        self.detector.track_history[8] = [(90, 160, 1, 60.0), (90, 170, 2, 70.0)]
        region, state, _ = self.detector.classify_vehicle_movement(8, cx=90, cy=170, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(region, "South")
        self.assertEqual(state, "OUTGOING")

    def test_9_same_vehicle_not_counted_repeatedly(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        boxes = [([160, 105, 180, 115], 0.9, 0, 17)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)

        # Process frame 1 and frame 2 with same track ID 17
        self.detector.process_frame(dummy_frame)
        _, stats = self.detector.process_frame(dummy_frame)

        # Track 17 counts as 1 vehicle on East, not 2
        self.assertEqual(stats["counts"]["East"], 1)

    def test_10_movement_toward_intersection_is_incoming(self):
        # Track 10 moving from dist 80 -> dist 60
        self.detector.track_history[10] = [(180, 110, 1, 80.0), (160, 110, 2, 60.0)]
        _, state, _ = self.detector.classify_vehicle_movement(10, cx=160, cy=110, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(state, "INCOMING")

    def test_11_movement_away_from_intersection_is_outgoing(self):
        # Track 11 moving from dist 40 -> dist 70
        self.detector.track_history[11] = [(140, 70, 1, 40.0), (170, 70, 2, 70.0)]
        _, state, _ = self.detector.classify_vehicle_movement(11, cx=170, cy=70, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(state, "OUTGOING")

    def test_12_unknown_movement_ignored(self):
        # 1st frame seen, no history, outside explicit polygon -> UNKNOWN
        region, state, _ = self.detector.classify_vehicle_movement(99, cx=10, cy=10, frame_width=200, frame_height=200, geom={})
        self.assertEqual(state, "UNKNOWN")

    def test_13_moving_average_calculation(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Frame 1: 10 incoming vehicles on North
        boxes_1 = [([85, 10 + i, 95, 20 + i], 0.9, 0, 100 + i) for i in range(10)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_1)
        self.detector.process_frame(dummy_frame)

        # Frame 2: 0 incoming vehicles
        self.mock_model.track.return_value = self.create_mock_results([])
        _, stats_2 = self.detector.process_frame(dummy_frame)

        # Moving average over 2 frames = (10 + 0) / 2 = 5.0
        self.assertEqual(stats_2["smoothed_counts"]["North"], 5.0)

    def test_14_density_calculation_formula(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # 4 incoming vehicles on North (Cap = 10) -> 40% density
        boxes = [([85, 10 + i * 2, 95, 20 + i * 2], 0.9, 0, 200 + i) for i in range(4)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)

        self.assertEqual(stats["density"]["North"], 40.0)

    def test_15_density_capped_at_100_percent(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # 15 incoming vehicles on North (Cap = 10) -> capped at 100.0%
        boxes = [([85, 2 + i, 95, 6 + i], 0.9, 0, 300 + i) for i in range(15)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)

        self.assertEqual(stats["density"]["North"], 100.0)

    def test_16_highest_of_four_roads_selected_independently(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # 8 incoming vehicles on East (East density = 80%)
        boxes = [([160 + (i % 2), 105 + i * 2, 175, 115 + i * 2], 0.9, 0, 400 + i) for i in range(8)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)

        time.sleep(0.6)  # Ensure min_green_duration elapses
        _, stats = self.detector.process_frame(dummy_frame)

        self.assertEqual(stats["selected_green_road"], "East")

    def test_17_no_ns_ew_grouping_used_for_normal_selection(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # 7 on South, 2 on North -> Single road South selected, NOT NS group
        boxes = [([110, 160 + i, 120, 170 + i], 0.9, 0, 500 + i) for i in range(7)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)

        time.sleep(0.6)
        _, stats = self.detector.process_frame(dummy_frame)

        self.assertEqual(stats["selected_green_road"], "South")

    def test_18_tie_handling_stability(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        self.mock_model.track.return_value = self.create_mock_results([])

        time.sleep(0.6)
        _, stats = self.detector.process_frame(dummy_frame)

        self.assertIn(stats["selected_green_road"], self.detector.ROADS)

    def test_19_hysteresis_10_percent_threshold(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Step 1: Set East green at 50% (5 vehicles)
        boxes_east = [([160, 105 + i, 175, 115 + i], 0.9, 0, 600 + i) for i in range(5)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_east)
        self.detector.process_frame(dummy_frame)
        time.sleep(0.6)
        self.detector.process_frame(dummy_frame)
        self.assertEqual(self.detector.current_green_road, "East")

        # Step 2: North gets 54% (5.4 smoothed -> diff = 4% < 10% hysteresis threshold)
        boxes_north = [([85, 10 + i, 95, 20 + i], 0.9, 0, 700 + i) for i in range(5)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_north)
        _, stats_hyst = self.detector.process_frame(dummy_frame)

        # Must hold East because 54% - 50% = 4% < 10%
        self.assertEqual(stats_hyst["selected_green_road"], "East")

    def test_20_emergency_vehicle_priority_override(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # 9 vehicles on South (90% density) AND 1 ambulance on West
        boxes = [([110, 160 + i, 120, 170 + i], 0.9, 0, 800 + i) for i in range(9)] + [([30, 85, 40, 95], 0.95, 5, 999)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)

        _, stats = self.detector.process_frame(dummy_frame)

        self.assertTrue(stats["emergency_active"])
        self.assertEqual(stats["emergency_road"], "West")
        self.assertEqual(stats["selected_green_road"], "West")

    def test_21_emergency_road_identification(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Ambulance on East
        boxes = [([170, 110, 180, 120], 0.98, 5, 888)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)

        _, stats = self.detector.process_frame(dummy_frame)

        self.assertEqual(stats["emergency_road"], "East")
        self.assertEqual(stats["selected_green_road"], "East")

    def test_22_realtime_minimum_green_hold(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Step 1: North green set
        boxes_north = [([85, 10 + i, 95, 20 + i], 0.9, 0, 900 + i) for i in range(5)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_north)
        self.detector.process_frame(dummy_frame)

        # Step 2: East suddenly 100% density without waiting min_green_duration
        boxes_east = [([160, 105 + i, 175, 115 + i], 0.9, 0, 950 + i) for i in range(10)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_east)
        _, stats_held = self.detector.process_frame(dummy_frame)

        # Must hold North until min_green_duration (0.5s) elapses
        self.assertEqual(stats_held["selected_green_road"], "North")

    def test_23_signal_changes_after_minimum_green_time(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Step 1: North green set
        boxes_north = [([85, 10 + i, 95, 20 + i], 0.9, 0, 1000 + i) for i in range(2)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_north)
        self.detector.process_frame(dummy_frame)

        # Step 2: Wait for min_green_duration (0.5s) to elapse with East at 100%
        time.sleep(0.6)
        boxes_east = [([160, 105 + i, 175, 115 + i], 0.9, 0, 1050 + i) for i in range(10)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_east)
        _, stats_switched = self.detector.process_frame(dummy_frame)

        # Signal switches to East after min green time
        self.assertEqual(stats_switched["selected_green_road"], "East")

    def test_24_active_incoming_vehicle_removed_after_becoming_outgoing(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)

        # Frame 1: Vehicle #55 on East Incoming (cx=170, cy=110)
        boxes_1 = [([165, 105, 175, 115], 0.9, 0, 55)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_1)
        _, stats_1 = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats_1["counts"]["East"], 1)

        # Frame 2: Vehicle #55 moves to East Outgoing (cx=170, cy=70)
        boxes_2 = [([165, 65, 175, 75], 0.9, 0, 55)]
        self.mock_model.track.return_value = self.create_mock_results(boxes_2)
        _, stats_2 = self.detector.process_frame(dummy_frame)

        # Vehicle #55 is now OUTGOING and removed from active East incoming count
        self.assertEqual(stats_2["counts"]["East"], 0)

    def test_25_model_loads_successfully(self):
        self.assertIsNotNone(self.detector.model)
        self.assertTrue(hasattr(self.detector.model, "names"))

    def test_26_inference_returns_valid_detection_structure(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        self.mock_model.track.return_value = self.create_mock_results([])
        annotated, stats = self.detector.process_frame(dummy_frame)
        self.assertIsInstance(annotated, np.ndarray)
        self.assertIsInstance(stats, dict)
        self.assertIn("counts", stats)
        self.assertIn("density", stats)
        self.assertIn("selected_green_road", stats)

    def test_27_synthetic_detection_mapped_to_road_region(self):
        # Synthetic box centered in North incoming lane
        road, state, _ = self.detector.classify_vehicle_movement(88, cx=90, cy=30, frame_width=200, frame_height=200, geom=self.detector._get_default_geometry(200, 200))
        self.assertEqual(road, "North")

    def test_28_valid_vehicle_detection_increments_road_count(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        # Vehicle in South incoming
        boxes = [([105, 165, 115, 175], 0.85, 0, 77)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats["counts"]["South"], 1)

    def test_29_class_filter_supports_actual_model_mapping(self):
        # Box with class 'person' (ID 4) should be filtered out
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        boxes = [([85, 20, 95, 30], 0.9, 4, 91)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats["total_vehicles"], 0)
        self.assertEqual(stats["filtered_detections"], 0)

    def test_30_density_calculation_correctness(self):
        # 3 vehicles in East with capacity 10 -> 30.0%
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        boxes = [([160, 105 + i*2, 175, 115 + i*2], 0.9, 0, 80 + i) for i in range(3)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats["density"]["East"], 30.0)

    def test_31_equal_traffic_does_not_permanently_favor_north(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        self.mock_model.track.return_value = self.create_mock_results([])
        
        # Track green selections over several elapsed periods
        selections = set()
        for i in range(4):
            time.sleep(0.55)
            _, stats = self.detector.process_frame(dummy_frame)
            selections.add(stats["selected_green_road"])

        # Round robin progression must rotate across roads rather than remaining stuck permanently on North
        self.assertTrue(len(selections) >= 2)

    def test_32_heavier_traffic_road_selected_when_switching_allowed(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        time.sleep(0.55)
        # 6 vehicles in West (60% density)
        boxes = [([25, 85, 35, 95], 0.9, 0, 700 + i) for i in range(6)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats["selected_green_road"], "West")

    def test_33_missing_detections_distinguishable_from_zero_traffic(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        self.detector.model = None
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertEqual(stats["detection_status"], "DETECTION_UNAVAILABLE")

    def test_34_emergency_priority_preserved(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        # Ambulance in East incoming
        boxes = [([165, 105, 175, 115], 0.95, 5, 999)]
        self.mock_model.track.return_value = self.create_mock_results(boxes)
        _, stats = self.detector.process_frame(dummy_frame)
        self.assertTrue(stats["emergency_active"])
        self.assertEqual(stats["selected_green_road"], "East")

    def test_35_exported_json_contains_valid_consistent_fields(self):
        dummy_frame = np.zeros((200, 200, 3), dtype=np.uint8)
        self.mock_model.track.return_value = self.create_mock_results([])
        _, stats = self.detector.process_frame(dummy_frame)
        for req_field in ["counts", "smoothed_counts", "density", "selected_green_road", "emergency_active", "total_vehicles"]:
            self.assertIn(req_field, stats)
        for road in self.detector.ROADS:
            self.assertIn(road, stats["counts"])
            self.assertIn(road, stats["density"])


if __name__ == "__main__":
    unittest.main()
