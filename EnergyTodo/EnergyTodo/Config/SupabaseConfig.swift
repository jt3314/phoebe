import Foundation
import Supabase

/// Central Supabase client instance shared across the app.
/// Replace the placeholder URL and key with your Supabase project credentials.
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://gcidbakuvepsqvyzoinz.supabase.co")!,
    supabaseKey: "sb_publishable_zmIVPayUGRhnPRcLl8PgIw_A3w6eB8T"
)
