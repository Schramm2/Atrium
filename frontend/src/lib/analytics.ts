/**
 * Compatibility surface for old event call sites.
 *
 * Notive does not collect product analytics. These methods intentionally
 * perform no I/O, persist no identifiers, and never contact a remote service.
 * Keeping the small surface avoids coupling recording workflows to telemetry
 * cleanup while older feature code is retired incrementally.
 */

export type AnalyticsProperties = Record<string, unknown>;

export interface DeviceInfo {
  platform: string;
  os_version: string;
  architecture: string;
}

export interface UserSession {
  session_id: string;
  user_id: string;
  start_time: string;
  last_heartbeat: string;
  is_active: boolean;
}

export class Analytics {
  static async init(): Promise<void> {}
  static async disable(): Promise<void> {}
  static async isEnabled(): Promise<boolean> { return false; }
  static async track(_eventName: string, _properties?: AnalyticsProperties): Promise<void> {}
  static async identify(_userId: string, _properties?: AnalyticsProperties): Promise<void> {}
  static async startSession(_userId: string): Promise<string | null> { return null; }
  static async endSession(): Promise<void> {}
  static async trackDailyActiveUser(): Promise<void> {}
  static async trackUserFirstLaunch(): Promise<void> {}
  static async isSessionActive(): Promise<boolean> { return false; }
  static async getPersistentUserId(): Promise<string> { return ''; }
  static async checkAndTrackFirstLaunch(): Promise<void> {}
  static async checkAndTrackDailyUsage(): Promise<void> {}
  static getCurrentUserId(): string | null { return null; }
  static async getDeviceInfo(): Promise<DeviceInfo> {
    return { platform: 'local', os_version: '', architecture: '' };
  }
  static async trackSessionStarted(_sessionId: string): Promise<void> {}
  static async trackSessionEnded(_sessionId: string): Promise<void> {}
  static async trackAppStarted(): Promise<void> {}
  static async cleanup(): Promise<void> {}
  static async trackBackendConnection(_success: boolean, _error?: string): Promise<void> {}
  static async trackButtonClick(_buttonName: string, _location?: string): Promise<void> {}
  static async trackCopy(_contentType: string, _properties?: AnalyticsProperties): Promise<void> {}
  static async trackCustomPromptUsed(_promptLength: number): Promise<void> {}
  static async trackError(_eventName: string, _error?: unknown): Promise<void> {}
  static async trackFeatureUsed(_featureName: string, _properties?: AnalyticsProperties): Promise<void> {}
  static async trackMeetingCompleted(_meetingId: string, _properties?: AnalyticsProperties): Promise<void> {}
  static async trackMeetingDeleted(_meetingId: string): Promise<void> {}
  static async trackModelChanged(..._args: unknown[]): Promise<void> {}
  static async trackPageView(_pageName: string): Promise<void> {}
  static async trackSettingsChanged(_settingName: string, _value?: unknown): Promise<void> {}
  static async trackSummaryGenerationCompleted(..._args: unknown[]): Promise<void> {}
  static async trackSummaryGenerationStarted(..._args: unknown[]): Promise<void> {}
  static async trackTranscriptionError(_error?: unknown): Promise<void> {}
  static async trackTranscriptionSuccess(): Promise<void> {}
  static async updateMeetingCount(): Promise<void> {}
  static async getMeetingsCountToday(): Promise<number> { return 0; }
  static async calculateDaysSince(_key: string): Promise<number | null> { return null; }
}

export default Analytics;
