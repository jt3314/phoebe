import Foundation

/// Fetches events from Google Calendar API and caches them in Supabase.
enum GoogleCalendarService {

    private static let calendarBaseURL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

    // MARK: - Sync from Google

    /// Fetch events from Google Calendar for a date range and upsert into Supabase.
    @MainActor
    static func syncEvents(userId: UUID, dateRange: ClosedRange<String>) async throws {
        guard let accessToken = await GoogleAuthService.getValidAccessToken() else {
            throw CalendarSyncError.noAccessToken
        }

        let events = try await fetchFromGoogle(accessToken: accessToken, dateRange: dateRange)
        try await upsertToSupabase(userId: userId, events: events)
    }

    /// Fetch events from the Google Calendar REST API.
    private static func fetchFromGoogle(accessToken: String, dateRange: ClosedRange<String>) async throws -> [GoogleCalendarAPIEvent] {
        var components = URLComponents(string: calendarBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: "\(dateRange.lowerBound)T00:00:00Z"),
            URLQueryItem(name: "timeMax", value: "\(dateRange.upperBound)T23:59:59Z"),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            // Token expired — try refresh
            if let newToken = await GoogleAuthService.refreshTokenIfNeeded() {
                return try await fetchFromGoogle(accessToken: newToken, dateRange: dateRange)
            }
            throw CalendarSyncError.authExpired
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
        return decoded.items ?? []
    }

    /// Upsert fetched events into the Supabase google_calendar_events table.
    private static func upsertToSupabase(userId: UUID, events: [GoogleCalendarAPIEvent]) async throws {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = .current

        let now = Date()

        let rows: [GoogleCalendarUpsertRow] = events.compactMap { event in
            let isAllDay = event.start.date != nil
            let startTime: Date
            let endTime: Date
            let dateString: String

            if let dateStr = event.start.date {
                dateString = dateStr
                startTime = dateOnlyFormatter.date(from: dateStr) ?? now
                endTime = dateOnlyFormatter.date(from: event.end?.date ?? dateStr) ?? now
            } else if let dtStr = event.start.dateTime {
                startTime = isoFormatter.date(from: dtStr) ?? now
                endTime = isoFormatter.date(from: event.end?.dateTime ?? dtStr) ?? now
                dateString = dateOnlyFormatter.string(from: startTime)
            } else {
                return nil
            }

            let effort = GoogleCalendarEvent.effortCost(startTime: startTime, endTime: endTime, isAllDay: isAllDay)

            return GoogleCalendarUpsertRow(
                userId: userId.uuidString,
                googleEventId: event.id,
                summary: event.summary ?? "Untitled event",
                startTime: isoFormatter.string(from: startTime),
                endTime: isoFormatter.string(from: endTime),
                date: dateString,
                effortCost: effort,
                isAllDay: isAllDay,
                syncedAt: isoFormatter.string(from: now)
            )
        }

        guard !rows.isEmpty else { return }

        try await supabase
            .from("google_calendar_events")
            .upsert(rows, onConflict: "user_id,google_event_id")
            .execute()
    }

    // MARK: - Read Cached Events

    /// Fetch cached Google Calendar events for a specific date from Supabase.
    static func fetchCachedEvents(userId: UUID, date: String) async throws -> [GoogleCalendarEvent] {
        try await supabase
            .from("google_calendar_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date)
            .execute()
            .value
    }

    /// Fetch cached events for a date range from Supabase.
    static func fetchCachedEvents(userId: UUID, startDate: String, endDate: String) async throws -> [GoogleCalendarEvent] {
        try await supabase
            .from("google_calendar_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .execute()
            .value
    }

    // MARK: - Error

    enum CalendarSyncError: LocalizedError {
        case noAccessToken
        case authExpired

        var errorDescription: String? {
            switch self {
            case .noAccessToken: return "No Google access token available. Please sign in again."
            case .authExpired: return "Google Calendar access expired. Please sign in again."
            }
        }
    }
}

// MARK: - Google Calendar API Response Models

private struct GoogleCalendarListResponse: Decodable {
    let items: [GoogleCalendarAPIEvent]?
}

private struct GoogleCalendarAPIEvent: Decodable {
    let id: String
    let summary: String?
    let start: GoogleCalendarDateTime
    let end: GoogleCalendarDateTime?
}

private struct GoogleCalendarDateTime: Decodable {
    let date: String? // All-day events: "2026-03-28"
    let dateTime: String? // Timed events: ISO 8601
}

/// Row shape for upserting into google_calendar_events table.
private struct GoogleCalendarUpsertRow: Encodable {
    let userId: String
    let googleEventId: String
    let summary: String
    let startTime: String
    let endTime: String
    let date: String
    let effortCost: Int
    let isAllDay: Bool
    let syncedAt: String

    enum CodingKeys: String, CodingKey {
        case summary, date
        case userId = "user_id"
        case googleEventId = "google_event_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case effortCost = "effort_cost"
        case isAllDay = "is_all_day"
        case syncedAt = "synced_at"
    }
}
