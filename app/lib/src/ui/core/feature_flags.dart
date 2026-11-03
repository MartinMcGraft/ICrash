// Features that are kept in the code but left out of the prototype.

/// P12 (28 Oct): emergency mode is set aside. While false, the cart menu doesn't
/// offer "Modo de emergência" (A10's code stays) and B7 doesn't list the
/// "Usar o modo de emergência" permission (3 Nov, DC-66). Flip to bring it back.
const kEmergencyModeEnabled = false;

/// Shifts (D8, B8 "Turnos") are set aside (2 Nov 2026): kept as an idea,
/// like emergency mode (P12, `kEmergencyModeEnabled`). While false, nothing
/// shows them: no "Turnos" in the Dashboard sidebar, no "Responsável no
/// turno" column in B3 or line in A5, and no "Os meus" tab in A4 (it lists
/// the carts someone is on shift for). The B8 code, the shift repository and
/// its tests stay. Flip to bring them back.
const kShiftsEnabled = false;
