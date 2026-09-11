import SwiftUI
import WidgetKit

private let appGroup = "group.pro.daddoodev.dailycompany"
private let kind = "BouquetWidget"

private let vellumBg = Color(red: 243 / 255, green: 237 / 255, blue: 225 / 255)
private let vellumInk = Color(red: 33 / 255, green: 29 / 255, blue: 26 / 255)
private let vellumSecondary = Color(red: 110 / 255, green: 101 / 255, blue: 90 / 255)

struct BouquetEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct BouquetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BouquetEntry {
        BouquetEntry(date: Date(), text: "Keep a line from Today.")
    }

    func getSnapshot(in context: Context, completion: @escaping (BouquetEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BouquetEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> BouquetEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        let empty = defaults?.bool(forKey: "bouquet_empty") ?? true
        let text = (defaults?.string(forKey: "bouquet_text") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = (!empty && !text.isEmpty) ? text : "Keep a line from Today."
        return BouquetEntry(date: Date(), text: shown)
    }
}

struct BouquetWidgetView: View {
    let entry: BouquetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BOUQUET")
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundStyle(vellumSecondary)
                .tracking(1.2)
            Text(entry.text)
                .font(.system(size: family == .accessoryRectangular ? 13 : 16, design: .serif))
                .foregroundStyle(vellumInk)
                .lineLimit(family == .accessoryRectangular ? 3 : 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground(vellumBg)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

struct BouquetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BouquetProvider()) { entry in
            BouquetWidgetView(entry: entry)
        }
        .configurationDisplayName("Bouquet")
        .description("The line you kept from the Devout Life.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct BouquetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BouquetWidget()
    }
}
