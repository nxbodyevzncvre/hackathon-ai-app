import SwiftUI

/// Settings: workday, capacity, notifications, privacy note, status.
/// Every control persists and is used by the planner (M4); no dead toggles.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s28) {
                Text("Settings")
                    .typeStyle(.screenTitle)

                VStack(alignment: .leading, spacing: Theme.Space.s12) {
                    SectionHeader(title: "Workday")
                    VStack(spacing: 0) {
                        capacityRow
                        Divider().overlay(Color.border)
                        MinutePickerRow(title: "Workday starts", minutes: $settings.workdayStartMinutes)
                        Divider().overlay(Color.border)
                        MinutePickerRow(title: "Workday ends", minutes: $settings.workdayEndMinutes)
                    }
                    .surfaceCard()
                }

                VStack(alignment: .leading, spacing: Theme.Space.s12) {
                    SectionHeader(title: "Notifications")
                    VStack(spacing: 0) {
                        Toggle(isOn: $settings.notificationsEnabled) {
                            VStack(alignment: .leading, spacing: Theme.Space.s4) {
                                Text("Reminders and briefing")
                                    .typeStyle(.taskTitle)
                                Text("Permission is requested after your first captured action.")
                                    .typeStyle(.meta)
                            }
                        }
                        .padding(Theme.Space.s16)
                        Divider().overlay(Color.border)
                        MinutePickerRow(title: "Briefing time", minutes: $settings.briefingMinutes)
                        Divider().overlay(Color.border)
                        MinutePickerRow(title: "Quiet hours start", minutes: $settings.quietStartMinutes)
                        Divider().overlay(Color.border)
                        MinutePickerRow(title: "Quiet hours end", minutes: $settings.quietEndMinutes)
                    }
                    .surfaceCard()
                }

                VStack(alignment: .leading, spacing: Theme.Space.s12) {
                    SectionHeader(title: "Privacy")
                    InlineNotice(
                        message: """
                        Only the text you type while capturing is sent out, over an encrypted \
                        connection to your configured AI proxy, to turn it into structured actions. \
                        It is not stored on the proxy. Your actions, settings and history stay \
                        on this device. No accounts, no analytics.
                        """,
                        systemImage: "lock.shield",
                        tone: .success
                    )
                }

                VStack(alignment: .leading, spacing: Theme.Space.s12) {
                    SectionHeader(title: "About")
                    VStack(spacing: 0) {
                        HStack {
                            Text("AI pipeline")
                                .typeStyle(.taskTitle)
                            Spacer()
                            Text("Offline")
                                .typeStyle(.meta)
                        }
                        .padding(Theme.Space.s16)
                        Divider().overlay(Color.border)
                        HStack {
                            Text("Version")
                                .typeStyle(.taskTitle)
                            Spacer()
                            Text(bundleVersion)
                                .typeStyle(.meta)
                        }
                        .padding(Theme.Space.s16)
                    }
                    .surfaceCard()
                }
            }
            .padding(.horizontal, Theme.Screen.hPadding)
            .padding(.top, Theme.Space.s24)
            .padding(.bottom, Theme.Space.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.bg)
        .accessibilityIdentifier("screen-settings")
    }

    private var capacityRow: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s8) {
            HStack {
                Text("Daily capacity")
                    .typeStyle(.taskTitle)
                Spacer()
                Text(capacityLabel)
                    .typeStyle(.meta)
            }
            Slider(
                value: Binding(
                    get: { Double(settings.dailyCapacityMinutes) },
                    set: { settings.dailyCapacityMinutes = Int($0) }
                ),
                in: 30...480,
                step: 15
            ) {
                Text("Daily capacity")
            } minimumValueLabel: {
                Text("30m").typeStyle(.chip)
            } maximumValueLabel: {
                Text("8h").typeStyle(.chip)
            }
        }
        .padding(Theme.Space.s16)
    }

    private var capacityLabel: String {
        let minutes = settings.dailyCapacityMinutes
        let hours = minutes / 60
        let rest = minutes % 60
        if rest == 0 { return "\(hours)h / day" }
        if hours == 0 { return "\(rest)m / day" }
        return "\(hours)h \(rest)m / day"
    }

    private var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

/// Row with a label on the left and an hour-and-minute picker on the right.
private struct MinutePickerRow: View {
    let title: String
    @Binding var minutes: Int

    var body: some View {
        HStack {
            Text(title)
                .typeStyle(.taskTitle)
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { SettingsStore.date(forMinutes: minutes) },
                    set: { minutes = SettingsStore.minutes(from: $0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .fixedSize()
        }
        .padding(Theme.Space.s16)
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(accessibilityTime)")
    }

    private var accessibilityTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: SettingsStore.date(forMinutes: minutes))
    }
}
