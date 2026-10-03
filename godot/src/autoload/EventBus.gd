extends Node

# Signály zmeny stavu simulácie
signal tick_processed(state: Dictionary, delta: float)
signal shift_changed(new_shift: int, crew_name: String)
signal foreman_changed(foreman_index: int, foreman_name: String)
signal day_passed(new_day: int, event_title: String)
signal week_passed(new_week: int)
signal money_changed(new_balance: int, delta: int)

# Signály strojov a výroby
signal machine_state_changed(slot: int, new_state: String)
signal batch_finished(slot: int, product_id: String)
signal reject_occurred(slot: int, product_id: String)
signal material_unloaded_to_pallet(slot: int, product_id: String)

# Signály pieskovača
signal washer_cycle_started(product_id: String)
signal washer_cycle_finished(product_id: String)

# Signály personálu a kancelárie
signal worker_hired(employee: Dictionary)
signal worker_dismissed(employee: Dictionary, severance: int)
signal worker_absent(employee: Dictionary, position_key: String)
signal overtime_called(employee: Dictionary, position_key: String)
signal wages_paid(paid_amount: int, debt_remaining: int)

# Signály obchodu a zákaziek
signal trade_executed(item: String, side: String, quantity: int, total_price: int)
signal contract_accepted(contract_id: String)
signal contract_fulfilled(contract_id: String, reward: int)
signal contract_expired(contract_id: String)

# Signály navigácie a používateľského rozhrania
signal room_change_requested(room_name: String)
signal machine_selected(slot: int)
signal machine_inspector_requested(slot: int)
signal bin_selected(bin_id: String)
signal toast_requested(message: String, is_error: bool)
signal pause_toggled(is_paused: bool)
